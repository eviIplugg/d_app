import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firestore_schema.dart';
import 'auth/auth_service.dart';

/// Сервис для админ-панели: модерация постов, управление пользователями, мероприятиями и местами.
class AdminCrmService {
  AdminCrmService._();
  static final AdminCrmService _instance = AdminCrmService._();
  factory AdminCrmService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthService get _auth => AuthService();
  String? get _uid => _auth.currentUserId;

  /// Посты на модерации (pending) или все с фильтром.
  Future<QuerySnapshot<Map<String, dynamic>>> getPostsForModeration({String? status, int limit = 50}) async {
    var q = _firestore.collection(kPostsCollection).orderBy(kPostCreatedAt, descending: true).limit(limit);
    if (status != null && status.isNotEmpty) {
      q = q.where(kPostModerationStatus, isEqualTo: status);
    }
    return q.get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamPostsForModeration({String? status, int limit = 50}) {
    if (status != null && status.isNotEmpty) {
      return _firestore
          .collection(kPostsCollection)
          .where(kPostModerationStatus, isEqualTo: status)
          .orderBy(kPostCreatedAt, descending: true)
          .limit(limit)
          .snapshots();
    }
    return _firestore
        .collection(kPostsCollection)
        .orderBy(kPostCreatedAt, descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Одобрить или отклонить пост.
  Future<void> setPostModerationStatus(String postId, String status) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore.collection(kPostsCollection).doc(postId).update({
      kPostModerationStatus: status,
      kPostReviewedAt: FieldValue.serverTimestamp(),
      kPostReviewedBy: uid,
    });
  }

  Future<void> setPostsModerationStatusBulk(List<String> postIds, String status) async {
    final uid = _uid;
    if (uid == null) return;
    if (postIds.isEmpty) return;
    const chunkSize = 450; // запас относительно лимита 500
    for (var i = 0; i < postIds.length; i += chunkSize) {
      final chunk = postIds.sublist(i, (i + chunkSize).clamp(0, postIds.length));
      final batch = _firestore.batch();
      for (final id in chunk) {
        final ref = _firestore.collection(kPostsCollection).doc(id);
        batch.update(ref, {
          kPostModerationStatus: status,
          kPostReviewedAt: FieldValue.serverTimestamp(),
          kPostReviewedBy: uid,
        });
      }
      await batch.commit();
    }
  }

  Future<void> deletePostsBulk(List<String> postIds) async {
    if (postIds.isEmpty) return;
    const chunkSize = 450;
    for (var i = 0; i < postIds.length; i += chunkSize) {
      final chunk = postIds.sublist(i, (i + chunkSize).clamp(0, postIds.length));
      final batch = _firestore.batch();
      for (final id in chunk) {
        final ref = _firestore.collection(kPostsCollection).doc(id);
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  /// Список пользователей (пагинация).
  Future<QuerySnapshot<Map<String, dynamic>>> getUsers({DocumentSnapshot? startAfter, int limit = 30}) async {
    var q = _firestore.collection(kUsersCollection).orderBy(kUserCreatedAt, descending: true).limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    return q.get();
  }

  /// Поиск пользователей для CRM:
  /// - по UID документа users/{uid}
  /// - по точному/префиксному имени
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> searchUsersByNameOrId(
    String query, {
    int limit = 20,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final byId = <DocumentSnapshot<Map<String, dynamic>>>[];
    // Пытаемся считать ID документа (uid).
    final idSnap = await _firestore.collection(kUsersCollection).doc(q).get();
    if (idSnap.exists) byId.add(idSnap);

    final results = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final d in byId) {
      results[d.id] = d;
    }

    try {
      // Точный матч по имени.
      final exact = await _firestore
          .collection(kUsersCollection)
          .where(kUserName, isEqualTo: q)
          .limit(limit)
          .get();
      for (final d in exact.docs) {
        results[d.id] = d;
      }
    } catch (_) {
      // ignore and continue with fallback
    }

    try {
      // Префикс по имени (A..A\uf8ff).
      final prefix = await _firestore
          .collection(kUsersCollection)
          .orderBy(kUserName)
          .startAt([q])
          .endAt(['$q\uf8ff'])
          .limit(limit)
          .get();
      for (final d in prefix.docs) {
        results[d.id] = d;
      }
    } catch (_) {
      // На случай отсутствия индекса — fallback ниже.
    }

    if (results.isEmpty) {
      // Fallback: последние пользователи + локальная фильтрация по имени.
      final recent = await _firestore
          .collection(kUsersCollection)
          .orderBy(kUserCreatedAt, descending: true)
          .limit(200)
          .get();
      final qLower = q.toLowerCase();
      for (final d in recent.docs) {
        final name = (d.data()[kUserName]?.toString() ?? '').toLowerCase();
        if (name.contains(qLower)) {
          results[d.id] = d;
          if (results.length >= limit) break;
        }
      }
    }

    final list = results.values.toList();
    list.sort((a, b) {
      final an = a.data()?[kUserName]?.toString() ?? '';
      final bn = b.data()?[kUserName]?.toString() ?? '';
      return an.compareTo(bn);
    });
    return list.take(limit).toList();
  }

  /// Обновить профиль пользователя (верификация, роль, бан). Только админ.
  Future<void> updateUserByAdmin(String userId, Map<String, dynamic> updates) async {
    final ref = _firestore.collection(kUsersCollection).doc(userId);
    final data = <String, dynamic>{
      ...updates,
      kUserUpdatedAt: FieldValue.serverTimestamp(),
    };
    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> updateUsersByAdminBulk(List<String> userIds, Map<String, dynamic> updates) async {
    if (userIds.isEmpty) return;
    final data = <String, dynamic>{
      ...updates,
      kUserUpdatedAt: FieldValue.serverTimestamp(),
    };
    const chunkSize = 450;
    for (var i = 0; i < userIds.length; i += chunkSize) {
      final chunk = userIds.sublist(i, (i + chunkSize).clamp(0, userIds.length));
      final batch = _firestore.batch();
      for (final id in chunk) {
        final ref = _firestore.collection(kUsersCollection).doc(id);
        batch.set(ref, data, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  /// Все мероприятия (для админа).
  Future<QuerySnapshot<Map<String, dynamic>>> getEvents({int limit = 50}) async {
    return _firestore
        .collection(kEventsCollection)
        .orderBy(kEventCreatedAt, descending: true)
        .limit(limit)
        .get();
  }

  /// Все места проведения.
  Future<QuerySnapshot<Map<String, dynamic>>> getVenues({int limit = 50}) async {
    return _firestore.collection(kVenuesCollection).limit(limit).get();
  }

  /// Удалить пост (админ).
  Future<void> deletePost(String postId) async {
    await _firestore.collection(kPostsCollection).doc(postId).delete();
  }

  /// Удалить мероприятие (админ).
  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection(kEventsCollection).doc(eventId).delete();
  }

  /// Удалить место (админ).
  Future<void> deleteVenue(String venueId) async {
    await _firestore.collection(kVenuesCollection).doc(venueId).delete();
  }
}
