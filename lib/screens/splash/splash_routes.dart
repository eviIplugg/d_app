import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../firebase/firestore_schema.dart';
import '../welcome/welcome_screen.dart';
import '../feed/main_app_shell.dart';

/// После сплеша: если пользователь уже зарегистрирован (профиль в Firestore с именем) — лента.
/// Иначе показываем Welcome → регистрация (Terms, Auth) → заполнение профиля (имя и т.д.).
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
    final isRegistered = profile != null &&
        profile[kUserName] != null &&
        (profile[kUserName] is String) &&
        (profile[kUserName] as String).trim().isNotEmpty;
    if (isRegistered) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainAppShell()),
      );
    } else {
      // Профиль не заполнен — показываем Welcome, затем пользователь пройдёт Terms и экран регистрации
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  } catch (_) {
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }
}
