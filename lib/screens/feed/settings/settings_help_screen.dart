import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Помощь и поддержка: написать в Telegram, отправить Email.
class SettingsHelpScreen extends StatelessWidget {
  const SettingsHelpScreen({super.key});

  static const String telegramSupport = 'https://t.me/support';
  static const String emailSupport = 'mailto:support@example.com';

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
          'Помощь и поддержка',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            context,
            'Написать в Telegram',
            Icons.send,
            () => launchUrl(Uri.parse(telegramSupport), mode: LaunchMode.externalApplication),
          ),
          _tile(
            context,
            'Отправить Email',
            Icons.email_outlined,
            () => launchUrl(Uri.parse(emailSupport), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF81262B)),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
