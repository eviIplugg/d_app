import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config/app_launch_config.dart';
import 'firebase_options.dart';
import 'screens/crm/crm_web_root.dart';
import 'services/auth/telegram_web_redirect.dart';
import 'theme/app_theme.dart';

/// Отдельная точка входа CRM (администрирование) для web-хоста `dating-app-34f38.web.app`.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLaunchConfig.enableCrmWebOnly();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await applyTelegramWebRedirectIfPresent();
  runApp(const _CrmAdminMaterialApp());
}

class _CrmAdminMaterialApp extends StatelessWidget {
  const _CrmAdminMaterialApp();

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
