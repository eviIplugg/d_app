import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;

/// Задерживает [navigateAfterSplash], пока обработается cold-start deep link Telegram
/// (иначе сплэш уводит на Welcome до завершения anonymous sign-in).
class TelegramDeepLinkGate {
  TelegramDeepLinkGate._();

  static final Completer<void> _initialHandlingDone = Completer<void>();

  static void markInitialHandlingDone() {
    if (!_initialHandlingDone.isCompleted) {
      _initialHandlingDone.complete();
    }
  }

  static Future<void> waitForInitialDeepLinkHandling() async {
    if (kIsWeb) return;
    try {
      await _initialHandlingDone.future.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      // продолжаем сплэш
    }
  }
}
