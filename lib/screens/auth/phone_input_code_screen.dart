import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth/auth_service.dart';
import 'auth_options_screen.dart';
import '../../navigation/auth_after_signin.dart';

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
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  static const int _resendCooldownSeconds = 59;
  int _resendSecondsLeft = _resendCooldownSeconds;
  final AuthService _authService = AuthService();
  bool _isVerifying = false;
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
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
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    setState(() => _isVerifying = true);
    try {
      await _authService.signInWithPhoneCode(_verificationId, code);
      await _authService.saveOrUpdateUser(
        uid: _authService.currentUserId!,
        authProvider: 'phone',
        phoneNumber: widget.phoneNumber,
      );
      if (!mounted) return;
      final profile = await _authService.getUserProfile(_authService.currentUserId!);
      if (!mounted) return;
      await AuthAfterSignIn.navigateFromProfile(context, _authService, profile);
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
    _authService.sendPhoneCode(widget.phoneNumber).then((newId) {
      if (mounted) {
        setState(() => _verificationId = newId);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : const Color(0xFFF3F3F3);
    final fg = isDark ? Colors.white : Colors.black;
    final fieldBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final fieldBorder = isDark ? Colors.white24 : Colors.grey.shade400;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF333333)),
                onPressed: () {
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Введите код из SMS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GestureDetector(
                onTap: () => _codeFocusNode.requestFocus(),
                child: Stack(
                  children: [
                    Opacity(
                      opacity: 0.01,
                      child: TextField(
                        controller: _codeController,
                        focusNode: _codeFocusNode,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) {
                          setState(() {});
                          if (_codeController.text.length == 6) {
                            _submitCode();
                          }
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        final chars = _codeController.text.split('');
                        final char = index < chars.length ? chars[index] : '';
                        final selected = _codeFocusNode.hasFocus && index == chars.length.clamp(0, 5);
                        return Container(
                          width: 44,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected ? const Color(0xFF81262B) : fieldBorder,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            char,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: fg),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
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
                        color: _resendSecondsLeft > 0 ? (isDark ? Colors.white38 : Colors.grey) : fg,
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
                    child: Text(
                      'Другой способ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: fg),
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
