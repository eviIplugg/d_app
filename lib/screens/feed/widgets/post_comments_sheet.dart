import 'package:flutter/material.dart';

import '../../../firebase/firestore_schema.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/post_comment_service.dart';

/// Окно со списком комментариев к посту. [scrollToCommentId] — прокрутка к комментарию (например из уведомления).
Future<void> showPostCommentsSheet(
  BuildContext context,
  String postId, {
  String? scrollToCommentId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _PostCommentsBody(
      postId: postId,
      scrollToCommentId: scrollToCommentId,
    ),
  );
}

class _PostCommentsBody extends StatefulWidget {
  const _PostCommentsBody({
    required this.postId,
    this.scrollToCommentId,
  });

  final String postId;
  final String? scrollToCommentId;

  @override
  State<_PostCommentsBody> createState() => _PostCommentsBodyState();
}

class _PostCommentsBodyState extends State<_PostCommentsBody> {
  final PostCommentService _comments = PostCommentService();
  final AuthService _auth = AuthService();
  final TextEditingController _controller = TextEditingController();
  final Map<String, String> _authorNames = {};
  final Set<String> _authorLoadsPending = {};
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _commentKeys = {};
  bool _sending = false;
  bool _didScrollTo = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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

  void _tryScrollToComment(List<PostComment> list) {
    final id = widget.scrollToCommentId;
    if (id == null || id.isEmpty || _didScrollTo) return;
    final idx = list.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _commentKeys[id];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, alignment: 0.15, duration: const Duration(milliseconds: 300));
      }
      _didScrollTo = true;
    });
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

  Future<void> _toggleCommentLike(PostComment c) async {
    try {
      await _comments.toggleCommentLike(widget.postId, c.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final uid = _auth.currentUserId;

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
                    Expanded(
                      child: Text(
                        'Комментарии',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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
                    _tryScrollToComment(list);
                    if (list.isEmpty && snap.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                    }
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          'Пока нет комментариев',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final c = list[i];
                        _commentKeys.putIfAbsent(c.id, GlobalKey.new);
                        final name = _authorNames[c.authorId] ?? '…';
                        final liked = uid != null && c.isLikedBy(uid);
                        return _CommentRow(
                          key: _commentKeys[c.id],
                          name: name,
                          text: c.text,
                          time: _formatTime(c.createdAt),
                          likeCount: c.likeCount,
                          liked: liked,
                          onLike: () => _toggleCommentLike(c),
                          theme: theme,
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
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                      style: IconButton.styleFrom(backgroundColor: theme.colorScheme.primary),
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

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    super.key,
    required this.name,
    required this.text,
    required this.time,
    required this.likeCount,
    required this.liked,
    required this.onLike,
    required this.theme,
  });

  final String name;
  final String text;
  final String time;
  final int likeCount;
  final bool liked;
  final VoidCallback onLike;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface, height: 1.35),
              children: [
                TextSpan(
                  text: '$name ',
                  style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(time, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            InkWell(
              onTap: onLike,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: liked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                    if (likeCount > 0) ...[
                      const SizedBox(width: 2),
                      Text(
                        '$likeCount',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
