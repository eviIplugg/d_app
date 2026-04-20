import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firestore_schema.dart';
import 'auth/auth_service.dart';
import 'like_notification_service.dart';

class PostComment {
  PostComment({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.likeCount = 0,
    List<String>? likedByIn,
  }) : likedBy = List<String>.from(likedByIn ?? const []);

  final String id;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final int likeCount;
  final List<String> likedBy;

  bool isLikedBy(String uid) => likedBy.contains(uid);

  static PostComment fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final t = d[kCommentCreatedAt];
    final liked = d[kCommentLikedBy];
    final List<String> likedList = liked is List
        ? (liked).map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : [];
    final lc = d[kCommentLikeCount];
    return PostComment(
      id: doc.id,
      authorId: d[kCommentAuthorId]?.toString() ?? '',
      text: d[kCommentText]?.toString() ?? '',
      createdAt: t is Timestamp ? t.toDate() : DateTime.now(),
      likeCount: lc is int ? lc : 0,
      likedByIn: likedList,
    );
  }
}

class PostCommentService {
  PostCommentService._();
  static final PostCommentService _instance = PostCommentService._();
  factory PostCommentService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthService get _auth => AuthService();

  CollectionReference<Map<String, dynamic>> _col(String postId) =>
      _firestore.collection(kPostsCollection).doc(postId).collection(kPostCommentsSubcollection);

  Stream<List<PostComment>> streamComments(String postId) {
    return _col(postId).orderBy(kCommentCreatedAt, descending: true).limit(100).snapshots().map(
          (s) => s.docs.map(PostComment.fromDoc).toList(),
        );
  }

  Future<void> addComment(String postId, String text) async {
    final uid = _auth.currentUserId;
    if (uid == null || text.trim().isEmpty) return;
    await _col(postId).add({
      kCommentAuthorId: uid,
      kCommentText: text.trim(),
      kCommentCreatedAt: FieldValue.serverTimestamp(),
      kCommentLikeCount: 0,
      kCommentLikedBy: <String>[],
    });
  }

  /// Лайк комментария: мгновенное переключение на клиенте, затем транзакция.
  Future<void> toggleCommentLike(String postId, String commentId) async {
    final uid = _auth.currentUserId;
    if (uid == null) throw StateError('Необходимо войти в аккаунт');
    final postRef = _firestore.collection(kPostsCollection).doc(postId);
    final commentRef = postRef.collection(kPostCommentsSubcollection).doc(commentId);
    var becameLiked = false;
    String? commentAuthorId;
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(commentRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      commentAuthorId = data[kCommentAuthorId]?.toString();
      final likedBy = List<String>.from((data[kCommentLikedBy] as List?)?.map((e) => e.toString()) ?? []);
      final count = (data[kCommentLikeCount] as int?) ?? 0;
      final had = likedBy.contains(uid);
      if (had) {
        likedBy.remove(uid);
        becameLiked = false;
        tx.update(commentRef, {kCommentLikedBy: likedBy, kCommentLikeCount: count > 0 ? count - 1 : 0});
      } else {
        likedBy.add(uid);
        becameLiked = true;
        tx.update(commentRef, {kCommentLikedBy: likedBy, kCommentLikeCount: count + 1});
      }
    });
    if (becameLiked && commentAuthorId != null && commentAuthorId != uid) {
      unawaited(
        LikeNotificationService().notifyCommentLiked(
          recipientId: commentAuthorId!,
          postId: postId,
          commentId: commentId,
          actorId: uid,
        ),
      );
    }
  }
}
