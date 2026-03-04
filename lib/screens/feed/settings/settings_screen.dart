import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../firebase/firestore_schema.dart';
import '../../../services/auth/auth_service.dart';
import '../../welcome/welcome_screen.dart';
import 'settings_privacy_screen.dart';
import 'settings_notifications_screen.dart';
import 'settings_help_screen.dart';
import 'login_methods_screen.dart';

/// Настройки: основное (имя, дата рождения, пол, способы входа), приложение (приватность, уведомления, помощь, о приложении), выход.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUserId;
    if (uid == null) {
      return;
    }
    final profile = await _auth.getUserProfile(uid);
    if (mounted) {
      setState(() => _profile = profile);
    }
  }

  String _name() => _profile?[kUserName]?.toString() ?? '—';
  String _birthdate() {
    final b = _profile?[kUserBirthdate];
    if (b == null) return '—';
    DateTime? d;
    if (b is Timestamp) d = b.toDate();
    else if (b is DateTime) d = b;
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')} ${_monthName(d.month)} ${d.year}';
  }
  String _monthName(int m) {
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return months[m - 1];
  }
  String _gender() {
    final g = _profile?[kUserGender]?.toString();
    if (g == 'male') return 'Мужчина';
    if (g == 'female') return 'Женщина';
    if (g == 'other') return 'Другое';
    return '—';
  }
  String _preference() {
    final p = _profile?[kUserPreference]?.toString();
    if (p == 'men') return 'Мужчин';
    if (p == 'women') return 'Женщин';
    if (p == 'everyone') return 'Всех';
    return '—';
  }
  String _relationshipGoal() {
    final g = _profile?[kUserRelationshipGoal]?.toString();
    if (g == 'friendship') return 'Дружба';
    if (g == 'communication') return 'Общение';
    if (g == 'relationship') return 'Отношения';
    return '—';
  }
  String _city() => _profile?[kUserCity]?.toString() ?? '—';
  String _bio() => _profile?[kUserBio]?.toString() ?? '—';
  String _job() => _profile?[kUserJob]?.toString() ?? '—';
  String _education() => _profile?[kUserEducation]?.toString() ?? '—';

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
          'Настройки',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Основное'),
          _tile('Имя', _name()),
          _tile('Дата рождения', _birthdate()),
          _tile('Пол', _gender()),
          _tile('Город', _city()),
          _tile('Кого ищу', _preference()),
          _tile('Цель знакомства', _relationshipGoal()),
          _tile('О себе', _bio().isEmpty || _bio() == '—' ? '—' : _bio()),
          _tile('Работа', _job()),
          _tile('Образование', _education()),
          _tileWithNav('Способы входа', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginMethodsScreen()))),
          const SizedBox(height: 24),
          _sectionTitle('Приложение'),
          _tileWithNav('Приватность и безопасность', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPrivacyScreen()))),
          _tileWithNav('Уведомления', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsNotificationsScreen()))),
          _tileWithNav('Помощь и поддержка', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsHelpScreen()))),
          _tileWithNav('О приложении', subtitle: 'Версия 1.0.0'),
          const SizedBox(height: 24),
          _logoutTile(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _tile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        subtitle: value != '—' ? Text(value, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)) : null,
      ),
    );
  }

  Widget _tileWithNav(String title, {String? subtitle, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)) : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap ?? () {},
      ),
    );
  }

  Widget _logoutTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: const Text('Выйти', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFB71C1C))),
        onTap: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Выйти?'),
              content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Выйти', style: TextStyle(color: Color(0xFFB71C1C)))),
              ],
            ),
          );
          if (ok == true && mounted) {
            await _auth.signOut();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}
