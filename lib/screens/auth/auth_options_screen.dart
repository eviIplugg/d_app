import 'package:flutter/material.dart';
import '../../config/telegram_config.dart';
import '../../services/auth/auth_service.dart';
import 'phone_input_screen.dart';
import 'telegram_login_webview_screen.dart';
import '../profile_create/name_screen.dart';

class AuthOptionsScreen extends StatefulWidget {
  const AuthOptionsScreen({super.key});

  @override
  State<AuthOptionsScreen> createState() => _AuthOptionsScreenState();
}

class _AuthOptionsScreenState extends State<AuthOptionsScreen> {
  @override
  void initState() {
    super.initState();
    AuthService().ensureVKInitialized();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
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
                    const Text(
                      'Регистрация',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 48),
                    _AuthButton(
                      text: 'Номер телефона',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PhoneInputScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _IconOnlyButton(
                      icon: _VKLogo(),
                      onPressed: () => _signInWithVK(context),
                    ),
                    const SizedBox(height: 16),
                    _AuthButton(
                      text: 'Telegram',
                      onPressed: () {
                        if (!isTelegramConfigured) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Настройте telegramBotUsername и telegramBotDomain в lib/config/telegram_config.dart'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TelegramLoginWebViewScreen(),
                          ),
                        );
                      },
                      accentColor: const Color(0xFF0088CC),
                    ),
                    const SizedBox(height: 16),
                    _AuthButton(
                      text: 'Войти',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PhoneInputScreen(),
                          ),
                        );
                      },
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

  Future<void> _signInWithVK(BuildContext context) async {
    final auth = AuthService();
    try {
      final cred = await auth.signInWithVK();
      if (cred == null || !context.mounted) return;
      await auth.saveOrUpdateUser(
        uid: auth.currentUserId!,
        authProvider: 'vk',
      );
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NameScreen()),
      );
    } catch (e) {
      if (!context.mounted) return;
      final String msg = e.toString().contains('initSdk') || e.toString().contains('_initialized') || e.toString().contains('VK ID')
          ? 'Вход через VK ID временно недоступен. Проверьте VKID_CLIENT_ID и VKID_CLIENT_SECRET в android/gradle.properties.'
          : 'Ошибка входа VK ID: ${e.toString().split('\n').first}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }
}

class _AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? accentColor;

  const _AuthButton({required this.text, required this.onPressed, this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    color: accentColor ?? const Color(0xFF333333),
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

class _IconOnlyButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;

  const _IconOnlyButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

class _VKLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const double originalWidth = 115;
    const double originalHeight = 20;
    const double uiHeight = 20;
    final double uiWidth = (originalWidth / originalHeight) * uiHeight;
    return Image.asset(
      'assets/images/registration_icons/vk.png',
      width: uiWidth,
      height: uiHeight,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: uiWidth,
          height: uiHeight,
          child: const Center(
            child: Text('VK', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        );
      },
    );
  }
}

