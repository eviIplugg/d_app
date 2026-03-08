import 'package:flutter/material.dart';
import '../../models/event_item.dart';
import '../../services/event_service.dart';
import 'widgets/event_card.dart';
import 'event_detail_screen.dart';

/// Пустое состояние ленты: лупа, «Пока нет событий рядом», подсказка.
class FeedEventsEmptyState extends StatelessWidget {
  const FeedEventsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 120, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              'Пока нет событий рядом',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 12),
            Text(
              'Посмотрите популярные или подпишитесь на бизнесы!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Одна секция с заголовком, «Все» и горизонтальным списком карточек.
class _EventSection extends StatelessWidget {
  const _EventSection({
    required this.title,
    required this.events,
    required this.onSeeAll,
    required this.onEventTap,
  });

  final String title;
  final List<EventItem> events;
  final VoidCallback onSeeAll;
  final void Function(EventItem) onEventTap;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
              TextButton(
                onPressed: onSeeAll,
                child: const Text('Все', style: TextStyle(color: Color(0xFF81262B), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 180,
                  child: EventCard(
                    event: event,
                    compact: true,
                    onTap: () => onEventTap(event),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Тело ленты мероприятий: вкладки Мероприятия / Места проведения, поиск, фильтр, баннер, секции.
class FeedEventsBody extends StatefulWidget {
  const FeedEventsBody({
    super.key,
    this.tabIndex = 0,
    this.searchQuery = '',
  });

  final int tabIndex;
  final String searchQuery;

  @override
  State<FeedEventsBody> createState() => _FeedEventsBodyState();
}

class _FeedEventsBodyState extends State<FeedEventsBody> {
  final EventService _eventService = EventService();
  bool _loading = true;
  List<EventItem> _mySchedule = [];
  List<EventItem> _nearby = [];
  List<EventItem> _popular = [];
  EventItem? _featured;
  List<VenueItem> _venues = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final my = await _eventService.getMyScheduleEvents(limit: 10);
      final near = await _eventService.getNearbyEvents(limit: 15);
      final pop = await _eventService.getPopularEvents(limit: 15);
      final v = await _eventService.getVenues(limit: 20);
      if (!mounted) return;
      setState(() {
        _mySchedule = my;
        _nearby = near;
        _popular = pop;
        _featured = near.isNotEmpty ? near.first : (pop.isNotEmpty ? pop.first : null);
        _venues = v;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onEventTap(EventItem event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => EventDetailScreen(
          eventId: event.id,
          onSubscriptionChanged: _load,
          onJoinChanged: _load,
        ),
      ),
    );
  }

  void _onSeeAllNearby() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => _AllEventsScreen(
          title: 'Рядом с вами',
          events: _nearby,
          onEventTap: _onEventTap,
        ),
      ),
    );
  }

  void _onSeeAllSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => _AllEventsScreen(
          title: 'Ваше расписание',
          events: _mySchedule,
          onEventTap: _onEventTap,
        ),
      ),
    );
  }

  void _onSeeAllPopular() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => _AllEventsScreen(
          title: 'Популярно на этой неделе',
          events: _popular,
          onEventTap: _onEventTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF81262B)));
    }

    if (widget.tabIndex == 1) {
      return _buildVenuesTab();
    }
    final hasAnyEvents = _mySchedule.isNotEmpty || _nearby.isNotEmpty || _popular.isNotEmpty;
    if (!hasAnyEvents) {
      return const FeedEventsEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF81262B),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_featured != null) _buildFeaturedBanner(_featured!),
            _EventSection(
              title: 'Ваше расписание',
              events: _mySchedule,
              onSeeAll: _onSeeAllSchedule,
              onEventTap: _onEventTap,
            ),
            _EventSection(
              title: 'Рядом с вами',
              events: _nearby,
              onSeeAll: _onSeeAllNearby,
              onEventTap: _onEventTap,
            ),
            _EventSection(
              title: 'Популярно на этой неделе',
              events: _popular,
              onSeeAll: _onSeeAllPopular,
              onEventTap: _onEventTap,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedBanner(EventItem event) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: () => _onEventTap(event),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.6,
                child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                    ? Image.network(event.imageUrl!, fit: BoxFit.cover)
                    : Container(color: Colors.grey.shade300, child: const Icon(Icons.event, size: 64)),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.dateTimeLabel} ${event.venueName ?? ''}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      if (event.price != null && event.price!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF81262B), width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.price!.toLowerCase().contains('от') ? event.price! : 'от ${event.price}',
                            style: const TextStyle(color: Color(0xFF81262B), fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVenuesTab() {
    if (_venues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.place_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Пока нет мест проведения', style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _venues.length,
      itemBuilder: (context, index) {
        final v = _venues[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: v.photoUrl != null && v.photoUrl!.isNotEmpty ? NetworkImage(v.photoUrl!) : null,
              child: v.photoUrl == null || v.photoUrl!.isEmpty ? const Icon(Icons.store) : null,
            ),
            title: Row(
              children: [
                Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (v.verified) const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.check_circle, size: 18, color: Colors.green),
                ),
              ],
            ),
            subtitle: Text('${v.eventsCount} событий · ${v.subscribersCount} подписчиков'),
          ),
        );
      },
    );
  }
}

class _AllEventsScreen extends StatelessWidget {
  const _AllEventsScreen({
    required this.title,
    required this.events,
    required this.onEventTap,
  });

  final String title;
  final List<EventItem> events;
  final void Function(EventItem) onEventTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
      ),
      body: events.isEmpty
          ? const Center(child: Text('Нет мероприятий'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: EventCard(event: event, onTap: () => onEventTap(event)),
                );
              },
            ),
    );
  }
}
