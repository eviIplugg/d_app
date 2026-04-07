import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'main.dart' show DatingApp;
import 'services/auth/telegram_web_redirect.dart';

/// Точка входа для веб-сборки (тот же consumer-приложение, что и [main.dart]).
/// Сборка: `flutter build web -t lib/main_crm_web.dart --release`
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await applyTelegramWebRedirectIfPresent();
  runApp(const DatingApp());
}
