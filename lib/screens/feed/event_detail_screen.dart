import 'package:flutter/material.dart';
import '../../models/event_item.dart';
import '../../services/event_service.dart';
import 'event_photo_grid_screen.dart';

/// Страница мероприятия: баннер, название, дата/время, место, описание, организатор (подписка), адрес, кнопка «Присоединиться».
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.onSubscriptionChanged,
    this.onJoinChanged,
  });

  final String eventId;
  final VoidCallback? onSubscriptionChanged;
  final VoidCallback? onJoinChanged;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventService _eventService = EventService();
  EventItem? _event;
  VenueItem? _venue;
  bool _loading = true;
  bool _subscribed = false;
  bool _showSubscriptionBanner = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final event = await _eventService.getEvent(widget.eventId);
    if (event == null || !mounted) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    VenueItem? venue;
    if (event.venueId != null && event.venueId!.isNotEmpty) {
      venue = await _eventService.getVenue(event.venueId!);
      final sub = await _eventService.isSubscribedToVenue(event.venueId!);
      if (mounted) setState(() => _subscribed = sub);
    }
    if (!mounted) return;
    setState(() {
      _event = event;
      _venue = venue;
      _loading = false;
    });
  }

  Future<void> _toggleSubscription() async {
    if (_venue == null) return;
    if (_subscribed) {
      await _eventService.unsubscribeFromVenue(_venue!.id);
      if (mounted) setState(() => _subscribed = false);
    } else {
      await _eventService.subscribeToVenue(_venue!.id);
      if (mounted) {
        setState(() {
          _subscribed = true;
          _showSubscriptionBanner = true;
        });
      }
      widget.onSubscriptionChanged?.call();
    }
  }

  Future<void> _toggleJoin() async {
    if (_event == null) return;
    if (_event!.isJoined) {
      await _eventService.leaveEvent(_event!.id);
    } else {
      await _eventService.joinEvent(_event!.id);
    }
    await _load();
    widget.onJoinChanged?.call();
  }

  void _openPhotoGrid() {
    if (_event == null || _event!.photoUrls.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => EventPhotoGridScreen(photoUrls: _event!.photoUrls),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF81262B))),
      );
    }
    final event = _event;
    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мероприятие')),
        body: const Center(child: Text('Мероприятие не найдено')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          event.title.length > 25 ? '${event.title.substring(0, 25)}...' : event.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined, color: Color(0xFF333333)), onPressed: () {}),
          IconButton(icon: const Icon(Icons.home_outlined, color: Color(0xFF333333)), onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: event.photoUrls.isNotEmpty ? _openPhotoGrid : null,
                  child: _buildBanner(event),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                      ),
                      if (event.dateTime != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _formatDateTime(event.dateTime!),
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                        ),
                      ],
                      if (event.venueName != null && event.venueName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(event.venueName!, style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
                            if (event.venueVerified) const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.check_circle, size: 18, color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                      if (event.description != null && event.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          event.description!,
                          style: TextStyle(fontSize: 14, height: 1.4, color: Colors.grey.shade800),
                        ),
                      ],
                      if (_venue != null) ...[
                        const SizedBox(height: 20),
                        _buildOrganizerCard(_venue!),
                      ],
                      if ((event.address != null && event.address!.isNotEmpty) || (event.city != null && event.city!.isNotEmpty)) ...[
                        const SizedBox(height: 16),
                        _buildLocationRow(event),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showSubscriptionBanner) _buildSubscriptionBanner(),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _event!.isJoined ? null : _toggleJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF81262B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_event!.isJoined ? 'Вы участвуете' : 'Присоединиться'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(EventItem event) {
    final url = event.imageUrl ?? (event.photoUrls.isNotEmpty ? event.photoUrls.first : null);
    return AspectRatio(
      aspectRatio: 1.4,
      child: url != null && url.isNotEmpty
          ? Image.network(url, fit: BoxFit.cover)
          : Container(color: Colors.grey.shade300, child: const Icon(Icons.event, size: 64)),
    );
  }

  String _formatDateTime(DateTime d) {
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    final m = d.month >= 1 && d.month <= 12 ? months[d.month - 1] : '';
    return '${d.day} $m ${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildOrganizerCard(VenueItem venue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: venue.photoUrl != null && venue.photoUrl!.isNotEmpty ? NetworkImage(venue.photoUrl!) : null,
            child: venue.photoUrl == null || venue.photoUrl!.isEmpty ? const Icon(Icons.store) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(venue.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    if (venue.verified) const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.check_circle, size: 18, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${venue.eventsCount} событий ${venue.subscribersCount} подписчиков',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _toggleSubscription,
            style: TextButton.styleFrom(
              backgroundColor: _subscribed ? Colors.grey.shade300 : const Color(0xFF333333),
              foregroundColor: _subscribed ? Colors.grey.shade700 : Colors.white,
            ),
            child: Text(_subscribed ? 'Отписаться' : 'Подписаться'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(EventItem event) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on_outlined, size: 22, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.city != null && event.city!.isNotEmpty) Text(event.city!, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (event.address != null && event.address!.isNotEmpty) Text(event.address!, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionBanner() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.green,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Expanded(child: Text('Подписка оформлена!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => setState(() => _showSubscriptionBanner = false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
