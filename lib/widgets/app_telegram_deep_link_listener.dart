import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';

import '../navigation/app_navigator.dart';
import '../services/auth/telegram_auth_from_callback_uri.dart';
import '../services/auth/telegram_deep_link_gate.dart';

/// Слушает `ringme://telegram?tg=1&...` после страницы виджета в системном браузере.
class AppTelegramDeepLinkListener extends StatefulWidget {
  const AppTelegramDeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  State<AppTelegramDeepLinkListener> createState() => _AppTelegramDeepLinkListenerState();
}

class _AppTelegramDeepLinkListenerState extends State<AppTelegramDeepLinkListener> {
  StreamSubscription<Uri>? _sub;
  final Set<String> _inFlight = <String>{};
  final Set<String> _completedOk = <String>{};

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      TelegramDeepLinkGate.markInitialHandlingDone();
      return;
    }
    // Ранняя регистрация singleton (README app_links).
    AppLinks();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      final appLinks = AppLinks();
      // Сначала cold-start ссылка, потом stream — иначе дубликат initial+stream блокирует вход.
      final initial = await appLinks.getInitialLink();
      _sub = appLinks.uriLinkStream.listen((uri) {
        if (mounted) unawaited(_handleIncoming(uri));
      });
      if (initial != null && isTelegramAppCallbackUri(initial)) {
        await _runWhenNavigatorReady(initial);
      }
    } catch (e, st) {
      assert(() {
        debugPrint('AppTelegramDeepLinkListener: $e\n$st');
        return true;
      }());
    } finally {
      TelegramDeepLinkGate.markInitialHandlingDone();
    }
  }

  Future<void> _handleIncoming(Uri uri) async {
    if (!isTelegramAppCallbackUri(uri)) return;
    await _runWhenNavigatorReady(uri);
  }

  Future<void> _runWhenNavigatorReady(Uri uri) async {
    final key = uri.toString();
    if (_completedOk.contains(key) || _inFlight.contains(key)) return;
    _inFlight.add(key);
    try {
      for (var i = 0; i < 80; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          await runTelegramAuthFromCallbackUri(
            context: ctx,
            uri: uri,
            linkOnly: false,
          );
          _completedOk.add(key);
          return;
        }
      }
    } catch (e, st) {
      assert(() {
        debugPrint('Telegram deep link auth: $e\n$st');
        return true;
      }());
    } finally {
      _inFlight.remove(key);
    }
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
