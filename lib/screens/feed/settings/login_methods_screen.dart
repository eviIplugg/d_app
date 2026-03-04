import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../firebase/firestore_schema.dart';

/// Способы входа: привязанные аккаунты (VK, Apple, Google).
class LoginMethodsScreen extends StatelessWidget {
  const LoginMethodsScreen({super.key});

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
          'Способы входа',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: AuthService().currentUserId != null ? AuthService().getUserProfile(AuthService().currentUserId!) : null,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final provider = profile?[kUserAuthProvider]?.toString() ?? '';
          String vkLabel = 'Нет данных';
          if (provider == 'vk' || provider.contains('vk')) vkLabel = profile?[kUserName]?.toString() ?? 'Подключено';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _tile('Вконтакте', Icons.link, vkLabel),
              _tile('Apple', Icons.apple, 'Нет данных'),
              _tile('Google', Icons.g_mobiledata, 'Нет данных'),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(String title, IconData icon, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF81262B)),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
