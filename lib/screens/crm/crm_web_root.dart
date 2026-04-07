import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import '../welcome/welcome_screen.dart';
import 'admin/admin_dashboard_screen.dart';

/// Корень веб-CRM: незалогиненным — приветствие и вход; админу — панель; остальным — отказ.
class CrmWebRoot extends StatefulWidget {
  const CrmWebRoot({super.key});

  @override
  State<CrmWebRoot> createState() => _CrmWebRootState();
}

class _CrmWebRootState extends State<CrmWebRoot> {
  bool _telegramCallbackProcessed = false;
  String? _telegramError;

  @override
  void initState() {
    super.initState();
    _maybeHandleTelegramCallback();
  }

  Future<void> _maybeHandleTelegramCallback() async {
    if (_telegramCallbackProcessed) return;
    _telegramCallbackProcessed = true;

    final params = Uri.base.queryParameters;
    // На странице Telegram-виджета мы редиректим: ringme.web.app/?tg=1&id=...
    final tg = params['tg'];
    final id = params['id'];
    if (tg != '1' || (id == null || id.isEmpty)) return;

    final auth = AuthService();
    final first = params['first_name'] ?? '';
    final last = params['last_name'] ?? '';
    final username = params['username'] ?? '';
    final fullName = '$first $last'.trim();
    final name = fullName.isEmpty ? (username.isNotEmpty ? username : 'Пользователь') : fullName;

    try {
      final uid = await auth.signInAnonymouslyForTelegram();
      if (uid == null) {
        setState(() => _telegramError = 'Не удалось выполнить anonymous sign-in');
        return;
      }

      // Защита от ситуации «Telegram ID привязан к другому пользователю».
      final existing = await auth.findUserByTelegramId(id);
      if (existing != null) {
        final existingUid = existing['uid']?.toString();
        if (existingUid != null && existingUid != uid) {
          await auth.signOut();
          if (!mounted) return;
          setState(() => _telegramError = 'Этот Telegram уже привязан к другому аккаунту. Войдите на том устройстве.');
          return;
        }
      }

      await auth.saveTelegramUser(
        uid: uid,
        telegramName: name,
        telegramUserId: id,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _telegramError = 'Ошибка Telegram callback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_telegramError != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade700),
                  const SizedBox(height: 16),
                  Text(
                    _telegramError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => AuthService().signOut(),
                    child: const Text('Выйти'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) {
          return const WelcomeScreen();
        }
        return FutureBuilder<bool>(
          future: AuthService().isAdmin(),
          builder: (context, adminSnap) {
            if (!adminSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (adminSnap.data != true) {
              return Scaffold(
                body: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade600),
                          const SizedBox(height: 16),
                          Text(
                            'Доступ только для администраторов',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade800),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => AuthService().signOut(),
                            child: const Text('Выйти'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            return const AdminDashboardScreen();
          },
        );
      },
    );
  }
}
