import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../firebase/firestore_schema.dart';
import '../../../services/organizer_crm_service.dart';
import 'organizer_event_edit_screen.dart';

/// Список мероприятий организатора, создание и редактирование.
class OrganizerEventsScreen extends StatefulWidget {
  const OrganizerEventsScreen({super.key});

  @override
  State<OrganizerEventsScreen> createState() => _OrganizerEventsScreenState();
}

class _OrganizerEventsScreenState extends State<OrganizerEventsScreen> {
  final OrganizerCrmService _crm = OrganizerCrmService();
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _venues = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final venues = await _crm.getMyVenues();
    final events = await _crm.getMyEvents(limit: 100);
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
        title: const Text('Мои мероприятия', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
        actions: [
          if (_venues.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF333333)),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrganizerEventEditScreen(
                      venues: _venues,
                      eventId: null,
                      eventData: null,
                    ),
                  ),
                );
                _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF81262B)))
          : _venues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('Сначала добавьте место проведения', textAlign: TextAlign.center),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final e = _events[index];
                      final title = e[kEventTitle]?.toString() ?? '—';
                      final dt = e[kEventDateTime];
                      DateTime? dateTime;
                      if (dt is Timestamp) dateTime = dt.toDate();
                      final dateStr = dateTime != null ? '${dateTime.day}.${dateTime.month}.${dateTime.year}' : '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: ListTile(
                          title: Text(title),
                          subtitle: Text(dateStr),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrganizerEventEditScreen(
                                        venues: _venues,
                                        eventId: e['id'] as String?,
                                        eventData: e,
                                      ),
                                    ),
                                  );
                                  _load();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () async {
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
                                  if (ok == true && e['id'] != null) {
                                    await _crm.deleteEvent(e['id'] as String);
                                    _load();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
