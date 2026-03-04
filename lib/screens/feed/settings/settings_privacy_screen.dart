import 'package:flutter/material.dart';
import '../../../firebase/firestore_schema.dart';
import '../../../services/auth/auth_service.dart';
import '../privacy_policy_screen.dart';

/// Приватность и безопасность: переключатели + ссылка на политику конфиденциальности.
class SettingsPrivacyScreen extends StatefulWidget {
  const SettingsPrivacyScreen({super.key});

  @override
  State<SettingsPrivacyScreen> createState() => _SettingsPrivacyScreenState();
}

class _SettingsPrivacyScreenState extends State<SettingsPrivacyScreen> {
  final AuthService _auth = AuthService();
  bool _visibilityForAll = true;
  bool _visibilityOnlyMatches = false;
  bool _visibilityOnlyEvents = false;
  bool _showLocation = true;
  bool _chatOnlyMatches = true;
  bool _allowGroupChats = true;
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
      final privacy = settings['privacy'];
      if (privacy is Map) {
        setState(() {
          _visibilityForAll = privacy['visibilityForAll'] ?? true;
          _visibilityOnlyMatches = privacy['visibilityOnlyMatches'] ?? false;
          _visibilityOnlyEvents = privacy['visibilityOnlyEvents'] ?? false;
          _showLocation = privacy['showLocation'] ?? true;
          _chatOnlyMatches = privacy['chatOnlyMatches'] ?? true;
          _allowGroupChats = privacy['allowGroupChats'] ?? true;
        });
      }
    }
    setState(() => _loaded = true);
  }

  Future<void> _save(Map<String, dynamic> privacy) async {
    final uid = _auth.currentUserId;
    if (uid == null) return;
    final profile = await _auth.getUserProfile(uid);
    final settings = Map<String, dynamic>.from(profile?[kUserSettings] is Map ? (profile![kUserSettings] as Map).map((k, v) => MapEntry(k.toString(), v)) : {});
    settings['privacy'] = privacy;
    await _auth.updateUserProfile(uid: uid, profileData: {kUserSettings: settings});
  }

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
          'Приватность и безопасность',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Видимость профиля', [
            _switch('Для всех', _visibilityForAll, (v) {
              setState(() => _visibilityForAll = v);
              _save(_buildPrivacy());
            }),
            _switch('Только совпадениям', _visibilityOnlyMatches, (v) {
              setState(() => _visibilityOnlyMatches = v);
              _save(_buildPrivacy());
            }),
            _switch('Только участникам мероприятий', _visibilityOnlyEvents, (v) {
              setState(() => _visibilityOnlyEvents = v);
              _save(_buildPrivacy());
            }),
          ]),
          _section('Геолокация', [
            _switch('Показывать местоположение', _showLocation, (v) {
              setState(() => _showLocation = v);
              _save(_buildPrivacy());
            }),
          ]),
          _section('Общение', [
            _switch('Общение только с мэтчами', _chatOnlyMatches, (v) {
              setState(() => _chatOnlyMatches = v);
              _save(_buildPrivacy());
            }),
            _switch('Разрешить групповые чаты', _allowGroupChats, (v) {
              setState(() => _allowGroupChats = v);
              _save(_buildPrivacy());
            }),
          ]),
          const SizedBox(height: 16),
          _section('', [
            ListTile(
              title: const Text('Политика конфиденциальности', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildPrivacy() => {
    'visibilityForAll': _visibilityForAll,
    'visibilityOnlyMatches': _visibilityOnlyMatches,
    'visibilityOnlyEvents': _visibilityOnlyEvents,
    'showLocation': _showLocation,
    'chatOnlyMatches': _chatOnlyMatches,
    'allowGroupChats': _allowGroupChats,
  };

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
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ...children,
        ],
      ),
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 15)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF81262B),
    );
  }
}
