import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase/firestore_schema.dart';
import '../../services/auth/auth_service.dart';
import 'settings/settings_screen.dart';
import 'edit_profile_screen.dart';
import '../crm/admin/admin_dashboard_screen.dart';
import '../crm/organizer/organizer_dashboard_screen.dart';

/// Личный кабинет: профиль зарегистрированного пользователя, меню, переход в настройки.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  Map<String, dynamic>? _profile;
  bool _loading = true;
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
      setState(() => _loading = false);
      return;
    }
    final profile = await _auth.getUserProfile(uid);
    if (mounted) setState(() {
      _profile = profile;
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
        title: const Text(
          'Профиль',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.grey.shade700),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
              );
              _loadProfile();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Войдите в аккаунт', style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 16),
                      _buildProfileDataCard(),
                      const SizedBox(height: 24),
                      _menuTile('Культурный профиль', Icons.face, onTap: () {}),
                      _menuTile('Мои истории', Icons.auto_stories, trailing: '0', onTap: () {}),
                      _menuTile('Чекины', Icons.location_on_outlined, trailing: '0', onTap: () {}),
                      _menuTile('Премиум', Icons.star_outline, onTap: () {}),
                      _menuTile('История активности', Icons.history, onTap: () {}),
                      if (_isAdmin)
                        _menuTile('Админ-панель', Icons.admin_panel_settings, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                        }),
                      if (_isOrganizer)
                        _menuTile('CRM организатора', Icons.store, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizerDashboardScreen()));
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _profile![kUserName]?.toString() ?? 'Пользователь';
    final city = _profile![kUserCity]?.toString();
    final photos = _profile![kUserPhotos];
    final photoUrl = photos is List && photos.isNotEmpty ? photos.first?.toString() : null;
    final verified = _profile![kUserVerificationStatus]?.toString() == 'verified';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          final updated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (ctx) => const EditProfileScreen()),
          );
          if (updated == true) _loadProfile();
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl == null || photoUrl.isEmpty
                ? const Icon(Icons.person, size: 40, color: Colors.white70)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: Color(0xFF81262B), size: 22),
                    ],
                    const Spacer(),
                    Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade600),
                  ],
                ),
                if (city != null && city.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    city,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  String _formatBirthdate() {
    final b = _profile![kUserBirthdate];
    if (b == null) return '—';
    DateTime? d;
    if (b is Timestamp) d = b.toDate();
    else if (b is DateTime) d = b;
    if (d == null) return '—';
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  String _genderLabel() {
    final g = _profile![kUserGender]?.toString();
    if (g == 'male') return 'Мужской';
    if (g == 'female') return 'Женский';
    if (g == 'other') return 'Другое';
    return '—';
  }

  String _preferenceLabel() {
    final p = _profile![kUserPreference]?.toString();
    if (p == 'men') return 'Мужчин';
    if (p == 'women') return 'Женщин';
    if (p == 'everyone') return 'Всех';
    return '—';
  }

  String _goalLabel() {
    final g = _profile![kUserRelationshipGoal]?.toString();
    if (g == 'friendship') return 'Дружба';
    if (g == 'communication') return 'Общение';
    if (g == 'relationship') return 'Отношения';
    return '—';
  }

  Widget _buildProfileDataCard() {
    final city = _profile![kUserCity]?.toString();
    final bio = _profile![kUserBio]?.toString();
    final job = _profile![kUserJob]?.toString();
    final education = _profile![kUserEducation]?.toString();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dataRow('Дата рождения', _formatBirthdate()),
          _dataRow('Пол', _genderLabel()),
          _dataRow('Город', city ?? '—'),
          _dataRow('Кого ищу', _preferenceLabel()),
          _dataRow('Цель знакомства', _goalLabel()),
          _dataRow('Работа', job ?? '—'),
          _dataRow('Образование', education ?? '—'),
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('О себе', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
            const SizedBox(height: 4),
            Text(bio, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4)),
          ],
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600))),
          Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 14, color: Color(0xFF333333)))),
        ],
      ),
    );
  }

  Widget _menuTile(String title, IconData icon, {String? trailing, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF81262B), size: 24),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) Text(trailing, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
