import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth/auth_service.dart';
import 'phone_input_code_screen.dart';
import '../profile_create/name_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final verificationId = await _authService.sendPhoneCode(_phoneController.text.trim());
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhoneInputCodeScreen(
            phoneNumber: _phoneController.text.trim(),
            verificationId: verificationId,
          ),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Код отправлен на указанный номер'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString();
      String msg;
      if (errStr.contains('BILLING_NOT_ENABLED')) {
        msg = 'Включите биллинг в Google Cloud (console.cloud.google.com) для входа по номеру телефона.';
      } else if (errStr.toLowerCase().contains('unavailable') ||
          errStr.toLowerCase().contains('transient')) {
        msg = 'Сервис верификации временно недоступен. Попробуйте позже или используйте тестовый номер: '
            'Firebase Console → Authentication → Sign-in method → Phone → Phone numbers for testing.';
      } else {
        msg = 'Ошибка: ${errStr.split('\n').first}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Введите номер телефона';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Введите корректный номер';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
                onPressed: () {
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                },
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Введите номер телефона',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\(\)\+]')),
                        ],
                        validator: _validatePhone,
                        decoration: InputDecoration(
                          hintText: '+7 (999) 123-45-67',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                        ),
                        style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF81262B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey.shade400,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Отправить код',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const NameScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF666666),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Пропустить', style: TextStyle(fontSize: 16)),
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
