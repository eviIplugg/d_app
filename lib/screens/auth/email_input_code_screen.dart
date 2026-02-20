import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_options_screen.dart';
// TEMP: Временный импорт для пропуска регистрации
import '../profile_create/name_screen.dart';

class EmailInputCodeScreen extends StatefulWidget {
  final String email;
  final String? verificationToken;

  const EmailInputCodeScreen({
    super.key,
    required this.email,
    this.verificationToken,
  });

  @override
  State<EmailInputCodeScreen> createState() => _EmailInputCodeScreenState();
}

class _EmailInputCodeScreenState extends State<EmailInputCodeScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  static const int _resendCooldownSeconds = 59;
  int _resendSecondsLeft = _resendCooldownSeconds;

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
      setState(() {
        _resendSecondsLeft--;
      });
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
      // Вставка из буфера
      final digits = value.replaceAll(RegExp(r'\D'), '').split('').take(6).toList();
      for (var i = 0; i < digits.length && index + i < 6; i++) {
        _controllers[index + i].text = digits[i];
        if (index + i < 5) {
          _focusNodes[index + i + 1].requestFocus();
        }
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
      // Backspace на пустом поле — перейти к предыдущему
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _submitCode() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) return;
    
    // TEMP: Временная проверка для пропуска регистрации - удалить после тестирования
    if (code == '666666') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NameScreen()),
      );
      return;
    }
    // TEMP END
    
    // TODO: вызвать API верификации кода, затем переход на создание профиля
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (context) => NameScreen()),
    // );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Код: $code')),
    );
  }

  void _resendCode() {
    if (_resendSecondsLeft > 0) return;
    // TODO: повторная отправка кода через API
    _startResendCooldown();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Код отправлен повторно')),
    );
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
            // Back button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            // Title — чёрный текст
            const Text(
              'Введите код из Email',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 48),
            // 6 полей кода
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF81262B), width: 2),
                          ),
                        ),
                        onChanged: (value) => _onCodeChanged(index, value),
                      ),
                  );
                }),
              ),
            ),
            const Spacer(),
            // Повторная отправка и "Другой способ" — чёрный текст
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
                  // "Another way" button
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthOptionsScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Другой способ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
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
