import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../firebase/firestore_schema.dart';
import '../models/feed_post.dart';
import 'auth/auth_service.dart';

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
      final ts = DateTime.now().millisecondsSinceEpoch;
      // Storage rules ожидают путь posts/{userId}/...
      final ref = _storage.ref().child('posts').child(uid).child(postId).child('photos').child('${ts}_$i.jpg');
      await ref.putFile(file);
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

  /// Переключить лайк поста для текущего пользователя.
  Future<void> toggleLike(String postId) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Необходимо войти в аккаунт');
    }

    final ref = _firestore.collection(kPostsCollection).doc(postId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final likedBy = List<String>.from((data[kPostLikedBy] as List?)?.map((e) => e.toString()) ?? []);
      final count = (data[kPostLikeCount] as int?) ?? 0;
      if (likedBy.contains(uid)) {
        likedBy.remove(uid);
        tx.update(ref, {kPostLikedBy: likedBy, kPostLikeCount: count > 0 ? count - 1 : 0});
      } else {
        likedBy.add(uid);
        tx.update(ref, {kPostLikedBy: likedBy, kPostLikeCount: count + 1});
      }
    });
  }
}
