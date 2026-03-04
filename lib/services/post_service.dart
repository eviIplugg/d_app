import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firestore_schema.dart';
import '../models/feed_post.dart';
import 'auth/auth_service.dart';

/// Сервис постов ленты: создание, стрим, лайки.
/// Без платной подписки Firebase Storage фото сохраняются в Firestore как base64 (data URL).
const int _maxPhotosWithoutStorage = 2;
const int _maxBytesPerPhoto = 350000; // ~350 KB, чтобы уложиться в лимит документа 1 MB

class PostService {
  PostService._();
  static final PostService _instance = PostService._();
  factory PostService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthService get _auth => AuthService();

  String? get _uid => _auth.currentUserId;

  /// Читает фото с диска, сжимает объём (лимит размера) и возвращает data URL для хранения в Firestore.
  Future<List<String>> filePathsToDataUrls(List<String> filePaths) async {
    final dataUrls = <String>[];
    for (var i = 0; i < filePaths.length && dataUrls.length < _maxPhotosWithoutStorage; i++) {
      final path = filePaths[i];
      if (path.trim().isEmpty) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxBytesPerPhoto) continue; // пропускаем слишком большие
      final base64 = base64Encode(bytes);
      dataUrls.add('data:image/jpeg;base64,$base64');
    }
    return dataUrls;
  }

  /// Создаёт пост. Фото сохраняются в Firestore как base64 (без Storage).
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

    final photoDataUrls = await filePathsToDataUrls(photoFilePaths);
    if (photoDataUrls.isEmpty) return null;

    final doc = _firestore.collection(kPostsCollection).doc();
    final data = <String, dynamic>{
      kPostAuthorId: uid,
      kPostPhotoUrls: <String>[],
      kPostPhotoDataUrls: photoDataUrls,
      kPostCaption: caption,
      kPostCreatedAt: FieldValue.serverTimestamp(),
      kPostType: type,
      kPostLikeCount: 0,
      kPostLikedBy: <String>[],
    };
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
    return doc.id;
  }

  /// Стрим постов для ленты (все пользователи), по убыванию createdAt.
  Stream<List<FeedPost>> streamPosts({int limit = 50}) {
    return _firestore
        .collection(kPostsCollection)
        .orderBy(kPostCreatedAt, descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FeedPost.fromFirestore(d)).toList());
  }

  /// Переключить лайк поста для текущего пользователя.
  Future<void> toggleLike(String postId) async {
    final uid = _uid;
    if (uid == null) return;

    final ref = _firestore.collection(kPostsCollection).doc(postId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final likedBy = List<String>.from((data[kPostLikedBy] as List?)?.map((e) => e.toString()) ?? []);
      final count = (data[kPostLikeCount] as int?) ?? 0;
      if (likedBy.contains(uid)) {
        likedBy.remove(uid);
        tx.update(ref, {kPostLikedBy: likedBy, kPostLikeCount: count - 1});
      } else {
        likedBy.add(uid);
        tx.update(ref, {kPostLikedBy: likedBy, kPostLikeCount: count + 1});
      }
    });
  }
}
