/// Модель ответа от API при отправке кода верификации
class EmailVerificationResponse {
  final bool success;
  final String? message;
  final String? verificationToken; // Токен для последующей верификации кода
  final int? codeExpiresIn; // Время жизни кода в секундах

  EmailVerificationResponse({
    required this.success,
    this.message,
    this.verificationToken,
    this.codeExpiresIn,
  });

  /// Создание из JSON ответа сервера
  factory EmailVerificationResponse.fromJson(Map<String, dynamic> json) {
    return EmailVerificationResponse(
      success: json['success'] ?? false,
      message: json['message'],
      verificationToken: json['verification_token'],
      codeExpiresIn: json['code_expires_in'],
    );
  }
}
