import 'package:flutter/material.dart';

import '../../../firebase/firestore_schema.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/post_comment_service.dart';

/// Отдельное окно (bottom sheet) со списком комментариев к посту.
Future<void> showPostCommentsSheet(BuildContext context, String postId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _PostCommentsBody(postId: postId),
  );
}

class _PostCommentsBody extends StatefulWidget {
  const _PostCommentsBody({required this.postId});

  final String postId;

  @override
  State<_PostCommentsBody> createState() => _PostCommentsBodyState();
}

class _PostCommentsBodyState extends State<_PostCommentsBody> {
  final PostCommentService _comments = PostCommentService();
  final AuthService _auth = AuthService();
  final TextEditingController _controller = TextEditingController();
  final Map<String, String> _authorNames = {};
  final Set<String> _authorLoadsPending = {};
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAuthorNames(Iterable<String> uids) {
    for (final uid in uids) {
      if (uid.isEmpty || _authorNames.containsKey(uid) || _authorLoadsPending.contains(uid)) continue;
      _authorLoadsPending.add(uid);
      _auth.getUserProfile(uid).then((p) {
        _authorLoadsPending.remove(uid);
        if (!mounted) return;
        final n = p?[kUserName]?.toString().trim();
        setState(() {
          _authorNames[uid] = (n != null && n.isNotEmpty) ? n : 'Пользователь';
        });
      });
    }
  }

  Future<void> _send() async {
    final t = _controller.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _comments.addComment(widget.postId, t);
      if (mounted) _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось отправить: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Комментарии',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<List<PostComment>>(
                  stream: _comments.streamComments(widget.postId),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(child: Text('Ошибка: ${snap.error}', textAlign: TextAlign.center));
                    }
                    final list = snap.data ?? [];
                    _scheduleAuthorNames(list.map((c) => c.authorId));
                    if (list.isEmpty && snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF81262B)));
                    }
                    if (list.isEmpty) {
                      return Center(
                        child: Text('Пока нет комментариев', style: TextStyle(color: Colors.grey.shade600)),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final c = list[i];
                        final name = _authorNames[c.authorId] ?? '…';
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade900, height: 1.35),
                                  children: [
                                    TextSpan(
                                      text: '$name ',
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                                    ),
                                    TextSpan(text: c.text),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              _formatTime(c.createdAt),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: 'Комментарий…',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF81262B)),
                      icon: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime t) {
    final now = DateTime.now();
    if (now.difference(t).inDays >= 1) {
      return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}';
    }
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
