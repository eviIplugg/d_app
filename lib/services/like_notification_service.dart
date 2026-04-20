import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firestore_schema.dart';
import 'auth/auth_service.dart';

class LikeNotificationItem {
  LikeNotificationItem({
    required this.id,
    required this.type,
    required this.actorId,
    required this.postId,
    this.commentId,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String actorId;
  final String postId;
  final String? commentId;
  final bool read;
  final DateTime createdAt;

  bool get isCommentLike => type == 'comment_like';

  static LikeNotificationItem fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final t = d[kNotifCreatedAt];
    return LikeNotificationItem(
      id: doc.id,
      type: d[kNotifType]?.toString() ?? 'post_like',
      actorId: d[kNotifActorId]?.toString() ?? '',
      postId: d[kNotifPostId]?.toString() ?? '',
      commentId: d[kNotifCommentId]?.toString(),
      read: d[kNotifRead] == true,
      createdAt: t is Timestamp ? t.toDate() : DateTime.now(),
    );
  }
}

/// Уведомления о лайках постов и комментариев: `users/{uid}/likeNotifications`.
class LikeNotificationService {
  LikeNotificationService._();
  static final LikeNotificationService _instance = LikeNotificationService._();
  factory LikeNotificationService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthService get _auth => AuthService();

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection(kUsersCollection).doc(uid).collection(kLikeNotificationsSubcollection);

  /// Лайк поста (уведомление автору поста).
  Future<void> notifyPostLiked({
    required String recipientId,
    required String postId,
    required String actorId,
  }) async {
    if (recipientId == actorId) return;
    await _col(recipientId).add({
      kNotifType: 'post_like',
      kNotifActorId: actorId,
      kNotifPostId: postId,
      kNotifRead: false,
      kNotifCreatedAt: FieldValue.serverTimestamp(),
    });
  }

  /// Лайк комментария (уведомление автору комментария).
  Future<void> notifyCommentLiked({
    required String recipientId,
    required String postId,
    required String commentId,
    required String actorId,
  }) async {
    if (recipientId == actorId) return;
    await _col(recipientId).add({
      kNotifType: 'comment_like',
      kNotifActorId: actorId,
      kNotifPostId: postId,
      kNotifCommentId: commentId,
      kNotifRead: false,
      kNotifCreatedAt: FieldValue.serverTimestamp(),
    });
  }

  Stream<int> streamUnreadCount() {
    final uid = _auth.currentUserId;
    if (uid == null) {
      return Stream<int>.value(0);
    }
    return _col(uid).where(kNotifRead, isEqualTo: false).snapshots().map((s) => s.docs.length);
  }

  Stream<List<LikeNotificationItem>> streamNotifications({int limit = 40}) {
    final uid = _auth.currentUserId;
    if (uid == null) {
      return Stream<List<LikeNotificationItem>>.value(const []);
    }
    return _col(uid).orderBy(kNotifCreatedAt, descending: true).limit(limit).snapshots().map(
          (s) => s.docs.map(LikeNotificationItem.fromDoc).toList(),
        );
  }

  Future<void> markRead(String notificationId) async {
    final uid = _auth.currentUserId;
    if (uid == null) return;
    await _col(uid).doc(notificationId).update({kNotifRead: true});
  }

  Future<void> markAllRead() async {
    final uid = _auth.currentUserId;
    if (uid == null) return;
    final snap = await _col(uid).where(kNotifRead, isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {kNotifRead: true});
    }
    await batch.commit();
  }
}
