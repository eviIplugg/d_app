import 'package:flutter/material.dart';
import 'email_input_screen.dart';

class AuthOptionsScreen extends StatelessWidget {
  const AuthOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Stack(
          children: [
            // Back button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    const Text(
                      'Регистрация',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Email button
                    _AuthButton(
                      text: 'Email',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmailInputScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // VKontakte button
                    _IconOnlyButton(
                      icon: _VKLogo(),
                      onPressed: () {},
                    ),
                    const SizedBox(height: 16),
                    // Yandex ID button
                    _IconOnlyButton(
                      icon: _YandexLogo(),
                      onPressed: () {},
                    ),
                    const SizedBox(height: 16),
                    // Google button
                    _IconOnlyButton(
                      icon: _GoogleLogo(),
                      onPressed: () {},
                    ),
                    const SizedBox(height: 16),
                    // Login button
                    _AuthButton(text: 'Login', onPressed: () {}),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _AuthButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconOnlyButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;

  const _IconOnlyButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

class _VKLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Оригинальный размер: 115x20, масштабируем для UI
    const double originalWidth = 115;
    const double originalHeight = 20;
    const double uiHeight = 20; // Высота для UI
    final double uiWidth = (originalWidth / originalHeight) * uiHeight;

    return Image.asset(
      'assets/images/registration_icons/vk.png',
      width: uiWidth,
      height: uiHeight,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback если изображение не найдено
        debugPrint('Error loading VK logo: $error');
        return Container(
          width: uiWidth,
          height: uiHeight,
          color: Colors.grey.shade300,
          child: const Center(
            child: Text(
              'VK',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}

class _YandexLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Оригинальный размер: 85x19, масштабируем для UI
    const double originalWidth = 85;
    const double originalHeight = 19;
    const double uiHeight = 19; // Высота для UI
    final double uiWidth = (originalWidth / originalHeight) * uiHeight;

    return Image.asset(
      'assets/images/registration_icons/yandex.png',
      width: uiWidth,
      height: uiHeight,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback если изображение не найдено
        debugPrint('Error loading Yandex logo: $error');
        return Container(
          width: uiWidth,
          height: uiHeight,
          color: Colors.grey.shade300,
          child: const Center(
            child: Text(
              'Я',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Оригинальный размер: 65x22, масштабируем для UI
    const double originalWidth = 65;
    const double originalHeight = 22;
    const double uiHeight = 22; // Высота для UI
    final double uiWidth = (originalWidth / originalHeight) * uiHeight;

    return Image.asset(
      'assets/images/registration_icons/google.png',
      width: uiWidth,
      height: uiHeight,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback если изображение не найдено
        debugPrint('Error loading Google logo: $error');
        return Container(
          width: uiWidth,
          height: uiHeight,
          color: Colors.grey.shade300,
          child: const Center(
            child: Text(
              'G',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}
