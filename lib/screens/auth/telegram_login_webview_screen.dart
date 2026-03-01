import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/telegram_config.dart';
import '../../models/profile_draft.dart';
import '../../services/auth/auth_service.dart';
import '../profile_create/name_screen.dart';

/// Экран с официальным Telegram Login Widget. Данные только из Telegram.
/// При успехе — переход на экран «Как вас зовут?» с именем из Telegram.
class TelegramLoginWebViewScreen extends StatefulWidget {
  const TelegramLoginWebViewScreen({super.key});

  @override
  State<TelegramLoginWebViewScreen> createState() => _TelegramLoginWebViewScreenState();
}

class _TelegramLoginWebViewScreenState extends State<TelegramLoginWebViewScreen> {
  static const _scheme = 'ringme';
  static const _host = 'telegram';

  bool _isProcessing = false;

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
    <h2>Вход через Telegram</h2>
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
        title: const Text(
          'Вход через Telegram',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
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
      final uid = await auth.signInWithTelegram(
        telegramName: name,
        telegramUserId: id.isNotEmpty ? id : null,
      );
      if (!context.mounted) return;
      if (uid != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NameScreen(draft: ProfileDraft(name: name)),
          ),
        );
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось войти. Включите Anonymous в Firebase Console → Authentication.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
