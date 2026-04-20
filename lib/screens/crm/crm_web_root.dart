import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import '../../utils/crm_telegram_redirect.dart';
import 'crm_token_login_screen.dart';
import 'admin/admin_dashboard_screen.dart';

/// Корень веб-CRM (dating-app-34f38.web.app): вход только для админов.
/// Коллбэк Telegram (`?tg=1`) редиректится на основное приложение (consumer-host).
class CrmWebRoot extends StatefulWidget {
  const CrmWebRoot({super.key});

  @override
  State<CrmWebRoot> createState() => _CrmWebRootState();
}

class _CrmWebRootState extends State<CrmWebRoot> {
  @override
  void initState() {
    super.initState();
    redirectCrmToConsumerIfTelegramCallback();
  }

  @override
  Widget build(BuildContext context) {
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
          return const CrmTokenLoginScreen();
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
                          const SizedBox(height: 12),
                          Text(
                            'Вход через Telegram и приложение — на consumer-host',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
