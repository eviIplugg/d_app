import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/splash/theme_aware_splash.dart';
import 'services/auth/telegram_web_redirect.dart';
import 'theme/app_theme.dart';
import 'widgets/app_presence_scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await applyTelegramWebRedirectIfPresent();
  runApp(const DatingApp());
}

class DatingApp extends StatelessWidget {
  const DatingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ring me.',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      scrollBehavior: _AppScrollBehavior(),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final data = mq.copyWith(
          // Сдерживаем экстремальное масштабирование шрифтов, чтобы верстка не "ломалась"
          // на отдельных устройствах/системных настройках.
          textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.2),
        );
        return MediaQuery(
          data: data,
          child: AppPresenceScope(child: child ?? const SizedBox.shrink()),
        );
      },
      home: const ThemeAwareSplash(),
    );
  }
}

class _AppScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => AppTheme.scrollPhysics;
}
