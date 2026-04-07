import 'package:flutter/material.dart';

import '../../models/story_item.dart';
import '../../services/auth/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/story_service.dart';
import '../../utils/presence_utils.dart';
import '../../widgets/story_ring_avatar.dart';
import 'chat_conversation_screen.dart';
import 'story_viewer_screen.dart';

/// Чаты: пустое состояние или список диалогов с бейджем непрочитанных.
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Чаты')),
      body: StreamBuilder<List<ChatListItem>>(
        stream: ChatService().streamChatList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return _EmptyChatState();
          }
          return StreamBuilder<List<StoryBucket>>(
            stream: StoryService().streamStoryBuckets(),
            builder: (context, storySnap) {
              final buckets = storySnap.data ?? const <StoryBucket>[];
              final storiesByUser = <String, StoryBucket>{for (final b in buckets) b.authorId: b};
              return _ChatListBody(
                chatList: list,
                storiesByUser: storiesByUser,
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Мэтчитесь и учавствуйте в активностях',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _EmptyChatState._textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Здесь будет находиться переписка',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Color _textColor = Color(0xFF333333);
}

class _ChatListBody extends StatelessWidget {
  const _ChatListBody({required this.chatList, required this.storiesByUser});

  final List<ChatListItem> chatList;
  final Map<String, StoryBucket> storiesByUser;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      cacheExtent: 280,
      slivers: [
        SliverToBoxAdapter(
          child: _HorizontalContactsRow(chatList: chatList, storiesByUser: storiesByUser),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = chatList[index];
              final bucket = storiesByUser[item.otherUserId];
              return RepaintBoundary(
                child: _ChatListTile(
                  item: item,
                  hasStory: bucket != null,
                  onTapStory: bucket == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => StoryViewerScreen(
                                stories: bucket.stories,
                                authorName: bucket.authorName,
                                authorPhotoUrl: bucket.authorPhotoUrl,
                              ),
                            ),
                          );
                        },
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => ChatConversationScreen(
                          matchId: item.matchId,
                          otherUserId: item.otherUserId,
                          otherName: item.otherName,
                          otherPhotoUrl: item.otherPhotoUrl,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            childCount: chatList.length,
            addAutomaticKeepAlives: true,
          ),
        ),
      ],
    );
  }
}

class _HorizontalContactsRow extends StatelessWidget {
  const _HorizontalContactsRow({required this.chatList, required this.storiesByUser});

  final List<ChatListItem> chatList;
  final Map<String, StoryBucket> storiesByUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 88,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          cacheExtent: 120,
          itemCount: 1 + (chatList.length > 10 ? 10 : chatList.length),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const RepaintBoundary(
                child: Padding(padding: EdgeInsets.only(right: 16), child: _AddContactChip()),
              );
            }
            final item = chatList[index - 1];
            final bucket = storiesByUser[item.otherUserId];
            return RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _ContactAvatar(
                  name: item.otherName,
                  photoUrl: item.otherPhotoUrl,
                  hasStory: bucket != null,
                  onTap: bucket == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => StoryViewerScreen(
                                stories: bucket.stories,
                                authorName: bucket.authorName,
                                authorPhotoUrl: bucket.authorPhotoUrl,
                              ),
                            ),
                          );
                        },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AddContactChip extends StatelessWidget {
  const _AddContactChip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.add, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            'Добавить',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({
    required this.name,
    this.photoUrl,
    this.hasStory = false,
    this.onTap,
  });

  final String name;
  final String? photoUrl;
  final bool hasStory;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: hasStory
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF81262B), width: 2),
                    )
                  : null,
              child: CircleAvatar(
                radius: 24,
                backgroundImage: photoUrl != null
                    ? ResizeImage(NetworkImage(photoUrl!), width: 96, height: 96)
                    : null,
                child: photoUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  const _ChatListTile({
    required this.item,
    required this.onTap,
    this.hasStory = false,
    this.onTapStory,
  });

  final ChatListItem item;
  final VoidCallback onTap;
  final bool hasStory;
  final VoidCallback? onTapStory;

  @override
  Widget build(BuildContext context) {
    final isMe = item.lastMessageSenderId == AuthService().currentUserId;
    final presenceLabel = PresenceUtils.shortLabel(item.otherLastActiveAt);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: onTapStory,
                  child: StoryRingAvatar(
                    radius: 28,
                    photoUrl: item.otherPhotoUrl,
                    hasStory: hasStory,
                    resizeWidth: 112,
                  ),
                ),
                if (PresenceUtils.isOnlineNow(item.otherLastActiveAt))
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.otherName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      if (item.lastMessageAt != null)
                        Text(
                          _formatTime(item.lastMessageAt!),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                  if (presenceLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      presenceLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: PresenceUtils.isOnlineNow(item.otherLastActiveAt)
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isMe)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            'Вы',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          item.lastMessagePreview ?? 'Нет сообщений',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ),
                      if (item.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.done_all, size: 16, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    if (t.day == now.day && t.month == now.month && t.year == now.year) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}';
  }

}
