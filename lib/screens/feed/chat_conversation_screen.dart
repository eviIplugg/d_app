import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth/auth_service.dart';
import '../../services/chat_service.dart';

/// Экран переписки: сообщения (входящие слева/серые, исходящие справа/оранжевые), ввод и отправка текста/фото.
class ChatConversationScreen extends StatefulWidget {
  const ChatConversationScreen({
    super.key,
    required this.matchId,
    required this.otherUserId,
    required this.otherName,
    this.otherPhotoUrl,
  });

  final String matchId;
  final String otherUserId;
  final String otherName;
  final String? otherPhotoUrl;

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chat = ChatService();
  final AuthService _auth = AuthService();

  static const Color _accentColor = Color(0xFF81262B);

  bool _isAtBottom = true;
  int _newMessagesCountBelow = 0;
  int _lastMessageCount = 0;
  bool _initialScrollDone = false;
  bool _scrollStateUpdateScheduled = false;

  @override
  void initState() {
    super.initState();
    _chat.markAsRead(widget.matchId);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final atBottom = pos.pixels <= 80;
    final needClearCount = atBottom && _newMessagesCountBelow > 0;
    final needUpdateAtBottom = atBottom != _isAtBottom;
    if ((needClearCount || needUpdateAtBottom) && !_scrollStateUpdateScheduled) {
      _scrollStateUpdateScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollStateUpdateScheduled = false;
        if (!mounted) return;
        setState(() {
          if (needClearCount) _newMessagesCountBelow = 0;
          if (needUpdateAtBottom) _isAtBottom = atBottom;
        });
      });
    }
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() {
      _isAtBottom = true;
      _newMessagesCountBelow = 0;
    });
    _scrollToBottomInstant();
    _chat.sendText(widget.matchId, text);
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null || !mounted) return;
    final file = File(xFile.path);
    try {
      final url = await _chat.uploadChatImage(widget.matchId, file);
      if (!mounted) return;
      await _chat.sendImage(widget.matchId, url);
      setState(() {
        _isAtBottom = true;
        _newMessagesCountBelow = 0;
      });
      _scrollToBottomInstant();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить фото: $e')),
        );
      }
    }
  }

  void _scrollToBottomInstant() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _goToBottom() {
    setState(() {
      _isAtBottom = true;
      _newMessagesCountBelow = 0;
    });
    _scrollToBottomInstant();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.otherName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            Text(
              'В сети',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 20,
              backgroundImage:
                  widget.otherPhotoUrl != null ? NetworkImage(widget.otherPhotoUrl!) : null,
              child: widget.otherPhotoUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                StreamBuilder<List<ChatMessage>>(
                  stream: _chat.streamMessages(widget.matchId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: _accentColor));
                    }
                    final messages = snapshot.data!;
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Напишите сообщение',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    if (messages.length != _lastMessageCount) {
                      final len = messages.length;
                      final prevCount = _lastMessageCount;
                      _lastMessageCount = len;
                      if (!_initialScrollDone && len > 0) {
                        _initialScrollDone = true;
                        _scrollToBottomInstant();
                      } else if (len > prevCount) {
                        final newCount = len - prevCount;
                        if (_isAtBottom) {
                          _scrollToBottomInstant();
                        } else {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _newMessagesCountBelow += newCount);
                          });
                        }
                      }
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 8,
                        bottom: 8,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[messages.length - 1 - index];
                        final isMe = msg.senderId == _auth.currentUserId;
                        return _MessageBubble(message: msg, isMe: isMe);
                      },
                    );
                  },
                ),
                if (!_isAtBottom || _newMessagesCountBelow > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 16),
                    child: _ScrollDownButton(
                      newCount: _newMessagesCountBelow,
                      onTap: _goToBottom,
                    ),
                  ),
              ],
            ),
          ),
          _InputBar(
            controller: _controller,
            onSend: _sendText,
            onAttach: _pickAndSendImage,
          ),
        ],
      ),
    );
  }
}

class _ScrollDownButton extends StatelessWidget {
  const _ScrollDownButton({
    required this.newCount,
    required this.onTap,
  });

  final int newCount;
  final VoidCallback onTap;

  static const Color _accent = Color(0xFF81262B);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.keyboard_arrow_down, size: 32, color: _accent),
              if (newCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(minWidth: 20),
                    child: Text(
                      newCount > 99 ? '99+' : '$newCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  static const Color _incomingColor = Color(0xFFEEEEEE);
  static const Color _outgoingColor = Color(0xFFE8A87C);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? _outgoingColor : _incomingColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.isImage && message.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.imageUrl!,
                  width: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loading) {
                    if (loading == null) return child;
                    return const SizedBox(
                      width: 200,
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              )
            else
              Text(
                message.text ?? '',
                style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.done_all,
                  size: 14,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.attach_file, color: Colors.grey.shade700),
              onPressed: onAttach,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Сообщение',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                onSubmitted: (_) => onSend(),
              ),
            ),
            IconButton(
              icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey.shade700),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
            Material(
              color: const Color(0xFF81262B),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onSend,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
