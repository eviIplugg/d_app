import 'package:flutter/material.dart';

import '../firebase/firestore_schema.dart';
import '../models/profile_draft.dart';
import '../screens/profile_create/name_screen.dart';
import '../screens/welcome/returning_user_welcome_screen.dart';
import '../services/auth/auth_service.dart';

/// Куда направить после успешного входа (онбординг / приветствие).
class AuthAfterSignIn {
  AuthAfterSignIn._();

  /// Полный профиль: имя и (пол или фото). Имя только из Telegram/телефона — всё ещё онбординг.
  static Future<void> navigateFromProfile(
    BuildContext context,
    AuthService auth,
    Map<String, dynamic>? profile,
  ) async {
    if (!context.mounted) return;

    if (auth.isProfileRegistered(profile)) {
      final name = profile?[kUserName]?.toString() ?? 'Пользователь';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (context) => ReturningUserWelcomeScreen(userName: name),
        ),
      );
    } else {
      final draftName = profile?[kUserName]?.toString().trim() ?? '';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => NameScreen(draft: ProfileDraft(name: draftName)),
        ),
      );
    }
  }
}
