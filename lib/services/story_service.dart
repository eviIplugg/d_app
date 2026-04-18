import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../firebase/firestore_schema.dart';
import '../models/story_item.dart';
import 'image_optimization_service.dart';
import 'auth/auth_service.dart';

/// Истории в стиле Telegram: видны только мэтчам и скрываются после 24 часов.
class StoryService {
  StoryService._();
  static final StoryService _instance = StoryService._();
  factory StoryService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  AuthService get _auth => AuthService();
  DateTime? _lastCleanupAt;

  String? get _uid => _auth.currentUserId;

  Future<List<String>> _matchedUserIds(String uid) async {
    final a = await _firestore.collection(kMatchesCollection).where(kMatchUserId1, isEqualTo: uid).get();
    final b = await _firestore.collection(kMatchesCollection).where(kMatchUserId2, isEqualTo: uid).get();
    final ids = <String>{};
    for (final d in a.docs) {
      final other = d.data()[kMatchUserId2]?.toString();
      if (other != null && other.isNotEmpty) ids.add(other);
    }
    for (final d in b.docs) {
      final other = d.data()[kMatchUserId1]?.toString();
      if (other != null && other.isNotEmpty) ids.add(other);
    }
    return ids.toList();
  }

  Future<void> _cleanupExpiredStories(String uid) async {
    final snap = await _firestore
        .collection(kStoriesCollection)
        .where(kStoryAuthorId, isEqualTo: uid)
        .limit(80)
        .get();
    final now = DateTime.now();
    final toDelete = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final doc in snap.docs) {
      final exp = doc.data()[kStoryExpiresAt];
      if (exp is Timestamp && exp.toDate().isBefore(now)) {
        toDelete.add(doc);
      }
    }
    if (toDelete.isEmpty) return;

    // Сначала удаляем файлы из Storage, затем документы из Firestore.
    // Если удаление файла не удалось, документ всё равно удаляем, чтобы история не "висела" в БД.
    for (final doc in toDelete) {
      final d = doc.data();
      final storagePath = d[kStoryStoragePath]?.toString();
      final imageUrl = d[kStoryImageUrl]?.toString();
      try {
        if (storagePath != null && storagePath.isNotEmpty) {
          await _storage.ref().child(storagePath).delete();
        } else if (imageUrl != null && imageUrl.isNotEmpty) {
          await _storage.refFromURL(imageUrl).delete();
        }
      } catch (_) {
        // Игнорируем, чтобы cleanup не останавливался.
      }
    }
    final batch = _firestore.batch();
    for (final doc in toDelete) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _cleanupExpiredStoriesIfNeeded(String uid) async {
    final now = DateTime.now();
    if (_lastCleanupAt != null && now.difference(_lastCleanupAt!) < const Duration(minutes: 5)) {
      return;
    }
    _lastCleanupAt = now;
    await _cleanupExpiredStories(uid);
  }

  Future<String?> createStory({
    required XFile image,
    String? caption,
  }) async {
    final uid = _uid;
    if (uid == null) return null;
    await _cleanupExpiredStories(uid);

    final storyRef = _firestore.collection(kStoriesCollection).doc();
    final path = _storage.ref().child('stories').child(uid).child('${storyRef.id}.jpg');

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      await path.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      final file = File(image.path);
      if (!await file.exists()) return null;
      final optimized = await ImageOptimizationService.optimizeJpeg(
        file,
        minWidth: 1080,
        minHeight: 1080,
        quality: 74,
      );
      await path.putFile(
        optimized,
        SettableMetadata(contentType: 'image/jpeg', cacheControl: 'public,max-age=604800'),
      );
    }
    final url = await path.getDownloadURL();

    final viewers = await _matchedUserIds(uid);
    final visibleTo = <String>{uid, ...viewers}.toList();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));

    await storyRef.set({
      kStoryAuthorId: uid,
      kStoryImageUrl: url,
      kStoryStoragePath: path.fullPath,
      kStoryCaption: caption?.trim() ?? '',
      kStoryCreatedAt: FieldValue.serverTimestamp(),
      kStoryExpiresAt: Timestamp.fromDate(expiresAt),
      kStoryVisibleTo: visibleTo,
    });
    return storyRef.id;
  }

  Stream<List<StoryBucket>> streamStoryBuckets() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);

    return _firestore
        .collection(kStoriesCollection)
        .where(kStoryVisibleTo, arrayContains: uid)
        .limit(120)
        .snapshots()
        .asyncMap((snap) async {
      await _cleanupExpiredStoriesIfNeeded(uid);
      final now = DateTime.now();
      final raw = <StoryItem>[];
      for (final doc in snap.docs) {
        final d = doc.data();
        final created = d[kStoryCreatedAt];
        final expires = d[kStoryExpiresAt];
        if (created is! Timestamp || expires is! Timestamp) continue;
        final story = StoryItem(
          id: doc.id,
          authorId: d[kStoryAuthorId]?.toString() ?? '',
          imageUrl: d[kStoryImageUrl]?.toString() ?? '',
          caption: d[kStoryCaption]?.toString(),
          createdAt: created.toDate(),
          expiresAt: expires.toDate(),
        );
        if (story.authorId.isEmpty || story.imageUrl.isEmpty || story.expiresAt.isBefore(now)) continue;
        raw.add(story);
      }
      if (raw.isEmpty) return <StoryBucket>[];

      final authorIds = raw.map((e) => e.authorId).toSet().toList();
      final profiles = await Future.wait(
        authorIds.map((id) => _firestore.collection(kUsersCollection).doc(id).get()),
      );
      final names = <String, String>{};
      final photos = <String, String?>{};
      for (final p in profiles) {
        final d = p.data();
        final name = d?[kUserName]?.toString().trim();
        final userPhotos = d?[kUserPhotos];
        final photo = userPhotos is List && userPhotos.isNotEmpty ? userPhotos.first?.toString() : null;
        names[p.id] = (name == null || name.isEmpty) ? 'Пользователь' : name;
        photos[p.id] = photo;
      }

      final grouped = <String, List<StoryItem>>{};
      for (final s in raw) {
        final withAuthor = StoryItem(
          id: s.id,
          authorId: s.authorId,
          imageUrl: s.imageUrl,
          createdAt: s.createdAt,
          expiresAt: s.expiresAt,
          caption: s.caption,
          authorName: names[s.authorId],
          authorPhotoUrl: photos[s.authorId],
        );
        grouped.putIfAbsent(s.authorId, () => <StoryItem>[]).add(withAuthor);
      }

      final buckets = grouped.entries
          .map((e) {
            final stories = e.value..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            return StoryBucket(
              authorId: e.key,
              authorName: names[e.key] ?? 'Пользователь',
              authorPhotoUrl: photos[e.key],
              stories: stories,
            );
          })
          .toList()
        ..sort((a, b) => b.latestCreatedAt.compareTo(a.latestCreatedAt));
      return buckets;
    });
  }
}
