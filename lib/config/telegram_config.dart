/// Конфиг для входа через Telegram (официальный Login Widget).
/// 1. Создайте бота в @BotFather, вrыполните /setdomain и укажите ваш HTTPS-домен.
/// 2. Укажите ниже имя бота (без @) и домен.
/// 3. В Firebase Console включите Anonymous sign-in (Authentication → Sign-in method).
const String telegramBotUsername = 'ringmeauth_bot'; // имя бота без @, например 'MyRingBot'
const String telegramBotDomain = 'auth-ringme.web.app'; // HTTPS-домен, привязанный в BotFather (страница/host для Telegram login widget)

bool get isTelegramConfigured =>
    telegramBotUsername.trim().isNotEmpty && telegramBotDomain.trim().isNotEmpty;
