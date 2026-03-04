import 'package:flutter/material.dart';
import '../../models/feed_user.dart';

/// Нижний лист с полным профилем пользователя; по нажатию на фото — колбэк для открытия галереи.
class FeedFullProfileSheet extends StatelessWidget {
  final FeedUser user;
  final VoidCallback onClose;
  final VoidCallback? onPhotoTap;

  const FeedFullProfileSheet({
    super.key,
    required this.user,
    required this.onClose,
    this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${user.name}, ${user.age ?? "—"}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (user.photoUrls.isNotEmpty)
                    GestureDetector(
                      onTap: onPhotoTap,
                      child: SizedBox(
                        height: 320,
                        child: PageView.builder(
                          itemCount: user.photoUrls.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                user.photoUrls[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, _) => Container(color: Colors.grey.shade200, child: const Icon(Icons.person, size: 80)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (user.photoUrls.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Нажмите на фото, чтобы открыть все (${user.photoUrls.length})', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ),
                  const SizedBox(height: 20),
                  if (user.city != null) _row('Город', user.city!),
                  if (user.relationshipGoalLabel.isNotEmpty) _row('Цель', user.relationshipGoalLabel),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('О себе', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(user.bio!, style: const TextStyle(fontSize: 14)),
                  ],
                  if (user.interests.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Интересы', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.interests.map((e) => Chip(label: Text(e))).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
