import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth/auth_service.dart';

/// Периодически обновляет [kUserLastActiveAt] при открытом приложении (для статуса «в сети»).
class AppPresenceScope extends StatefulWidget {
  const AppPresenceScope({super.key, required this.child});

  final Widget? child;

  @override
  State<AppPresenceScope> createState() => _AppPresenceScopeState();
}

class _AppPresenceScopeState extends State<AppPresenceScope> with WidgetsBindingObserver {
  final AuthService _auth = AuthService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth.touchLastActive(minInterval: Duration.zero);
    _timer = Timer.periodic(const Duration(seconds: 90), (_) {
      _auth.touchLastActive();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _auth.touchLastActive(minInterval: Duration.zero);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}
