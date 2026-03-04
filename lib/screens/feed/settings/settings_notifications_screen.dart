import 'package:flutter/material.dart';
import '../../../firebase/firestore_schema.dart';
import '../../../services/auth/auth_service.dart';

/// Уведомления: переключатели по категориям (чаты, события, места). Сохранение в Firebase.
class SettingsNotificationsScreen extends StatefulWidget {
  const SettingsNotificationsScreen({super.key});

  @override
  State<SettingsNotificationsScreen> createState() => _SettingsNotificationsScreenState();
}

class _SettingsNotificationsScreenState extends State<SettingsNotificationsScreen> {
  final AuthService _auth = AuthService();
  bool _privateMessages = true;
  bool _groupChats = true;
  bool _reminders = true;
  bool _fromMatches = true;
  bool _newEventsByInterest = true;
  bool _changesInEvents = true;
  bool _newLocations = true;
  bool _partnerPromo = true;
  bool _updatesPlacesBeen = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _auth.currentUserId;
    if (uid == null) {
      setState(() => _loaded = true);
      return;
    }
    final profile = await _auth.getUserProfile(uid);
    final settings = profile?[kUserSettings];
    if (settings is Map) {
      final notif = settings['notifications'];
      if (notif is Map) {
        setState(() {
          _privateMessages = notif['privateMessages'] ?? true;
          _groupChats = notif['groupChats'] ?? true;
          _reminders = notif['reminders'] ?? true;
          _fromMatches = notif['fromMatches'] ?? true;
          _newEventsByInterest = notif['newEventsByInterest'] ?? true;
          _changesInEvents = notif['changesInEvents'] ?? true;
          _newLocations = notif['newLocations'] ?? true;
          _partnerPromo = notif['partnerPromo'] ?? true;
          _updatesPlacesBeen = notif['updatesPlacesBeen'] ?? true;
        });
      }
    }
    setState(() => _loaded = true);
  }

  Future<void> _save(Map<String, dynamic> notif) async {
    final uid = _auth.currentUserId;
    if (uid == null) return;
    final profile = await _auth.getUserProfile(uid);
    final settings = Map<String, dynamic>.from(profile?[kUserSettings] is Map ? (profile![kUserSettings] as Map).map((k, v) => MapEntry(k.toString(), v)) : {});
    settings['notifications'] = notif;
    await _auth.updateUserProfile(uid: uid, profileData: {kUserSettings: settings});
  }

  Map<String, dynamic> _buildNotif() => {
    'privateMessages': _privateMessages,
    'groupChats': _groupChats,
    'reminders': _reminders,
    'fromMatches': _fromMatches,
    'newEventsByInterest': _newEventsByInterest,
    'changesInEvents': _changesInEvents,
    'newLocations': _newLocations,
    'partnerPromo': _partnerPromo,
    'updatesPlacesBeen': _updatesPlacesBeen,
  };

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
          'Уведомления',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Чаты', [
            _switch('Личные сообщения', _privateMessages, (v) { setState(() => _privateMessages = v); _save(_buildNotif()); }),
            _switch('Групповые чаты', _groupChats, (v) { setState(() => _groupChats = v); _save(_buildNotif()); }),
          ]),
          _section('События', [
            _switch('Напоминания', _reminders, (v) { setState(() => _reminders = v); _save(_buildNotif()); }, subtitle: 'За 1 день и за 2 ч. до начала'),
            _switch('От совпадений', _fromMatches, (v) { setState(() => _fromMatches = v); _save(_buildNotif()); }),
            _switch('Новые события по интересам', _newEventsByInterest, (v) { setState(() => _newEventsByInterest = v); _save(_buildNotif()); }),
            _switch('Изменения в событиях', _changesInEvents, (v) { setState(() => _changesInEvents = v); _save(_buildNotif()); }),
          ]),
          _section('Места', [
            _switch('Новые локации и предложения', _newLocations, (v) { setState(() => _newLocations = v); _save(_buildNotif()); }),
            _switch('Акции партнёров', _partnerPromo, (v) { setState(() => _partnerPromo = v); _save(_buildNotif()); }),
            _switch('Обновления мест, где вы были', _updatesPlacesBeen, (v) { setState(() => _updatesPlacesBeen = v); _save(_buildNotif()); }),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged, {String? subtitle}) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)) : null,
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF81262B),
    );
  }
}
