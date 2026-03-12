import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../firebase/firestore_schema.dart';
import '../welcome/welcome_screen.dart';
import '../welcome/returning_user_welcome_screen.dart';
import '../feed/main_app_shell.dart';

/// После сплеша: если пользователь уже зарегистрирован (профиль в Firestore с именем и полом/фото) — экран «Добро пожаловать» затем лента.
/// Иначе показываем Welcome → регистрация (Terms, Auth) → заполнение профиля.
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
    final profile = await auth.getUserProfile(user.uid);
    if (!context.mounted) return;
    final isRegistered = auth.isProfileRegistered(profile);
    if (isRegistered) {
      final name = profile![kUserName]?.toString() ?? 'Пользователь';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReturningUserWelcomeScreen(userName: name),
        ),
      );
    } else {
      final hasName = profile != null &&
          profile[kUserName] != null &&
          (profile[kUserName] is String) &&
          (profile[kUserName] as String).trim().isNotEmpty;
      if (hasName) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainAppShell()),
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
