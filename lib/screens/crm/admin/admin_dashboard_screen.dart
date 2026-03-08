import 'package:flutter/material.dart';
import 'admin_moderation_screen.dart';
import 'admin_users_screen.dart';
import 'admin_events_venues_screen.dart';

/// Дашборд админ-панели: модерация фото, управление профилями, мероприятия и места.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

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
          'Админ-панель',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Tile(
            icon: Icons.photo_library,
            title: 'Модерация фото и постов',
            subtitle: 'Одобрение и отклонение контента',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminModerationScreen())),
          ),
          _Tile(
            icon: Icons.people,
            title: 'Управление профилями',
            subtitle: 'Пользователи, верификация, роли, блокировка',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
          ),
          _Tile(
            icon: Icons.event,
            title: 'Мероприятия и места',
            subtitle: 'Список событий и организаторов',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEventsVenuesScreen())),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
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
