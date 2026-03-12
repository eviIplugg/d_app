import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import '../../services/chat_service.dart';
import 'chat_conversation_screen.dart';

/// Чаты: пустое состояние или список диалогов с бейджем непрочитанных.
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  static const Color _titleColor = Color(0xFF333333);
  static const Color _accentColor = Color(0xFF81262B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Чаты',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _titleColor,
          ),
        ),
      ),
      body: StreamBuilder<List<ChatListItem>>(
        stream: ChatService().streamChatList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: _accentColor));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return _EmptyChatState();
          }
          return _ChatListBody(chatList: list);
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
  const _ChatListBody({required this.chatList});

  final List<ChatListItem> chatList;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _HorizontalContactsRow(chatList: chatList),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = chatList[index];
              return _ChatListTile(
                item: item,
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
              );
            },
            childCount: chatList.length,
          ),
        ),
      ],
    );
  }
}

class _HorizontalContactsRow extends StatelessWidget {
  const _HorizontalContactsRow({required this.chatList});

  final List<ChatListItem> chatList;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 80,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _AddContactChip(),
            ...chatList.take(10).map((item) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _ContactAvatar(
                    name: item.otherName,
                    photoUrl: item.otherPhotoUrl,
                    hasStory: item.unreadCount > 0,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _AddContactChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.add, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            'Добавить',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
  });

  final String name;
  final String? photoUrl;
  final bool hasStory;

  @override
  Widget build(BuildContext context) {
    return Column(
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
            radius: 26,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 56,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

class _ChatListTile extends StatelessWidget {
  const _ChatListTile({required this.item, required this.onTap});

  final ChatListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMe = item.lastMessageSenderId == AuthService().currentUserId;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: item.otherPhotoUrl != null ? NetworkImage(item.otherPhotoUrl!) : null,
              child: item.otherPhotoUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
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
