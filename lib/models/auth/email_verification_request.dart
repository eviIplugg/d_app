/// Модель запроса для отправки кода верификации на email
class EmailVerificationRequest {
  final String email;

  EmailVerificationRequest({
    required this.email,
  });

  /// Преобразование в JSON для отправки на сервер
  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}
