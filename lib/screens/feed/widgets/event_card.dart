import 'package:flutter/material.dart';
import '../../../models/event_item.dart';
import '../../../services/event_service.dart';

/// Карточка мероприятия в ленте: фото, сердце, счётчик участников, статус, название, время/место, цена, рейтинг.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.compact = false,
    this.onTap,
  });

  final EventItem event;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final eventService = EventService();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: compact ? 0.85 : 1.35,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                      Image.network(
                        event.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                        ),
                      )
                    else
                      Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.event, size: 48, color: Colors.grey),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => eventService.toggleEventLike(event.id),
                        child: Icon(
                          event.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${event.currentParticipants}/${event.maxParticipants}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: event.status == 'full'
                    ? Colors.orange.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: event.status == 'full' ? Colors.orange.shade800 : Colors.green.shade800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (event.dateTimeLabel.isNotEmpty) ...[
                  Text(
                    '${event.dateTimeLabel} ${event.venueName ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  if (event.venueName != null && event.venueName!.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (event.price != null && event.price!.isNotEmpty)
                  Text(
                    '${event.price}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                  ),
                if (event.rating != null) ...[
                  if (event.price != null && event.price!.isNotEmpty) const SizedBox(width: 8),
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    event.rating!.toStringAsFixed(1),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
