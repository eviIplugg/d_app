/// Конфиг для входа через Telegram (официальный Login Widget).
/// 1. В @BotFather выполните /setdomain и укажите домен [telegramBotDomain] (без пути).
/// 2. Страница с виджетом после деплоя: [telegramWidgetPageUrl] (файл `hosting/telegram.html` → `build/web`).
/// 3. В Firebase Console включите Anonymous sign-in (Authentication → Sign-in method).
const String telegramBotUsername = 'ringmeauth_bot'; // имя бота без @

/// HTTPS-домен для BotFather (без пути) — совпадает с хостингом consumer (auth-ringme.web.app).
const String telegramBotDomain = 'auth-ringme.web.app';

/// Путь к статической странице с виджетом на том же сайте, что и Flutter.
const String telegramWidgetPath = '/telegram_auth.html';

/// Полный URL страницы входа через Telegram (открывать с web и в WebView на мобильных).
String get telegramWidgetPageUrl => 'https://$telegramBotDomain$telegramWidgetPath';

bool get isTelegramConfigured =>
    telegramBotUsername.trim().isNotEmpty && telegramBotDomain.trim().isNotEmpty;

/// Возврат в нативное приложение после виджета (iOS URL Types / Android intent-filter).
/// Не путать с HTTPS [telegramBotDomain] — там веб и PWA.
const String telegramDeepLinkScheme = 'ringme';
const String telegramDeepLinkHost = 'telegram';
