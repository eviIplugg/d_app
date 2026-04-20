import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/telegram_config.dart';
import '../../firebase/firestore_schema.dart';
import '../../services/auth/auth_service.dart';
import '../../services/blacklist_service.dart';
import '../../navigation/auth_after_signin.dart';
import 'phone_input_screen.dart';
import 'telegram_login_webview_screen.dart';

class AuthOptionsScreen extends StatefulWidget {
  const AuthOptionsScreen({super.key});

  @override
  State<AuthOptionsScreen> createState() => _AuthOptionsScreenState();
}

class _AuthOptionsScreenState extends State<AuthOptionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAlreadyLoggedIn());
  }

  Future<void> _checkAlreadyLoggedIn() async {
    final auth = AuthService();
    final uid = auth.currentUserId;
    if (uid == null) return;
    final profile = await auth.getUserProfile(uid);
    if (!mounted) return;
    if (await BlacklistService().isPhoneBlacklisted(auth.currentUser?.phoneNumber) ||
        await BlacklistService().isTelegramBlacklisted(profile?[kUserTelegramUserId]?.toString())) {
      await auth.signOut();
      if (!mounted) return;
      return;
    }
    if (!mounted) return;
    await AuthAfterSignIn.navigateFromProfile(context, auth, profile);
  }

  Future<void> _openTelegram(BuildContext context) async {
    if (!isTelegramConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройте telegramBotUsername и telegramBotDomain в lib/config/telegram_config.dart'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Открываем Telegram авторизацию...'), backgroundColor: Colors.blueGrey),
      );

      final uri = Uri.parse(telegramWidgetPageUrl);

      try {
        launchUrl(uri, mode: LaunchMode.externalApplication).then((ok) {
          if (!context.mounted) return;
          if (!ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Не удалось открыть Telegram. Возможно блокируется всплывающее окно.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }).catchError((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка открытия Telegram.'), backgroundColor: Colors.red),
          );
        });
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка открытия Telegram: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TelegramLoginWebViewScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : const Color(0xFFF3F3F3);
    final fg = isDark ? Colors.white : const Color(0xFF333333);
    final sub = isDark ? Colors.white70 : Colors.grey.shade700;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: fg),
                onPressed: () {
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                },
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Регистрация',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Выберите способ входа — дальше заполните профиль в приложении.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: sub, height: 1.35),
                    ),
                    const SizedBox(height: 40),
                    _AuthButton(
                      isDark: isDark,
                      text: 'Войти по номеру телефона',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => const PhoneInputScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _AuthButton(
                      isDark: isDark,
                      text: 'Войти через Telegram',
                      onPressed: () => _openTelegram(context),
                      accentColor: const Color(0xFF0088CC),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final bool isDark;
  final String text;
  final VoidCallback onPressed;
  final Color? accentColor;

  const _AuthButton({
    required this.isDark,
    required this.text,
    required this.onPressed,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (accentColor != null) ...[
                  Icon(Icons.send, size: 20, color: accentColor),
                  const SizedBox(width: 10),
                ],
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: accentColor ?? (isDark ? Colors.white : const Color(0xFF333333)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
