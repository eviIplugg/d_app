import 'package:flutter/material.dart';

import '../../firebase/firestore_schema.dart';
import '../../services/auth/auth_service.dart';
import '../../services/like_notification_service.dart';
import 'widgets/post_comments_sheet.dart';

Future<void> showLikeNotificationsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => const _LikeNotificationsBody(),
  );
}

class _LikeNotificationsBody extends StatelessWidget {
  const _LikeNotificationsBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Лайки',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () => LikeNotificationService().markAllRead(),
                    child: const Text('Прочитать все'),
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
              child: StreamBuilder<List<LikeNotificationItem>>(
                stream: LikeNotificationService().streamNotifications(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('${snap.error}', textAlign: TextAlign.center));
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'Пока нет уведомлений',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final n = list[i];
                      return _NotificationTile(item: n);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatefulWidget {
  const _NotificationTile({required this.item});

  final LikeNotificationItem item;

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  final AuthService _auth = AuthService();
  String? _actorName;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final id = widget.item.actorId;
    if (id.isEmpty) return;
    final p = await _auth.getUserProfile(id);
    if (!mounted) return;
    final n = p?[kUserName]?.toString().trim();
    setState(() => _actorName = (n != null && n.isNotEmpty) ? n : 'Пользователь');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = widget.item;
    final title = n.isCommentLike ? 'Оценил ваш комментарий' : 'Оценил ваш пост';
    final subtitle = _formatTime(n.createdAt);
    return ListTile(
      tileColor: n.read ? null : theme.colorScheme.primary.withValues(alpha: 0.06),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
        child: Icon(Icons.favorite, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(_actorName ?? '…', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('$title · $subtitle', style: theme.textTheme.bodySmall),
      onTap: () async {
        await LikeNotificationService().markRead(n.id);
        if (!context.mounted) return;
        Navigator.pop(context);
        await showPostCommentsSheet(
          context,
          n.postId,
          scrollToCommentId: n.isCommentLike ? n.commentId : null,
        );
      },
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
