import 'package:flutter/material.dart';

import '../../services/like_notification_service.dart';
import 'feed_posts_body.dart';
import 'like_notifications_sheet.dart';

/// Лента в стиле Instagram: сторис + посты. Добавление постов через кнопку «Добавить» в сторис.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Лента'),
        actions: [
          StreamBuilder<int>(
            stream: LikeNotificationService().streamUnreadCount(),
            builder: (context, snap) {
              final n = snap.data ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Badge(
                  isLabelVisible: n > 0,
                  label: Text(n > 99 ? '99+' : '$n'),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Уведомления о лайках',
                    onPressed: () => showLikeNotificationsSheet(context),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: const FeedPostsBody(),
    );
  }
}
