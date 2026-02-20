# Email Auth Service - Инструкция по интеграции API

## Описание

Сервис `EmailAuthService` содержит заглушки для работы с API аутентификации через email. Для интеграции с реальным бэкендом необходимо:

## Шаги интеграции

### 1. Добавить зависимости HTTP клиента

В `pubspec.yaml` добавьте:

```yaml
dependencies:
  http: ^1.1.0  # или dio: ^5.4.0 для более продвинутого клиента
```

Затем выполните:
```bash
flutter pub get
```

### 2. Настроить базовый URL API

В файле `email_auth_service.dart` раскомментируйте и укажите ваш API URL:

```dart
static const String baseUrl = 'https://your-api-url.com/api';
```

### 3. Реализовать метод `sendVerificationCode`

Замените заглушку на реальный HTTP запрос. Пример с использованием `http`:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<EmailVerificationResponse> sendVerificationCode(
  EmailVerificationRequest request,
) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-verification-code'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return EmailVerificationResponse.fromJson(jsonData);
    } else {
      throw Exception('Failed to send verification code: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error sending verification code: $e');
  }
}
```

### 4. Формат API запроса/ответа

#### Запрос (POST `/auth/send-verification-code`):
```json
{
  "email": "user@example.com"
}
```

#### Ответ (успешный):
```json
{
  "success": true,
  "message": "Код отправлен на email",
  "verification_token": "abc123...",
  "code_expires_in": 300
}
```

#### Ответ (ошибка):
```json
{
  "success": false,
  "message": "Email уже зарегистрирован"
}
```

### 5. Реализовать запись в БД

На бэкенде при получении запроса на отправку кода:

1. Проверить, не зарегистрирован ли email уже
2. Сгенерировать код верификации (обычно 4-6 цифр)
3. Сохранить в БД:
   - email
   - код верификации (захешированный)
   - timestamp создания
   - срок действия кода
   - статус верификации (не верифицирован)
4. Отправить код на email через email сервис
5. Вернуть `verification_token` для последующей проверки кода

### 6. Реализовать метод `verifyCode`

После реализации проверки кода на бэкенде, замените заглушку в методе `verifyCode`.

### 7. Реализовать метод `saveUserToDatabase`

После успешной верификации кода, реализуйте сохранение пользователя в БД.

## Структура БД (рекомендация)

Таблица `email_verifications`:
- `id` (UUID)
- `email` (VARCHAR, UNIQUE)
- `code_hash` (VARCHAR) - захешированный код
- `verification_token` (VARCHAR, UNIQUE)
- `created_at` (TIMESTAMP)
- `expires_at` (TIMESTAMP)
- `verified` (BOOLEAN, default: false)

Таблица `users`:
- `id` (UUID)
- `email` (VARCHAR, UNIQUE)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)
- ... другие поля пользователя

## Безопасность

- Коды верификации должны храниться в БД в захешированном виде
- Используйте HTTPS для всех API запросов
- Добавьте rate limiting для предотвращения спама
- Коды должны иметь ограниченное время жизни (обычно 5-15 минут)
