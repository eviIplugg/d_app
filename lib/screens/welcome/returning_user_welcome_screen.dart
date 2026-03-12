import 'package:flutter/material.dart';
import '../feed/main_app_shell.dart';

/// Экран «Добро пожаловать» для вернувшегося пользователя (после проверки, что он уже зарегистрирован).
class ReturningUserWelcomeScreen extends StatelessWidget {
  final String userName;

  const ReturningUserWelcomeScreen({
    super.key,
    required this.userName,
  });

  static const Color _accent = Color(0xFF81262B);
  static const Color _textDark = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    final displayName = userName.trim().isEmpty ? 'Пользователь' : userName.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Icon(
                Icons.waving_hand,
                size: 64,
                color: Colors.orange.shade300,
              ),
              const SizedBox(height: 32),
              Text(
                'Добро пожаловать',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainAppShell(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Продолжить',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
