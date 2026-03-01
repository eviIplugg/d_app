import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth/auth_service.dart';
import 'auth_options_screen.dart';
import '../profile_create/name_screen.dart';

class PhoneInputCodeScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const PhoneInputCodeScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<PhoneInputCodeScreen> createState() => _PhoneInputCodeScreenState();
}

class _PhoneInputCodeScreenState extends State<PhoneInputCodeScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  static const int _resendCooldownSeconds = 59;
  int _resendSecondsLeft = _resendCooldownSeconds;
  final AuthService _authService = AuthService();
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  void _startResendCooldown() {
    _resendSecondsLeft = _resendCooldownSeconds;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSecondsLeft--);
      return _resendSecondsLeft > 0;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '').split('').take(6).toList();
      for (var i = 0; i < digits.length && index + i < 6; i++) {
        _controllers[index + i].text = digits[i];
        if (index + i < 5) _focusNodes[index + i + 1].requestFocus();
      }
      if (digits.length == 6) _submitCode();
      return;
    }
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _submitCode();
      }
    } else {
      if (index > 0) _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _submitCode() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) return;

    setState(() => _isVerifying = true);
    try {
      await _authService.signInWithPhoneCode(widget.verificationId, code);
      await _authService.saveOrUpdateUser(
        uid: _authService.currentUserId!,
        authProvider: 'phone',
        phoneNumber: widget.phoneNumber,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NameScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Неверный код или ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _resendCode() {
    if (_resendSecondsLeft > 0) return;
    _authService.sendPhoneCode(widget.phoneNumber).then((_) {
      if (mounted) {
        _startResendCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Код отправлен повторно')),
        );
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    });
  }

  String get _resendLabel {
    if (_resendSecondsLeft > 0) {
      final m = _resendSecondsLeft ~/ 60;
      final s = _resendSecondsLeft % 60;
      return 'Отправить код повторно (${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')})';
    }
    return 'Отправить код повторно';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
                onPressed: () {
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Введите код из SMS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 44,
                    height: 52,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF81262B), width: 2)),
                      ),
                      onChanged: (value) => _onCodeChanged(index, value),
                    ),
                  );
                }),
              ),
            ),
            if (_isVerifying)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF81262B))),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _resendCode,
                    child: Text(
                      _resendLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: _resendSecondsLeft > 0 ? Colors.grey : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthOptionsScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Другой способ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
