import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../firebase/firestore_schema.dart';
import '../../models/profile_draft.dart';
import '../../services/blacklist_service.dart';
import '../welcome/welcome_screen.dart';
import '../profile_create/name_screen.dart';
import '../../navigation/post_auth_home.dart';

/// После сплеша: полный профиль → лента; иначе (в т.ч. после Telegram) → заполнение анкеты.
Future<void> navigateAfterSplash(BuildContext context) async {
  if (!context.mounted) return;
  final auth = AuthService();
  final user = kIsWeb ? await auth.waitForInitialUserOnWeb() : auth.currentUser;
  if (!context.mounted) return;
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
      return;
    }
    if (auth.hasProfileWithName(profile)) {
      final name = profile?[kUserName]?.toString().trim() ?? '';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (context) => NameScreen(draft: ProfileDraft(name: name)),
        ),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  } catch (_) {
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }
}
