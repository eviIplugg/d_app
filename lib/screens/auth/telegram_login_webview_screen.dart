import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/telegram_config.dart';
import '../../config/web_hosts.dart';
import '../../services/auth/telegram_auth_from_callback_uri.dart';

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
  static String get _scheme => telegramDeepLinkScheme;
  static String get _host => telegramDeepLinkHost;

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

    try {
      // Не делаем `await`, чтобы не терять шанс на «пользовательское действие» в браузере.
      launchUrl(Uri.parse(telegramWidgetPageUrl), mode: LaunchMode.externalApplication).then((ok) {
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
      var q = 'tg=1&id=' + encodeURIComponent(user.id || '') +
              '&auth_date=' + encodeURIComponent(String(user.auth_date || '')) +
              '&hash=' + encodeURIComponent(user.hash || '');
      if (user.first_name) q += '&first_name=' + encodeURIComponent(user.first_name);
      if (user.last_name) q += '&last_name=' + encodeURIComponent(user.last_name);
      if (user.username) q += '&username=' + encodeURIComponent(user.username);
      if (user.photo_url) q += '&photo_url=' + encodeURIComponent(user.photo_url);
      window.location = '$_scheme://$_host/?' + q;
    }
  </script>
  <script async src="https://core.telegram.org/widget/login.js"></script>
</body>
</html>
''';
  }

  static bool _isConsumerTelegramCallback(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return false;
    if (u.queryParameters['tg'] != '1') return false;
    return u.origin == Uri.parse(kConsumerWebAppOrigin).origin;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : const Color(0xFFF3F3F3);
    final fg = isDark ? Colors.white : const Color(0xFF333333);
    if (kIsWeb && widget.linkOnly) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: fg),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Привязка Telegram',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: fg),
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

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            final asUri = Uri.tryParse(req.url);
            if (asUri != null && isTelegramAppCallbackUri(asUri)) {
              _onTelegramCallback(context, req.url);
              return NavigationDecision.prevent;
            }
            if (_isConsumerTelegramCallback(req.url)) {
              _onTelegramCallback(context, req.url);
              return NavigationDecision.prevent;
            }
            if (req.url.startsWith('$_scheme://$_host')) {
              _onTelegramCallback(context, req.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    // Виджет Telegram должен открываться на домене, указанном в BotFather (/setdomain),
    // иначе кнопка не отображается. Поэтому грузим страницу с auth-ringme хоста.
    final pageUrl = telegramWidgetPageUrl.trim();
    if (pageUrl.isNotEmpty) {
      controller.loadRequest(Uri.parse(pageUrl));
    } else {
      controller.loadHtmlString(_html, baseUrl: 'https://core.telegram.org/');
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: fg),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.linkOnly ? 'Привязка Telegram' : 'Вход через Telegram',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: fg),
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

  Future<void> _onTelegramCallback(BuildContext context, String url) async {
    if (_isProcessing) return;
    await runTelegramAuthFromCallbackUri(
      context: context,
      uri: Uri.parse(url),
      linkOnly: widget.linkOnly,
      onProcessing: (v) {
        if (mounted) setState(() => _isProcessing = v);
      },
    );
  }
}
