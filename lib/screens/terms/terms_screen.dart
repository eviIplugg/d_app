import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/auth_options_screen.dart';

/// Placeholder URLs — replace with your real policy and agreement pages.
const String _privacyPolicyUrl = 'https://example.com/privacy';
const String _userAgreementUrl = 'https://example.com/terms';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  static const Color _darkRed = Color(0xFF81262B);

  bool _privacyAccepted = false;
  bool _agreementAccepted = false;

  bool get _canContinue => _privacyAccepted && _agreementAccepted;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Center(
                child: Image.asset(
                  'assets/images/terms.png',
                  fit: BoxFit.contain,
                  height: 200,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Нужно принять условия\nпользования',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _CheckRow(
                value: _privacyAccepted,
                onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
                label: 'Я принимаю ',
                linkText: 'Политику конфиденциальности',
                onTapLink: () => _openUrl(_privacyPolicyUrl),
              ),
              const SizedBox(height: 20),
              _CheckRow(
                value: _agreementAccepted,
                onChanged: (v) => setState(() => _agreementAccepted = v ?? false),
                label: 'Я принимаю ',
                linkText: 'Пользовательское соглашение',
                linkSuffix: ' и подтверждаю, что мне исполнилось 18 лет',
                onTapLink: () => _openUrl(_userAgreementUrl),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canContinue
                        ? () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AuthOptionsScreen(),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkRed,
                      disabledBackgroundColor: _darkRed.withValues(alpha: 0.5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Принять и продолжить',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.linkText,
    this.linkSuffix = '',
    required this.onTapLink,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final String linkText;
  final String linkSuffix;
  final VoidCallback onTapLink;

  static const Color _darkRed = Color(0xFF81262B);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: _darkRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: label),
                  TextSpan(
                    text: linkText,
                    style: const TextStyle(
                      color: _darkRed,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = onTapLink,
                  ),
                  TextSpan(text: linkSuffix),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
