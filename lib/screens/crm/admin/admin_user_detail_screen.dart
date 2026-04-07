import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../firebase/firestore_schema.dart';
import '../../../services/admin_crm_service.dart';
import 'admin_user_edit_screen.dart';
import 'admin_user_posts_screen.dart';
import 'admin_user_chats_screen.dart';

class AdminUserDetailScreen extends StatelessWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

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
          'Профиль',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection(kUsersCollection).doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF81262B)));
          }
          final doc = snapshot.data;
          if (doc == null || !doc.exists || doc.data() == null) {
            return const Center(child: Text('Пользователь не найден'));
          }
          final d = doc.data()!;
          final name = d[kUserName]?.toString() ?? '—';
          final surname = d[kUserSurname]?.toString();
          final city = d[kUserCity]?.toString();
          final role = d[kUserRole]?.toString() ?? 'user';
          final verification = d[kUserVerificationStatus]?.toString() ?? 'none';
          final banned = d[kUserIsBanned] == true;
          final phone = d[kUserPhoneNumber]?.toString();
          final tg = d[kUserTelegramUserId]?.toString();
          final authProvider = d[kUserAuthProvider]?.toString();

          final photos = d[kUserPhotos];
          final photoUrl = photos is List && photos.isNotEmpty ? photos.first?.toString() : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                      child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            surname != null && surname.trim().isNotEmpty ? '$name $surname' : name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text('uid: $userId', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          if (city != null && city.trim().isNotEmpty)
                            Text(city, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    if (banned) const Icon(Icons.block, color: Colors.red),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _infoTile('Роль', role),
              _infoTile('Верификация', verification),
              _infoTile('Провайдер', authProvider ?? '—'),
              _infoTile('Телефон', phone ?? '—'),
              _infoTile('Telegram ID', tg ?? '—'),
              const SizedBox(height: 12),
              _navTile(
                context,
                title: 'Посты пользователя',
                subtitle: 'Просмотр и массовое удаление',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserPostsScreen(userId: userId))),
              ),
              _navTile(
                context,
                title: 'Чаты и сообщения',
                subtitle: 'Просмотр диалогов и переписки',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserChatsScreen(userId: userId))),
              ),
              const SizedBox(height: 12),
              _navTile(
                context,
                title: 'Редактировать (бан/роль/верификация)',
                onTap: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => AdminUserEditScreen(userId: userId, userData: d)),
                  );
                  if (updated == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сохранено'), backgroundColor: Colors.green));
                  }
                },
              ),
              const SizedBox(height: 24),
              _dangerZone(context, userId),
            ],
          );
        },
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value, style: TextStyle(color: Colors.grey.shade700)),
      ),
    );
  }

  Widget _navTile(BuildContext context, {required String title, String? subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _dangerZone(BuildContext context, String uid) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Опасные действия', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFB71C1C))),
          const SizedBox(height: 8),
          Text(
            'Жёсткое удаление (Auth) будет доступно после подключения Cloud Functions и blacklist.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Забанить пользователя?'),
                  content: const Text('Пользователь не сможет пользоваться приложением.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Забанить', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (ok == true) {
                await AdminCrmService().updateUserByAdmin(uid, {kUserIsBanned: true});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пользователь забанен'), backgroundColor: Colors.green));
                }
              }
            },
            child: const Text('Бан'),
          ),
        ],
      ),
    );
  }
}

