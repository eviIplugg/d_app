import 'package:flutter/material.dart';
import '../../models/event_item.dart';
import '../../models/place_item.dart';
import '../../firebase/firestore_schema.dart';
import '../../services/auth/auth_service.dart';
import '../../services/event_service.dart';
import '../../services/location_service.dart';
import '../../services/yandex_places_service.dart';
import 'widgets/event_card.dart';
import 'widgets/place_catalog_cover.dart';
import 'event_detail_screen.dart';
import 'place_detail_screen.dart';

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
  final YandexPlacesService _placesService = YandexPlacesService();
  final AuthService _auth = AuthService();
  bool _loading = true;
  String? _error;
  List<EventItem> _mySchedule = [];
  List<EventItem> _nearby = [];
  List<EventItem> _popular = [];
  EventItem? _featured;
  Future<List<PlaceItem>>? _placesFuture;
  String _lastPlacesQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.tabIndex == 1) {
      _placesFuture = _loadPlaces(query: widget.searchQuery);
      _lastPlacesQuery = widget.searchQuery;
    }
  }

  @override
  void didUpdateWidget(covariant FeedEventsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabIndex == 1 && (oldWidget.tabIndex != 1 || oldWidget.searchQuery != widget.searchQuery)) {
      if (_lastPlacesQuery != widget.searchQuery) {
        _placesFuture = _loadPlaces(query: widget.searchQuery);
        _lastPlacesQuery = widget.searchQuery;
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final my = await _eventService.getMyScheduleEvents(limit: 10);
      final near = await _eventService.getNearbyEvents(limit: 15);
      final pop = await _eventService.getPopularEvents(limit: 15);
      if (!mounted) return;
      setState(() {
        _mySchedule = my;
        _nearby = near;
        _popular = pop;
        _featured = near.isNotEmpty ? near.first : (pop.isNotEmpty ? pop.first : null);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<List<PlaceItem>> _loadPlaces({required String query}) async {
    final uid = _auth.currentUserId;
    double? lat;
    double? lng;
    if (uid != null) {
      final profile = await _auth.getUserProfile(uid, forceRefresh: false);
      final glat = profile?[kUserGeoLat];
      final glng = profile?[kUserGeoLng];
      if (glat is num) lat = glat.toDouble();
      if (glng is num) lng = glng.toDouble();
    }
    if (lat == null || lng == null) {
      final loc = await LocationService.getCurrentLocation();
      lat = loc.lat;
      lng = loc.lng;
      if (uid != null) {
        await _auth.updateUserProfile(uid: uid, profileData: {
          kUserGeoLat: lat,
          kUserGeoLng: lng,
          kUserGeoUpdatedAt: DateTime.now(),
        });
      }
    }
    return _placesService.searchNearby(lat: lat, lng: lng, query: query);
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
                'Не удалось загрузить активности',
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
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF81262B)),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.tabIndex == 1) {
      return _buildPlacesTab();
    }
    if (widget.searchQuery.trim().isNotEmpty) {
      return _buildSearchResults(widget.searchQuery.trim());
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

  Widget _buildSearchResults(String query) {
    return FutureBuilder<List<EventItem>>(
      future: _eventService.searchEvents(query, limit: 40),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF81262B)));
        }
        if (snap.hasError) {
          return Center(child: Text('Ошибка поиска: ${snap.error}', textAlign: TextAlign.center));
        }
        final list = snap.data ?? const <EventItem>[];
        if (list.isEmpty) {
          return Center(child: Text('Ничего не найдено', style: TextStyle(color: Colors.grey.shade700)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final e = list[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EventCard(event: e, compact: false, onTap: () => _onEventTap(e)),
            );
          },
        );
      },
    );
  }

  Widget _buildPlacesTab() {
    final fut = _placesFuture ??= _loadPlaces(query: widget.searchQuery);
    return FutureBuilder<List<PlaceItem>>(
      future: fut,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF81262B)));
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.place_outlined, size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 14),
                  Text(
                    'Не удалось загрузить места рядом',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snap.error.toString(),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => setState(() => _placesFuture = _loadPlaces(query: widget.searchQuery)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF81262B)),
                  ),
                ],
              ),
            ),
          );
        }
        final list = snap.data ?? const <PlaceItem>[];
        if (list.isEmpty) {
          return Center(
            child: Text('Пока ничего не найдено', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          );
        }

        void openPlace(PlaceItem p) {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => PlaceDetailScreen(place: p)),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF81262B),
          onRefresh: () async {
            setState(() => _placesFuture = _loadPlaces(query: widget.searchQuery));
            await _placesFuture;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _PlaceHeroCard(place: list.first, onTap: () => openPlace(list.first)),
                ),
              ),
              if (list.length > 1)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.74,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final p = list[index + 1];
                        return _PlaceGridTile(place: p, onTap: () => openPlace(p));
                      },
                      childCount: list.length - 1,
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
          ),
        );
      },
    );
  }
}

/// Крупная карточка «герой» — как на макете ленты мест.
class _PlaceHeroCard extends StatelessWidget {
  const _PlaceHeroCard({required this.place, required this.onTap});

  final PlaceItem place;
  final VoidCallback onTap;

  static const Color _tagGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 1.05,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PlaceCatalogCover(imageUrl: place.displayCoverImageUrl, fit: BoxFit.cover, iconSize: 64),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0.15), Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                      stops: const [0, 0.5, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (place.categories.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _tagGreen.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            place.categories.first,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (place.rating != null) ...[
                            const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 20),
                            const SizedBox(width: 4),
                            Text(
                              place.rating!.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ],
                          if (place.rating != null && place.distanceLabel.isNotEmpty) const SizedBox(width: 12),
                          if (place.distanceLabel.isNotEmpty)
                            Text(place.distanceLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Плитка в сетке 2 колонки.
class _PlaceGridTile extends StatelessWidget {
  const _PlaceGridTile({required this.place, required this.onTap});

  final PlaceItem place;
  final VoidCallback onTap;

  static const Color _tagGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PlaceCatalogCover(imageUrl: place.displayCoverImageUrl, fit: BoxFit.cover, iconSize: 44),
                  if (place.categories.isNotEmpty)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _tagGreen.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          place.categories.first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.2, color: Color(0xFF333333)),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (place.rating != null) ...[
                          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB300)),
                          const SizedBox(width: 2),
                          Text(place.rating!.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                        if (place.rating != null && place.distanceLabel.isNotEmpty) const SizedBox(width: 8),
                        if (place.distanceLabel.isNotEmpty)
                          Expanded(
                            child: Text(
                              place.distanceLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
