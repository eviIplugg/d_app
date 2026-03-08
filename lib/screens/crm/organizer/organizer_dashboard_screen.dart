import 'package:flutter/material.dart';
import '../../../services/organizer_crm_service.dart';
import 'organizer_venue_screen.dart';
import 'organizer_events_screen.dart';

/// Дашборд организатора: моё место, мои мероприятия.
class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() => _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  final OrganizerCrmService _crm = OrganizerCrmService();
  List<Map<String, dynamic>> _venues = [];
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final venues = await _crm.getMyVenues();
    final events = await _crm.getMyEvents(limit: 20);
    if (!mounted) return;
    setState(() {
      _venues = venues;
      _events = events;
      _loading = false;
    });
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CRM организатора',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF81262B)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Tile(
                    icon: Icons.store,
                    title: 'Моё место проведения',
                    subtitle: _venues.isEmpty ? 'Добавить место' : _venues.first['name']?.toString() ?? '—',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrganizerVenueScreen(
                            venueId: _venues.isNotEmpty ? _venues.first['id'] as String? : null,
                            venueData: _venues.isNotEmpty ? _venues.first : null,
                          ),
                        ),
                      );
                      _load();
                    },
                  ),
                  _Tile(
                    icon: Icons.event,
                    title: 'Мои мероприятия',
                    subtitle: '${_events.length} мероприятий',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrganizerEventsScreen()),
                      );
                      _load();
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF81262B).withValues(alpha: 0.15),
          child: Icon(icon, color: const Color(0xFF81262B)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
