import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firestore_schema.dart';
import 'auth/auth_service.dart';

class PostComment {
  PostComment({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String text;
  final DateTime createdAt;

  static PostComment fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final t = d[kCommentCreatedAt];
    return PostComment(
      id: doc.id,
      authorId: d[kCommentAuthorId]?.toString() ?? '',
      text: d[kCommentText]?.toString() ?? '',
      createdAt: t is Timestamp ? t.toDate() : DateTime.now(),
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
    });
  }
}
