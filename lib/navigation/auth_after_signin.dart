import 'package:flutter/material.dart';

import '../firebase/firestore_schema.dart';
import '../screens/profile_create/name_screen.dart';
import '../screens/welcome/returning_user_welcome_screen.dart';
import '../services/auth/auth_service.dart';

/// Куда направить после успешного входа (онбординг / приветствие).
class AuthAfterSignIn {
  AuthAfterSignIn._();

  static Future<void> navigateFromProfile(
    BuildContext context,
    AuthService auth,
    Map<String, dynamic>? profile,
  ) async {
    if (!context.mounted) return;

    if (auth.hasProfileWithName(profile)) {
      final name = profile?[kUserName]?.toString() ?? 'Пользователь';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (context) => ReturningUserWelcomeScreen(userName: name),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const NameScreen()),
      );
    }
  }
}
