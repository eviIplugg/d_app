import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';

import '../../config/telegram_config.dart';
import '../../navigation/auth_after_signin.dart';
import '../../screens/welcome/welcome_screen.dart';
import 'auth_service.dart';

/// Параметры query из deep link (на части устройств [Uri.queryParameters] обрезает длинную строку).
Map<String, String> _telegramDeepLinkParams(Uri uri) {
  final merged = <String, String>{};
  void putAll(Map<String, String> m) => m.forEach((k, v) => merged[k] = v);
  putAll(uri.queryParameters);
  final raw = uri.toString();
  final qIdx = raw.indexOf('?');
  if (qIdx >= 0) {
    final hashIdx = raw.indexOf('#', qIdx + 1);
    final queryPart = hashIdx < 0 ? raw.substring(qIdx + 1) : raw.substring(qIdx + 1, hashIdx);
    try {
      putAll(Uri.splitQueryString(queryPart));
    } catch (_) {}
  }
  return merged;
}

/// Параметры для [telegramSignIn] (без `tg` и без пустых значений — как в проверке HMAC на сервере).
Map<String, dynamic> _telegramSignInPayloadFromUri(Uri uri) {
  final q = _telegramDeepLinkParams(uri);
  final out = <String, dynamic>{};
  for (final e in q.entries) {
    if (e.key == 'tg') continue;
    if (e.value.trim().isEmpty) continue;
    out[e.key] = e.value;
  }
  return out;
}

bool _uriHasTelegramSignature(Uri uri) {
  final q = _telegramDeepLinkParams(uri);
  final id = q['id']?.trim() ?? '';
  final hash = q['hash']?.trim() ?? '';
  final authDate = q['auth_date']?.trim() ?? '';
  if (id.isEmpty || hash.isEmpty || authDate.isEmpty) {
    if (kDebugMode && id.isNotEmpty) {
      debugPrint(
        'Telegram deep link: нет hash/auth_date в URI (нужны для входа). keys=${q.keys.toList()}',
      );
    }
    return false;
  }
  return true;
}

/// Коллбэк Telegram после виджета: `ringme://telegram?tg=1&...`
/// Допускается `ringme://telegram?id=...` без `tg` (старый встроенный HTML во WebView).
bool isTelegramAppCallbackUri(Uri uri) {
  if (uri.scheme.toLowerCase() != telegramDeepLinkScheme.toLowerCase()) return false;
  if (uri.host.toLowerCase() != telegramDeepLinkHost.toLowerCase()) return false;
  if (uri.queryParameters['tg'] == '1') return true;
  final id = uri.queryParameters['id'];
  return id != null && id.isNotEmpty;
}

/// Та же логика, что и в [TelegramLoginWebViewScreen] после успешного входа в Telegram.
Future<void> runTelegramAuthFromCallbackUri({
  required BuildContext context,
  required Uri uri,
  required bool linkOnly,
  void Function(bool isProcessing)? onProcessing,
}) async {
  final auth = AuthService();
  onProcessing?.call(true);

  final first = uri.queryParameters['first_name'] ?? '';
  final last = uri.queryParameters['last_name'] ?? '';
  final username = uri.queryParameters['username'] ?? '';
  final id = uri.queryParameters['id'] ?? '';
  final fullName = '$first $last'.trim();
  final name = fullName.isEmpty ? (username.isNotEmpty ? username : 'Пользователь') : fullName;

  try {
    if (linkOnly) {
      final uid = auth.currentUserId;
      if (!context.mounted) return;
      if (uid == null) {
        onProcessing?.call(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сначала войдите в аккаунт'), backgroundColor: Colors.orange),
        );
        return;
      }
      if (id.isEmpty) {
        onProcessing?.call(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось получить данные Telegram'), backgroundColor: Colors.red),
        );
        return;
      }
      final err = await auth.linkTelegramToCurrentUser(telegramUserId: id);
      if (!context.mounted) return;
      onProcessing?.call(false);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.orange),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telegram привязан'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
      return;
    }

    // Как на web: подпись Telegram → Cloud Function → custom token с тем же uid, что в Firestore.
    // Иначе каждый раз новый anonymous uid и «Telegram привязан к другому аккаунту».
    if (!linkOnly && _uriHasTelegramSignature(uri)) {
      try {
        final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
        final callable = functions.httpsCallable('telegramSignIn');
        final raw = await callable.call(_telegramSignInPayloadFromUri(uri));
        final data = raw.data;
        if (data is! Map) {
          onProcessing?.call(false);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Неверный ответ сервера входа'), backgroundColor: Colors.red),
          );
          return;
        }
        final map = Map<String, dynamic>.from(data);
        final customToken = map['customToken']?.toString();
        if (customToken != null && customToken.isNotEmpty) {
          await auth.signInWithCustomToken(customToken);
          if (!context.mounted) return;
          final uid = auth.currentUserId;
          if (uid == null) {
            onProcessing?.call(false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Не удалось применить сессию'), backgroundColor: Colors.red),
            );
            return;
          }
          final profile = await auth.getUserProfile(uid);
          if (!context.mounted) return;
          onProcessing?.call(false);
          await AuthAfterSignIn.navigateFromProfile(context, auth, profile);
          return;
        }
        if (map['register'] == true) {
          final uid = await auth.signInAnonymouslyForTelegram();
          if (!context.mounted) return;
          if (uid == null) {
            onProcessing?.call(false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Не удалось войти. Включите Anonymous в Firebase Console → Authentication.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          await auth.saveTelegramUser(
            uid: uid,
            telegramName: name,
            telegramUserId: id.isNotEmpty ? id : null,
          );
          if (!context.mounted) return;
          final profile = await auth.getUserProfile(uid);
          if (!context.mounted) return;
          onProcessing?.call(false);
          await AuthAfterSignIn.navigateFromProfile(context, auth, profile);
          return;
        }
        onProcessing?.call(false);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Неожиданный ответ: $map'), backgroundColor: Colors.orange),
        );
        return;
      } on FirebaseFunctionsException catch (e) {
        onProcessing?.call(false);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Ошибка входа Telegram'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      } catch (e) {
        onProcessing?.call(false);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка входа: $e'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    final uid = await auth.signInAnonymouslyForTelegram();
    if (!context.mounted) return;
    if (uid == null) {
      onProcessing?.call(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось войти. Включите Anonymous в Firebase Console → Authentication.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (id.isNotEmpty) {
      final existing = await auth.findUserByTelegramId(id);
      if (!context.mounted) return;
      if (existing != null) {
        final existingUid = existing['uid']?.toString();
        if (existingUid != null && existingUid != uid) {
          await auth.signOut();
          if (!context.mounted) return;
          onProcessing?.call(false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Нужен вход с подписью Telegram (обновите приложение и страницу auth-ringme). '
                'Повторите «Вход через Telegram» на странице с виджетом.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
          return;
        }
        if (existingUid == uid && auth.isProfileRegistered(existing)) {
          onProcessing?.call(false);
          await AuthAfterSignIn.navigateFromProfile(context, auth, existing);
          return;
        }
      }
    }

    await auth.saveTelegramUser(
      uid: uid,
      telegramName: name,
      telegramUserId: id.isNotEmpty ? id : null,
    );
    if (!context.mounted) return;
    final profile = await auth.getUserProfile(uid);
    if (!context.mounted) return;
    onProcessing?.call(false);
    await AuthAfterSignIn.navigateFromProfile(context, auth, profile);
  } catch (e) {
    if (!context.mounted) return;
    onProcessing?.call(false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ошибка входа: $e. Включите Anonymous в Firebase Console → Authentication.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
