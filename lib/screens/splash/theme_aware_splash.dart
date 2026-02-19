import 'package:flutter/material.dart';
import 'red_splash.dart';
import 'black_splash.dart';

class ThemeAwareSplash extends StatefulWidget {
  const ThemeAwareSplash({super.key});

  @override
  State<ThemeAwareSplash> createState() => _ThemeAwareSplashState();
}

class _ThemeAwareSplashState extends State<ThemeAwareSplash> {
  @override
  void initState() {
    super.initState();
    
    // Небольшая задержка для определения темы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToCorrectSplash();
    });
  }

  void _navigateToCorrectSplash() {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => isDarkMode 
            ? const BlackSplash()    // темная тема → черный
            : const RedSplash(),      // светлая тема → красный
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}