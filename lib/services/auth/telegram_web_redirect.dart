import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import '../../utils/telegram_web_url.dart';
import 'auth_service.dart';

/// Обработка `?tg=1&...` после Telegram Login Widget на web.
///
/// 1) Вызывает Cloud Function [telegramSignIn]: проверка подписи Telegram.
/// 2) Если пользователь уже есть — `signInWithCustomToken` (тот же Firebase uid).
/// 3) Если новый — anonymous + [AuthService.saveTelegramUser].
Future<void> applyTelegramWebRedirectIfPresent() async {
  if (!kIsWeb) return;

  final params = Uri.base.queryParameters;
  if (params['tg'] != '1') return;
  final id = params['id'];
  if (id == null || id.isEmpty) return;

  final hash = params['hash'];
  if (hash == null || hash.isEmpty) {
    debugPrint('applyTelegramWebRedirectIfPresent: нет hash — полный вход только с виджета Telegram (auth_date + hash).');
    clearTelegramQueryFromCurrentUrl();
    return;
  }

  final auth = AuthService();
  final first = params['first_name'] ?? '';
  final last = params['last_name'] ?? '';
  final username = params['username'] ?? '';
  final fullName = '$first $last'.trim();
  final name = fullName.isEmpty ? (username.isNotEmpty ? username : 'Пользователь') : fullName;

  try {
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    final callable = functions.httpsCallable('telegramSignIn');

    final payload = <String, dynamic>{};
    for (final e in params.entries) {
      if (e.key == 'tg') continue;
      payload[e.key] = e.value;
    }

    final result = await callable.call(payload);
    final raw = result.data;
    if (raw is! Map) {
      clearTelegramQueryFromCurrentUrl();
      return;
    }
    final data = Map<String, dynamic>.from(raw);

    final customToken = data['customToken']?.toString();
    if (customToken != null && customToken.isNotEmpty) {
      await auth.signInWithCustomToken(customToken);
      clearTelegramQueryFromCurrentUrl();
      return;
    }

    if (data['register'] == true) {
      final uid = await auth.signInAnonymouslyForTelegram();
      if (uid == null) {
        clearTelegramQueryFromCurrentUrl();
        return;
      }
      await auth.saveTelegramUser(
        uid: uid,
        telegramName: name,
        telegramUserId: id,
      );
    }
  } on FirebaseFunctionsException catch (e, st) {
    debugPrint('telegramSignIn: ${e.code} ${e.message}\n$st');
  } catch (e, st) {
    debugPrint('applyTelegramWebRedirectIfPresent: $e\n$st');
  }

  clearTelegramQueryFromCurrentUrl();
}
