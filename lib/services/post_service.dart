import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../firebase/firestore_schema.dart';
import '../models/feed_post.dart';
import 'auth/auth_service.dart';
import 'image_optimization_service.dart';
import 'like_notification_service.dart';

/// Сервис постов ленты: создание, стрим, лайки.
/// Фото храним в Firebase Storage, а в Firestore — только download URL в поле photoUrls.
const int _maxPostPhotos = 10;

class PostService {
  PostService._();
  static final PostService _instance = PostService._();
  factory PostService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  AuthService get _auth => AuthService();

  String? get _uid => _auth.currentUserId;

  Future<List<String>> _uploadPostPhotos({
    required String uid,
    required String postId,
    required List<String> photoFilePaths,
  }) async {
    final urls = <String>[];
    for (var i = 0; i < photoFilePaths.length && urls.length < _maxPostPhotos; i++) {
      final path = photoFilePaths[i];
      if (path.trim().isEmpty) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      final optimized = await ImageOptimizationService.optimizeJpeg(
        file,
        minWidth: 1440,
        minHeight: 1440,
        quality: 74,
      );
      final ts = DateTime.now().millisecondsSinceEpoch;
      // Storage rules ожидают путь posts/{userId}/...
      final ref = _storage.ref().child('posts').child(uid).child(postId).child('photos').child('${ts}_$i.jpg');
      await ref.putFile(
        optimized,
        SettableMetadata(contentType: 'image/jpeg', cacheControl: 'public,max-age=604800'),
      );
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  /// Создаёт пост. Фото загружаются в Storage, в Firestore сохраняются URL.
  Future<String?> createPost({
    required List<String> photoFilePaths,
    String caption = '',
    String type = 'personal',
    String? activityTitle,
    String? activityDate,
    String? activityVenue,
    bool activityVenueVerified = false,
    String? activityPrice,
    String? activityRating,
    String? activityTag,
  }) async {
    final uid = _uid;
    if (uid == null || photoFilePaths.isEmpty) return null;

    final doc = _firestore.collection(kPostsCollection).doc();
    final data = <String, dynamic>{
      kPostAuthorId: uid,
      kPostPhotoUrls: <String>[],
      kPostPhotoDataUrls: <String>[], // legacy (раньше хранили base64). Оставляем пустым.
      kPostCaption: caption,
      kPostCreatedAt: FieldValue.serverTimestamp(),
      kPostType: type,
      kPostLikeCount: 0,
      kPostLikedBy: <String>[],
    };
    data[kPostModerationStatus] = 'pending'; // модерация: по умолчанию на проверке
    if (type == 'activity') {
      if (activityTitle != null) data[kPostActivityTitle] = activityTitle;
      if (activityDate != null) data[kPostActivityDate] = activityDate;
      if (activityVenue != null) data[kPostActivityVenue] = activityVenue;
      data[kPostActivityVenueVerified] = activityVenueVerified;
      if (activityPrice != null) data[kPostActivityPrice] = activityPrice;
      if (activityRating != null) data[kPostActivityRating] = activityRating;
      if (activityTag != null) data[kPostActivityTag] = activityTag;
    }
    await doc.set(data);
    final urls = await _uploadPostPhotos(uid: uid, postId: doc.id, photoFilePaths: photoFilePaths);
    if (urls.isEmpty) {
      await doc.delete();
      return null;
    }
    await doc.update({kPostPhotoUrls: urls});
    return doc.id;
  }

  /// Стрим постов для ленты: все, кроме отклонённых модерацией (pending и approved видны).
  Stream<List<FeedPost>> streamPosts({int limit = 50}) {
    return _firestore
        .collection(kPostsCollection)
        .orderBy(kPostCreatedAt, descending: true)
        .limit(limit * 2)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .where((d) {
            final status = d.data()[kPostModerationStatus]?.toString();
            return status != 'rejected';
          })
          .take(limit)
          .map((d) => FeedPost.fromFirestore(d))
          .toList();
      return list;
    });
  }

