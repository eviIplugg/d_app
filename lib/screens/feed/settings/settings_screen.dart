import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../firebase/firestore_schema.dart';
import '../../../services/auth/auth_service.dart';
import '../../../utils/education_levels.dart';
import '../../welcome/welcome_screen.dart';
import '../edit_profile_screen.dart';
import 'settings_privacy_screen.dart';
import 'settings_notifications_screen.dart';
import 'settings_help_screen.dart';
import 'login_methods_screen.dart';
import '../../crm/admin/admin_dashboard_screen.dart';
import '../../crm/organizer/organizer_dashboard_screen.dart';

/// Настройки: основное (имя, дата рождения, пол, способы входа), приложение (приватность, уведомления, помощь, о приложении), выход.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();
  Map<String, dynamic>? _profile;
  bool _isAdmin = false;
  bool _isOrganizer = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    final admin = await _auth.isAdmin();
    final org = await _auth.isOrganizer();
    if (mounted) setState(() {
      _isAdmin = admin;
      _isOrganizer = org;
    });
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

  void _openEditProfile() async {
    final updated = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    if (updated == true && mounted) _loadProfile();
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
  String _surname() => _profile?[kUserSurname]?.toString() ?? '—';
  String _city() => _profile?[kUserCity]?.toString() ?? '—';
  String _bio() => _profile?[kUserBio]?.toString() ?? '—';
  String _job() => _profile?[kUserJob]?.toString() ?? '—';
  String _educationLevel() {
    final key = _profile?[kUserEducationLevel]?.toString();
    if (key == null || key.isEmpty) return '—';
    return educationLevelLabel(key) ?? key;
  }
  String _university() => _profile?[kUserUniversity]?.toString() ?? '—';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Основное'),
          _tileWithNav('Имя', subtitle: _name(), onTap: _openEditProfile),
          _tileWithNav('Фамилия', subtitle: _surname(), onTap: _openEditProfile),
          _tileWithNav('Дата рождения', subtitle: _birthdate(), onTap: _openEditProfile),
          _tileWithNav('Пол', subtitle: _gender(), onTap: _openEditProfile),
          _tileWithNav('Город', subtitle: _city(), onTap: _openEditProfile),
          _tileWithNav('Кого ищу', subtitle: _preference(), onTap: _openEditProfile),
          _tileWithNav('Цель знакомства', subtitle: _relationshipGoal(), onTap: _openEditProfile),
          _tileWithNav('О себе', subtitle: _bio().isEmpty || _bio() == '—' ? '—' : _bio(), onTap: _openEditProfile),
          _tileWithNav('Работа', subtitle: _job(), onTap: _openEditProfile),
          _tileWithNav('Уровень образования', subtitle: _educationLevel(), onTap: _openEditProfile),
          _tileWithNav('Вуз', subtitle: _university(), onTap: _openEditProfile),
          _tileWithNav('Способы входа', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginMethodsScreen()))),
          const SizedBox(height: 24),
          _sectionTitle('Приложение'),
          _tileWithNav('Приватность и безопасность', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPrivacyScreen()))),
          _tileWithNav('Уведомления', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsNotificationsScreen()))),
          _tileWithNav('Помощь и поддержка', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsHelpScreen()))),
          _tileWithNav('О приложении', subtitle: 'Версия 1.0.0'),
          if (_isAdmin)
            _tileWithNav('Админ-панель', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()))),
          if (_isOrganizer)
            _tileWithNav('CRM организатора', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizerDashboardScreen()))),
          const SizedBox(height: 24),
          _logoutTile(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _tileWithNav(String title, {String? subtitle, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final hasSubtitle = subtitle != null && subtitle != '—';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title, style: theme.textTheme.bodyLarge),
        subtitle: hasSubtitle ? Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)) : null,
        trailing: onTap != null ? Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant) : null,
        onTap: onTap,
      ),
    );
  }


  Widget _logoutTile() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text('Выйти', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.error)),
        onTap: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Выйти?'),
              content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Выйти', style: TextStyle(color: theme.colorScheme.error))),
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
