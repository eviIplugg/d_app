import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/telegram_config.dart';
import '../../models/profile_draft.dart';
import '../../services/auth/auth_service.dart';
import '../profile_create/name_screen.dart';
import '../../navigation/auth_after_signin.dart';
import '../welcome/welcome_screen.dart';

/// Экран с официальным Telegram Login Widget. Данные только из Telegram.
/// [linkOnly]: привязка к текущему аккаунту (настройки) — без анонимного входа.
class TelegramLoginWebViewScreen extends StatefulWidget {
  const TelegramLoginWebViewScreen({super.key, this.linkOnly = false});

  /// `true` — только сохранить telegramUserId у уже авторизованного пользователя.
  final bool linkOnly;

  @override
  State<TelegramLoginWebViewScreen> createState() => _TelegramLoginWebViewScreenState();
}

class _TelegramLoginWebViewScreenState extends State<TelegramLoginWebViewScreen> {
  static const _scheme = 'ringme';
  static const _host = 'telegram';

  bool _isProcessing = false;
  bool _externalOpened = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && widget.linkOnly) {
      // На web просто пробуем открыть внешний хостинг сразу при показе экрана.
      // Даже если браузер блокирует всплывающее окно, у пользователя останется кнопка «Открыть ещё раз».
      _openExternalAuthPage();
    }
  }

  Future<void> _openExternalAuthPage() async {
    if (_externalOpened) return;
    if (!isTelegramConfigured) return;
    _externalOpened = true;

    final domain = telegramBotDomain.trim();
    final url = domain.startsWith('http://') || domain.startsWith('https://')
        ? domain
        : 'https://$domain';

    try {
      // Не делаем `await`, чтобы не терять шанс на «пользовательское действие» в браузере.
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).then((ok) {
        if (!ok && mounted) {
          setState(() => _externalOpened = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось открыть Telegram. Возможно блокируется всплывающее окно.')),
          );
        }
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _externalOpened = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка открытия Telegram.')),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _externalOpened = false);
    }
  }

  String get _html {
    final bot = telegramBotUsername.trim().isEmpty ? 'placeholder_bot' : telegramBotUsername.trim();
    final safeClass = bot.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Вход через Telegram</title>
  <style>
    body { font-family: -apple-system, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: #f3f3f3; }
    #wrap { text-align: center; }
    h2 { color: #333; margin-bottom: 24px; }
  </style>
</head>
<body>
  <div id="wrap">
    <h2>${widget.linkOnly ? 'Привязка Telegram' : 'Вход через Telegram'}</h2>
    <div class="telegram-login-$safeClass" 
         data-telegram-login="$bot" 
         data-size="large" 
         data-onauth="onTelegramAuth(user)" 
         data-request-access="write"></div>
  </div>
  <script>
    function onTelegramAuth(user) {
      var q = 'id=' + encodeURIComponent(user.id || '') +
              '&first_name=' + encodeURIComponent(user.first_name || '') +
              '&last_name=' + encodeURIComponent(user.last_name || '') +
              '&username=' + encodeURIComponent(user.username || '');
      window.location = '$_scheme://$_host?' + q;
    }
  </script>
  <script async src="https://core.telegram.org/widget/login.js"></script>
</body>
</html>
''';
  }

  /// Добавляет https:// если в строке нет схемы (для Uri.parse и loadRequest).
  static String _ensureScheme(String url) {
    final s = url.trim().toLowerCase();
    if (s.startsWith('https://') || s.startsWith('http://')) return url.trim();
    return 'https://${url.trim()}';
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && widget.linkOnly) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F3F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF3F3F3),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Привязка Telegram',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Открываем страницу Telegram…',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _openExternalAuthPage,
                  child: const Text('Открыть ещё раз'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final auth = AuthService();
    final domain = telegramBotDomain.trim();
    final baseUrl = domain.isEmpty
        ? null
        : _ensureScheme(domain.endsWith('/') ? domain : '$domain/');

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            if (req.url.startsWith('$_scheme://$_host')) {
              _onTelegramCallback(context, req.url, auth);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    if (baseUrl != null && baseUrl.isNotEmpty) {
      controller.loadRequest(Uri.parse(baseUrl));
    } else {
      controller.loadHtmlString(_html, baseUrl: 'https://core.telegram.org/');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.linkOnly ? 'Привязка Telegram' : 'Вход через Telegram',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  void _onTelegramCallback(BuildContext context, String url, AuthService auth) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final uri = Uri.parse(url);
    final first = uri.queryParameters['first_name'] ?? '';
    final last = uri.queryParameters['last_name'] ?? '';
    final username = uri.queryParameters['username'] ?? '';
    final id = uri.queryParameters['id'] ?? '';
    final fullName = '$first $last'.trim();
    final name = fullName.isEmpty ? (username.isNotEmpty ? username : 'Пользователь') : fullName;

    try {
      if (widget.linkOnly) {
        final uid = auth.currentUserId;
        if (!context.mounted) return;
        if (uid == null) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Сначала войдите в аккаунт'), backgroundColor: Colors.orange),
          );
          return;
        }
        if (id.isEmpty) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось получить данные Telegram'), backgroundColor: Colors.red),
          );
          return;
        }
        final err = await auth.linkTelegramToCurrentUser(telegramUserId: id);
        if (!context.mounted) return;
        setState(() => _isProcessing = false);
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

      final uid = await auth.signInAnonymouslyForTelegram();
      if (!context.mounted) return;
      if (uid == null) {
        setState(() => _isProcessing = false);
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
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Этот Telegram уже привязан к другому аккаунту. Войдите на том устройстве.'),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
            return;
          }
          if (existingUid == uid && auth.hasProfileWithName(existing)) {
            setState(() => _isProcessing = false);
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
      setState(() => _isProcessing = false);
      if (!auth.hasProfileWithName(profile)) {
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (context) => NameScreen(draft: ProfileDraft(name: name)),
          ),
        );
        return;
      }
      await AuthAfterSignIn.navigateFromProfile(context, auth, profile);
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка входа: $e. Включите Anonymous в Firebase Console → Authentication.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
