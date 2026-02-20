import '../../models/auth/email_verification_request.dart';
import '../../models/auth/email_verification_response.dart';

/// Сервис для работы с API аутентификации через email
class EmailAuthService {
  // TODO: Добавить базовый URL API
  // static const String baseUrl = 'https://your-api-url.com/api';
  
  /// Отправка кода верификации на email
  /// 
  /// Этот метод отправляет запрос на сервер для:
  /// 1. Отправки кода верификации на указанный email
  /// 2. Сохранения данных пользователя в БД (email, timestamp, статус верификации)
  /// 
  /// [request] - объект запроса с email пользователя
  /// 
  /// Возвращает [EmailVerificationResponse] с результатом операции
  Future<EmailVerificationResponse> sendVerificationCode(
    EmailVerificationRequest request,
  ) async {
    // TODO: Заменить заглушку на реальный API вызов
    // Пример реализации:
    /*
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
    */

    // ЗАГЛУШКА: Имитация задержки сети
    await Future.delayed(const Duration(seconds: 1));

    // ЗАГЛУШКА: Имитация успешного ответа
    // В реальном приложении здесь будет запись в БД и отправка email через API
    return EmailVerificationResponse(
      success: true,
      message: 'Код отправлен на ${request.email}',
      verificationToken: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      codeExpiresIn: 300, // 5 минут
    );

    // ЗАГЛУШКА: Пример обработки ошибок
    /*
    // Если email уже зарегистрирован:
    if (emailExists) {
      return EmailVerificationResponse(
        success: false,
        message: 'Email уже зарегистрирован',
      );
    }
    
    // Если произошла ошибка сервера:
    return EmailVerificationResponse(
      success: false,
      message: 'Ошибка сервера. Попробуйте позже',
    );
    */
  }

  /// Верификация кода, полученного по email
  /// 
  /// [email] - email пользователя
  /// [code] - код верификации
  /// [verificationToken] - токен, полученный при отправке кода
  /// 
  /// Возвращает true, если код верный, иначе false
  Future<bool> verifyCode({
    required String email,
    required String code,
    required String verificationToken,
  }) async {
    // TODO: Реализовать проверку кода через API
    // Пример:
    /*
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-code'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'code': code,
          'verification_token': verificationToken,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['verified'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
    */

    // ЗАГЛУШКА
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // В реальном приложении здесь будет проверка кода
  }

  /// Сохранение пользователя в БД после успешной верификации
  /// 
  /// [email] - email пользователя
  /// [additionalData] - дополнительные данные пользователя (имя, дата рождения и т.д.)
  /// 
  /// Возвращает ID созданного пользователя
  Future<String> saveUserToDatabase({
    required String email,
    Map<String, dynamic>? additionalData,
  }) async {
    // TODO: Реализовать сохранение пользователя в БД через API
    // Пример:
    /*
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/create'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          ...?additionalData,
        }),
      );

      if (response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return jsonData['user_id'];
      }
      throw Exception('Failed to create user');
    } catch (e) {
      throw Exception('Error saving user: $e');
    }
    */

    // ЗАГЛУШКА: Имитация сохранения в БД
    await Future.delayed(const Duration(milliseconds: 500));
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }
}
