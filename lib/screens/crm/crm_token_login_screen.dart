import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import '../welcome/welcome_screen.dart';

/// Экран входа в CRM по custom token.
/// Поддерживает:
/// - автологин из query-параметра `?crm_token=...` (или `?token=...`)
/// - ручной ввод токена
class CrmTokenLoginScreen extends StatefulWidget {
  const CrmTokenLoginScreen({super.key});

  @override
  State<CrmTokenLoginScreen> createState() => _CrmTokenLoginScreenState();
}

class _CrmTokenLoginScreenState extends State<CrmTokenLoginScreen> {
  final TextEditingController _tokenCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _attemptedAuto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoSignInFromUrlIfPresent());
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _autoSignInFromUrlIfPresent() async {
    if (_attemptedAuto) return;
    _attemptedAuto = true;
    final token = Uri.base.queryParameters['crm_token'] ?? Uri.base.queryParameters['token'];
    if (token == null || token.trim().isEmpty) return;
    _tokenCtrl.text = token.trim();
    await _signInWithToken(token.trim());
  }

  Future<void> _signInWithToken(String raw) async {
    final token = raw.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Введите токен');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().signInWithCustomToken(token);
      if (!mounted) return;
      // После signIn CrmWebRoot сам переключится на admin gate.
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Не удалось войти по токену: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'CRM вход по токену',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _tokenCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'CRM token',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : () => _signInWithToken(_tokenCtrl.text),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Войти в CRM'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                            ),
                    child: const Text('Обычный вход (телефон / Telegram)'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
