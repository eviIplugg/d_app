import 'package:flutter/material.dart';
import '../../models/feed_user.dart';

/// Диалог «Это мэтч!»: фото обоих, % совместимости, общие интересы, кнопки «Начать общение» и «Запланировать активность».
class FeedMatchDialog extends StatelessWidget {
  final FeedUser? currentUser;
  final FeedUser matchedUser;
  final VoidCallback? onStartChat;
  final VoidCallback? onPlanActivity;
  final VoidCallback? onClose;

  const FeedMatchDialog({
    super.key,
    this.currentUser,
    required this.matchedUser,
    this.onStartChat,
    this.onPlanActivity,
    this.onClose,
  });

  int get _compatibilityPercent {
    if (currentUser == null || currentUser!.interests.isEmpty) return 92;
    final mine = currentUser!.interests.map((e) => e.toLowerCase()).toSet();
    final other = matchedUser.interests.map((e) => e.toLowerCase()).toSet();
    final common = mine.intersection(other).length;
    if (mine.isEmpty) return 92;
    return ((common / mine.length) * 50 + 50).round().clamp(50, 99);
  }

  List<String> get _sharedInterests {
    if (currentUser == null) return matchedUser.interests.take(4).toList();
    final mine = currentUser!.interests.map((e) => e.toLowerCase()).toSet();
    final other = matchedUser.interests.map((e) => e.toLowerCase()).toSet();
    final common = mine.intersection(other).toList();
    if (common.isEmpty) return matchedUser.interests.take(4).toList();
    return matchedUser.interests.where((e) => common.contains(e.toLowerCase())).take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F0),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF333333)),
                  onPressed: onClose ?? () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _avatar(currentUser?.photoUrls.isNotEmpty == true ? currentUser!.photoUrls.first : null, 72),
                  const SizedBox(width: 8),
                  _avatar(matchedUser.photoUrls.isNotEmpty ? matchedUser.photoUrls.first : null, 72),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Это мэтч!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, size: 20, color: Colors.red.shade300),
                  const SizedBox(width: 6),
                  Text(
                    '$_compatibilityPercent% совместимости',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              if (_sharedInterests.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Общие интересы', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: _sharedInterests.map((e) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF81262B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onStartChat ?? () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Начать общение', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onPlanActivity ?? () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: const Text('Запланировать активность', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(String? photoUrl, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, _) => _placeholder())
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(color: Colors.grey.shade300, child: const Icon(Icons.person, size: 36, color: Colors.white70));
}
