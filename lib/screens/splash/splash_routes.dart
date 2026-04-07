import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../firebase/firestore_schema.dart';
import '../../services/blacklist_service.dart';
import '../welcome/welcome_screen.dart';
import '../../navigation/post_auth_home.dart';

/// После сплеша: если пользователь уже зарегистрирован — сразу лента (без «Добро пожаловать»).
/// Экран «Добро пожаловать, Имя» показывается только после повторной авторизации (экраны входа).
/// Иначе — Welcome → регистрация → заполнение профиля.
Future<void> navigateAfterSplash(BuildContext context) async {
  if (!context.mounted) return;
  final auth = AuthService();
  final user = auth.currentUser;
  if (user == null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
    return;
  }
  try {
    // Blacklist: запрет повторной регистрации после жёсткого удаления
    final isBl = await BlacklistService().isPhoneBlacklisted(user.phoneNumber);
    if (!context.mounted) return;
    if (isBl) {
      await auth.signOut();
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
      return;
    }

    final profile = await auth.getUserProfile(user.uid);
    if (!context.mounted) return;

    // Telegram/VK: phoneNumber может отсутствовать. Проверяем blacklist по telegramUserId из профиля.
    final tg = profile?[kUserTelegramUserId]?.toString();
    if (await BlacklistService().isTelegramBlacklisted(tg)) {
      await auth.signOut();
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
      return;
    }

    final isRegistered = auth.isProfileRegistered(profile);
    if (isRegistered) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (context) => PostAuthHome.shell),
      );
    } else {
      final hasName = profile != null &&
          profile[kUserName] != null &&
          (profile[kUserName] is String) &&
          (profile[kUserName] as String).trim().isNotEmpty;
      if (hasName) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(builder: (context) => PostAuthHome.shell),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
  } catch (_) {
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }
}