  /// Установить статус модерации поста (только для админа).
  Future<void> setModerationStatus(String postId, String status, String reviewedBy) async {
    await _firestore.collection(kPostsCollection).doc(postId).update({
      kPostModerationStatus: status,
      kPostReviewedAt: FieldValue.serverTimestamp(),
      kPostReviewedBy: reviewedBy,
    });
  }

  /// Переключить лайк поста для текущего пользователя (оптимистично на UI; сервер — источник истины).
  Future<void> toggleLike(String postId) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Необходимо войти в аккаунт');
    }

    final ref = _firestore.collection(kPostsCollection).doc(postId);
    var becameLiked = false;
    String? authorId;
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      authorId = data[kPostAuthorId]?.toString();
      final likedBy = List<String>.from((data[kPostLikedBy] as List?)?.map((e) => e.toString()) ?? []);
      final count = (data[kPostLikeCount] as int?) ?? 0;
      final had = likedBy.contains(uid);
      if (had) {
        likedBy.remove(uid);
        becameLiked = false;
        tx.update(ref, {kPostLikedBy: likedBy, kPostLikeCount: count > 0 ? count - 1 : 0});
      } else {
        likedBy.add(uid);
        becameLiked = true;
        tx.update(ref, {kPostLikedBy: likedBy, kPostLikeCount: count + 1});
      }
    });
    if (becameLiked && authorId != null && authorId != uid) {
      unawaited(
        LikeNotificationService().notifyPostLiked(recipientId: authorId!, postId: postId, actorId: uid),
      );
    }
  }

  Future<void> updatePost({
    required String postId,
    String? caption,
    String? activityTitle,
    String? activityDate,
    String? activityVenue,
    bool? activityVenueVerified,
    String? activityPrice,
    String? activityRating,
    String? activityTag,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Необходимо войти в аккаунт');
    final ref = _firestore.collection(kPostsCollection).doc(postId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final author = snap.data()?[kPostAuthorId]?.toString();
    if (author != uid && !await _auth.isAdmin()) {
      throw StateError('Нет прав на редактирование');
    }
    final update = <String, dynamic>{};
    if (caption != null) update[kPostCaption] = caption;
    final type = snap.data()?[kPostType]?.toString() ?? 'personal';
    if (type == 'activity') {
      if (activityTitle != null) update[kPostActivityTitle] = activityTitle;
      if (activityDate != null) update[kPostActivityDate] = activityDate;
      if (activityVenue != null) update[kPostActivityVenue] = activityVenue;
      if (activityVenueVerified != null) update[kPostActivityVenueVerified] = activityVenueVerified;
      if (activityPrice != null) update[kPostActivityPrice] = activityPrice;
      if (activityRating != null) update[kPostActivityRating] = activityRating;
      if (activityTag != null) update[kPostActivityTag] = activityTag;
    }
    if (update.isEmpty) return;
    await ref.update(update);
  }

  Future<void> deletePost(String postId) async {
    final uid = _uid;
    if (uid == null) throw StateError('Необходимо войти в аккаунт');
    final ref = _firestore.collection(kPostsCollection).doc(postId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final author = snap.data()?[kPostAuthorId]?.toString();
    if (author != uid && !await _auth.isAdmin()) {
      throw StateError('Нет прав на удаление');
    }
    while (true) {
      final page = await ref.collection(kPostCommentsSubcollection).limit(400).get();
      if (page.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final d in page.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
    await ref.delete();
  }

  Future<void> reportPost({required String postId, required String reason}) async {
    final uid = _uid;
    if (uid == null) throw StateError('Необходимо войти в аккаунт');
    final r = reason.trim();
    if (r.isEmpty) throw ArgumentError('Укажите причину');
    await _firestore.collection(kPostReportsCollection).add({
      kReportPostId: postId,
      kReportReporterId: uid,
      kReportReason: r,
      kReportCreatedAt: FieldValue.serverTimestamp(),
    });
  }
}
