import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/feed_user.dart';
import '../../services/auth/auth_service.dart';
import '../../services/feed_service.dart';
import '../feed/chat_conversation_screen.dart';
import 'widgets/feed_card.dart';
import 'widgets/swipeable_feed_card.dart';
import 'feed_full_profile_sheet.dart';
import 'feed_match_dialog.dart';
import 'feed_filters_screen.dart';

/// Тело ленты (свайпы, кнопки, мэтч, полный профиль). Без AppBar — для использования в Ленте и Поиске.
class FeedContent extends StatefulWidget {
  const FeedContent({super.key});

  @override
  State<FeedContent> createState() => FeedContentState();
}

class FeedContentState extends State<FeedContent> {
  final FeedService _feedService = FeedService();
  List<FeedUser> _candidates = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Небольшая задержка, чтобы токен анонимного/только что вошедшего пользователя успел подставиться в запросы.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _loadCandidates();
    });
  }

  void loadCandidates() => _loadCandidates();

  Future<void> _loadCandidates() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _feedService.getCandidates();
      if (!mounted) return;
      setState(() {
        _candidates = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      final String message = e is FirebaseException
          ? (e.code == 'permission-denied'
              ? 'Нет доступа. Выйдите из аккаунта и войдите снова.'
              : e.message ?? e.code)
          : e.toString();
      setState(() {
        _loading = false;
        _error = message;
      });
    }
  }

  void _onSwipe(FeedUser user, bool isLike) async {
    if (_candidates.isEmpty) return;
    setState(() {
      _candidates = _candidates.where((c) => c.uid != user.uid).toList();
    });
    final matchId = await _feedService.recordSwipe(targetUserId: user.uid, isLike: isLike);
    if (!mounted) return;
    if (matchId != null) {
      final other = await _feedService.getUser(user.uid);
      final me = AuthService().currentUserId != null ? await _feedService.getUser(AuthService().currentUserId!) : null;
      if (!mounted) return;
      final matched = other ?? user;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => FeedMatchDialog(
          currentUser: me,
          matchedUser: matched,
          onStartChat: () {
            Navigator.pop(ctx);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => ChatConversationScreen(
                  matchId: matchId,
                  otherUserId: matched.uid,
                  otherName: matched.name,
                  otherPhotoUrl: matched.photoUrls.isNotEmpty ? matched.photoUrls.first : null,
                ),
              ),
            );
          },
          onPlanActivity: () => Navigator.pop(ctx),
          onClose: () => Navigator.pop(ctx),
        ),
      );
    }
  }

  void _openFullProfile(FeedUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FeedFullProfileSheet(
        user: user,
        onClose: () => Navigator.pop(ctx),
        onPhotoTap: () {
          Navigator.pop(ctx);
          _openPhotoGallery(user);
        },
      ),
    );
  }

  void _openPhotoGallery(FeedUser user) {
    if (user.photoUrls.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => _PhotoGalleryScreen(photos: user.photoUrls, name: user.name),
      ),
    );
  }

  Future<void> openFiltersAndReload() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const FeedFiltersScreen()),
    );
    _loadCandidates();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Не удалось загрузить анкеты',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadCandidates,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF81262B)),
              ),
            ],
          ),
        ),
      );
    }
    if (_candidates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Нет новых анкет', style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _loadCandidates,
              icon: const Icon(Icons.refresh),
              label: const Text('Обновить'),
            ),
          ],
        ),
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        for (var i = 1; i < _candidates.length && i <= 2; i++) ...[
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(left: 12 + i * 8.0, right: 12 + i * 8.0, top: 12 + i * 8.0, bottom: 100 + i * 8.0),
              child: RepaintBoundary(
                child: FeedCard(
                  user: _candidates[i],
                  onTapArrow: () => _openFullProfile(_candidates[i]),
                  onTapPhoto: () => _openFullProfile(_candidates[i]),
                ),
              ),
            ),
          ),
        ],
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 100),
            child: RepaintBoundary(
              child: SwipeableFeedCard(
                key: ValueKey<String>(_candidates.first.uid),
                user: _candidates.first,
                onSwipe: (like) => _onSwipe(_candidates.first, like),
                onOpenProfile: () => _openFullProfile(_candidates.first),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionButton(Icons.close, const Color(0xFF333333), () {
                if (_candidates.isNotEmpty) _onSwipe(_candidates.first, false);
              }),
              const SizedBox(width: 20),
              _actionButton(Icons.star, const Color(0xFFE91E63), () {
                if (_candidates.isNotEmpty) _onSwipe(_candidates.first, true);
              }),
              const SizedBox(width: 20),
              _actionButton(Icons.home_outlined, Colors.grey.shade600, () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

class _PhotoGalleryScreen extends StatelessWidget {
  final List<String> photos;
  final String name;

  const _PhotoGalleryScreen({required this.photos, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('$name — ${photos.length} фото', style: const TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: PageView.builder(
        itemCount: photos.length,
        itemBuilder: (ctx, i) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${i + 1} из ${photos.length}', style: const TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 16),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    photos[i],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, _) => const Icon(Icons.broken_image, size: 80, color: Colors.white54),
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
