import 'package:flutter/material.dart';
import 'main_app_shell.dart';

/// Окно подгрузки: «Подбираем для вас пользователей» — показывается перед главным экраном с лентой.
class FeedLoadingScreen extends StatefulWidget {
  const FeedLoadingScreen({super.key});

  @override
  State<FeedLoadingScreen> createState() => _FeedLoadingScreenState();
}

class _FeedLoadingScreenState extends State<FeedLoadingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainAppShell()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81262B)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Подбираем для вас',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'пользователей',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
