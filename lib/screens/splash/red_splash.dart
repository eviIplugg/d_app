import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'splash_routes.dart';

class RedSplash extends StatefulWidget {
  const RedSplash({super.key});

  @override
  State<RedSplash> createState() => _RedSplashState();
}

class _RedSplashState extends State<RedSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        navigateAfterSplash(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7F0F0F),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF7F0F0F),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Text(
                    'Ring\nme.',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 56,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF302020),
                      letterSpacing: 0.5,
                      height: 0.92,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}