import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firestore_schema.dart';
import '../models/feed_user.dart';
import 'auth/auth_service.dart';

/// Сервис ленты: кандидаты для свайпов, запись свайпа, проверка мэтча.
class FeedService {
  FeedService._();
  static final FeedService _instance = FeedService._();
  factory FeedService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthService get _auth => AuthService();

  /// Текущие фильтры (устанавливаются с экрана фильтров в Поиске).
  Map<String, dynamic> currentFilter = {};

  /// Загрузить кандидатов по фильтрам (пол, возраст, верификация). Сортировка: сначала тот же город, остальные — по индексу.
  Future<List<FeedUser>> getCandidates({int limit = 50}) async {
    final uid = _auth.currentUserId;
    if (uid == null) return [];

    final swipedIds = await _getSwipedTargetIds(uid);
    swipedIds.add(uid);

    final myProfile = await _auth.getUserProfile(uid);
    final myCity = myProfile?[kUserCity]?.toString();
    final myBirthdate = myProfile?[kUserBirthdate];
    DateTime? myBd;
    if (myBirthdate is Timestamp) myBd = myBirthdate.toDate();
    else if (myBirthdate is DateTime) myBd = myBirthdate;

    final filter = currentFilter;
    final gender = filter['gender'] as String?;
    final ageMin = (filter['ageMin'] is int) ? filter['ageMin'] as int : 18;
    final ageMax = (filter['ageMax'] is int) ? filter['ageMax'] as int : 60;
    final verifiedOnly = filter['verifiedOnly'] == true;

    Query<Map<String, dynamic>> q = _firestore.collection(kUsersCollection).limit(limit * 2);
    if (gender != null && gender.isNotEmpty && gender != 'everyone') {
      q = q.where(kUserGender, isEqualTo: gender);
    }

    final snap = await q.get();
    final list = <FeedUser>[];
    for (final doc in snap.docs) {
      if (swipedIds.contains(doc.id)) continue;
      final user = FeedUser.fromFirestore(doc);
      if (user.age != null && (user.age! < ageMin || user.age! > ageMax)) continue;
      if (verifiedOnly && !user.isVerified) continue;
      list.add(user);
    }

    if (myCity != null && myCity.isNotEmpty) {
      list.sort((a, b) {
        final aSame = a.city != null && a.city!.toLowerCase() == myCity.toLowerCase();
        final bSame = b.city != null && b.city!.toLowerCase() == myCity.toLowerCase();
        if (aSame && !bSame) return -1;
        if (!aSame && bSame) return 1;
        return 0;
      });
    }
    return list.take(limit).toList();
  }

  int _ageFromBirthdate(DateTime bd) {
    final now = DateTime.now();
    int age = now.year - bd.year;
    if (now.month < bd.month || (now.month == bd.month && now.day < bd.day)) age--;
    return age;
  }

  Future<Set<String>> _getSwipedTargetIds(String userId) async {
    final snap = await _firestore
        .collection(kSwipesCollection)
        .where(kSwipeUserId, isEqualTo: userId)
        .get();
    return snap.docs.map((d) => d.data()[kSwipeTargetUserId] as String?).whereType<String>().toSet();
  }

  /// Записать свайп (like или pass). Возвращает true, если это мэтч (вторая сторона уже лайкнула).
  Future<bool> recordSwipe({
    required String targetUserId,
    required bool isLike,
  }) async {
    final uid = _auth.currentUserId;
    if (uid == null) return false;

    await _firestore.collection(kSwipesCollection).add({
      kSwipeUserId: uid,
      kSwipeTargetUserId: targetUserId,
      kSwipeDirection: isLike ? 'like' : 'pass',
      kSwipeCreatedAt: FieldValue.serverTimestamp(),
    });

    if (!isLike) return false;
    return await _checkAndCreateMatch(uid, targetUserId);
  }

  /// Проверить, лайкал ли targetUserId текущего пользователя; если да — создать мэтч.
  Future<bool> _checkAndCreateMatch(String userId, String targetUserId) async {
    final snap = await _firestore
        .collection(kSwipesCollection)
        .where(kSwipeUserId, isEqualTo: targetUserId)
        .where(kSwipeTargetUserId, isEqualTo: userId)
        .where(kSwipeDirection, isEqualTo: 'like')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return false;

    final id1 = userId.compareTo(targetUserId) <= 0 ? userId : targetUserId;
    final id2 = userId.compareTo(targetUserId) <= 0 ? targetUserId : userId;
    final matchId = '${id1}_$id2';

    await _firestore.collection(kMatchesCollection).doc(matchId).set({
      kMatchUserId1: id1,
      kMatchUserId2: id2,
      kMatchCreatedAt: FieldValue.serverTimestamp(),
      kMatchLastActivityAt: FieldValue.serverTimestamp(),
      kMatchUnreadCount1: 0,
      kMatchUnreadCount2: 0,
    }, SetOptions(merge: true));

    return true;
  }

  /// Получить данные пользователя по uid (для полного профиля).
  Future<FeedUser?> getUser(String targetUid) async {
    final doc = await _firestore.collection(kUsersCollection).doc(targetUid).get();
    if (!doc.exists || doc.data() == null) return null;
    return FeedUser.fromFirestore(doc);
  }
}
