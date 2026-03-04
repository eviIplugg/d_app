import 'package:flutter/material.dart';
import '../../../models/feed_user.dart';

/// Одна карточка в ленте: фото, имя, возраст, город, дистанция, цель, теги, био, стрелка.
class FeedCard extends StatelessWidget {
  final FeedUser user;
  final VoidCallback? onTapArrow;
  final VoidCallback? onTapPhoto;

  const FeedCard({
    super.key,
    required this.user,
    this.onTapArrow,
    this.onTapPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoUrls.isNotEmpty ? user.photoUrls.first : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Фото с оверлеями
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: onTapPhoto,
                    child: photoUrl != null
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, _) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  // Верх: город, дистанция, цель
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        _chip(Icons.location_city, user.city ?? 'Город'),
                        const SizedBox(width: 8),
                        _chip(Icons.pin_drop, user.distanceKm != null ? '${user.distanceKm!.round()} км' : '—'),
                        const SizedBox(width: 8),
                        _chip(Icons.favorite_border, user.relationshipGoalLabel),
                        const Spacer(),
                        if (user.isVerified)
                          const Icon(Icons.verified, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                  // Индикатор фото (1 из N)
                  if (user.photoUrls.length > 1)
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '1 из ${user.photoUrls.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  // Низ: имя, возраст, стрелка
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${user.name}, ${user.age ?? "—"}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (onTapArrow != null)
                                      GestureDetector(
                                        onTap: onTapArrow,
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF333333),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    ...user.interests.take(5).map((e) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(e, style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
                                        )),
                                    if (user.interests.length > 5)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text('+${user.interests.length - 5}', style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
                                      ),
                                  ],
                                ),
                                if (user.bio != null && user.bio!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    user.bio!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.person, size: 80, color: Colors.white70),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
