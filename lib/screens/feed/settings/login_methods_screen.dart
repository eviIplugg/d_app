import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/telegram_config.dart';
import '../../../firebase/firestore_schema.dart';
import '../../../services/auth/auth_service.dart';
import '../../auth/telegram_login_webview_screen.dart';

/// Способы входа: привязка Telegram (как при основном входе), статус VK и др.
class LoginMethodsScreen extends StatefulWidget {
  const LoginMethodsScreen({super.key});

  @override
  State<LoginMethodsScreen> createState() => _LoginMethodsScreenState();
}

class _LoginMethodsScreenState extends State<LoginMethodsScreen> {
  final AuthService _auth = AuthService();

  Future<void> _openTelegramLink() async {
    if (!isTelegramConfigured) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Настройте telegramBotUsername и telegramBotDomain в lib/config/telegram_config.dart',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // На web редирект/коллбэки лучше работают через отдельный hosting (auth-ringme.web.app),
    // поэтому открываем страницу в браузере без WebView.
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Открываем Telegram авторизацию...'), backgroundColor: Colors.blueGrey),
        );
      }

      final url = telegramBotDomain.trim();
      final uri = url.startsWith('http://') || url.startsWith('https://') ? Uri.parse(url) : Uri.parse('https://$url');
      // Важно: не делаем `await`, чтобы браузер считал это реакцией на клик.
      try {
        launchUrl(uri, mode: LaunchMode.externalApplication).then((ok) {
          if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Не удалось открыть Telegram. Возможно блокируется всплывающее окно.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }).catchError((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка открытия Telegram.'), backgroundColor: Colors.red),
          );
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка открытия Telegram: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TelegramLoginWebViewScreen(linkOnly: true)),
    );
    if (ok == true && mounted) setState(() {});
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
        title: const Text(
          'Способы входа',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _auth.currentUserId != null ? _auth.getUserProfile(_auth.currentUserId!) : Future.value(null),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final provider = profile?[kUserAuthProvider]?.toString() ?? '';
          String vkLabel = 'Не подключено';
          if (provider == 'vk' || provider.contains('vk')) {
            vkLabel = profile?[kUserName]?.toString() ?? 'Подключено';
          }
          final tgId = profile?[kUserTelegramUserId]?.toString();
          final tgLabel = (tgId != null && tgId.isNotEmpty) ? 'Привязан (ID: $tgId)' : 'Не привязан';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _tile(
                title: 'Telegram',
                icon: Icons.telegram,
                subtitle: tgLabel,
                onTap: _openTelegramLink,
                trailing: Text(
                  (tgId != null && tgId.isNotEmpty) ? 'Изменить' : 'Привязать',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF81262B), fontWeight: FontWeight.w600),
                ),
              ),
              _tile(
                title: 'Вконтакте',
                icon: Icons.link,
                subtitle: vkLabel,
              ),
              _tile(
                title: 'Apple',
                icon: Icons.apple,
                subtitle: 'Нет данных',
              ),
              _tile(
                title: 'Google',
                icon: Icons.g_mobiledata,
                subtitle: 'Нет данных',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile({
    required String title,
    required IconData icon,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
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
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
