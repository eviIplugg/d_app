import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../firebase/firestore_schema.dart';
import '../../../services/admin_crm_service.dart';

/// Управление мероприятиями и местами проведения (список, удаление).
class AdminEventsVenuesScreen extends StatefulWidget {
  const AdminEventsVenuesScreen({super.key});

  @override
  State<AdminEventsVenuesScreen> createState() => _AdminEventsVenuesScreenState();
}

class _AdminEventsVenuesScreenState extends State<AdminEventsVenuesScreen> with SingleTickerProviderStateMixin {
  final AdminCrmService _crm = AdminCrmService();
  late TabController _tabController;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _events = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _venues = [];
  bool _loadingEvents = true;
  bool _loadingVenues = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
    _loadVenues();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _loadingEvents = true);
    final snap = await _crm.getEvents(limit: 100);
    if (!mounted) return;
    setState(() {
      _events = snap.docs;
      _loadingEvents = false;
    });
  }

  Future<void> _loadVenues() async {
    setState(() => _loadingVenues = true);
    final snap = await _crm.getVenues(limit: 100);
    if (!mounted) return;
    setState(() {
      _venues = snap.docs;
      _loadingVenues = false;
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
        title: const Text('Мероприятия и места', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF81262B),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Мероприятия'),
            Tab(text: 'Места'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _loadingEvents
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF81262B)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final doc = _events[index];
                    final d = doc.data();
                    final title = d[kEventTitle]?.toString() ?? '—';
                    final venueName = d[kEventVenueName]?.toString();
                    return _ListTileAdmin(
                      title: title,
                      subtitle: venueName,
                      onDelete: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Удалить мероприятие?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await _crm.deleteEvent(doc.id);
                          _loadEvents();
                        }
                      },
                    );
                  },
                ),
          _loadingVenues
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF81262B)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _venues.length,
                  itemBuilder: (context, index) {
                    final doc = _venues[index];
                    final d = doc.data();
                    final name = d[kVenueName]?.toString() ?? '—';
                    final city = d[kVenueCity]?.toString();
                    return _ListTileAdmin(
                      title: name,
                      subtitle: city,
                      onDelete: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Удалить место?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await _crm.deleteVenue(doc.id);
                          _loadVenues();
                        }
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }
}

class _ListTileAdmin extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onDelete;

  const _ListTileAdmin({required this.title, this.subtitle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
