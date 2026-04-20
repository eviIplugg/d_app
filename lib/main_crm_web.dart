import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config/app_launch_config.dart';
import 'firebase_options.dart';
import 'screens/crm/crm_web_root.dart';
import 'services/auth/telegram_web_redirect.dart';
import 'theme/app_theme.dart';

/// Точка входа **только для CRM** на https://dating-app-34f38.web.app
///
/// Сборка: `flutter build web -t lib/main_crm_web.dart --release --output=build/web_crm`
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLaunchConfig.enableCrmWebOnly();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await applyTelegramWebRedirectIfPresent();
  runApp(const _CrmMaterialApp());
}

class _CrmMaterialApp extends StatelessWidget {
  const _CrmMaterialApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ring me. CRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      home: const CrmWebRoot(),
    );
  }
}
