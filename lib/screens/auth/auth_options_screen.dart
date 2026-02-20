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
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF333333),
                ),
                onPressed: () => Navigator.of(context).pop(),
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
                    _AuthButton(
                      text: 'вконтакте',
                      onPressed: () {},
                      leading: _VKLogo(),
                    ),
                    const SizedBox(height: 16),
                    // Yandex ID button
                    _AuthButton(
                      text: 'Яндекс ID',
                      onPressed: () {},
                      trailing: _YandexLogo(),
                    ),
                    const SizedBox(height: 16),
                    // Google button
                    _AuthButton(
                      text: 'Google',
                      onPressed: () {},
                      leading: _GoogleLogo(),
                    ),
                    const SizedBox(height: 16),
                    // Login button
                    _AuthButton(
                      text: 'Login',
                      onPressed: () {},
                    ),
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
  final Widget? leading;
  final Widget? trailing;

  const _AuthButton({
    required this.text,
    required this.onPressed,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            child: Row(
              mainAxisAlignment: leading != null || trailing != null
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 12),
                ],
                if (leading == null && trailing == null)
                  Expanded(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
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
    return Image.asset(
      'assets/images/registration_icons/vk.png',
      width: 24,
      height: 24,
      fit: BoxFit.contain,
    );
  }
}

class _YandexLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/registration_icons/yandex.png',
      width: 24,
      height: 24,
      fit: BoxFit.contain,
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/registration_icons/google.png',
      width: 24,
      height: 24,
      fit: BoxFit.contain,
    );
  }
}
