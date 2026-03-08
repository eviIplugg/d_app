import 'package:flutter/material.dart';
import '../../../firebase/firestore_schema.dart';
import '../../../services/admin_crm_service.dart';

/// Редактирование пользователя админом: верификация, роль, бан.
class AdminUserEditScreen extends StatefulWidget {
  const AdminUserEditScreen({super.key, required this.userId, required this.userData});

  final String userId;
  final Map<String, dynamic> userData;

  @override
  State<AdminUserEditScreen> createState() => _AdminUserEditScreenState();
}

class _AdminUserEditScreenState extends State<AdminUserEditScreen> {
  final AdminCrmService _crm = AdminCrmService();
  late String _verificationStatus;
  late String _role;
  late bool _isBanned;

  @override
  void initState() {
    super.initState();
    _verificationStatus = widget.userData[kUserVerificationStatus]?.toString() ?? 'none';
    _role = widget.userData[kUserRole]?.toString() ?? 'user';
    _isBanned = widget.userData[kUserIsBanned] == true;
  }

  Future<void> _save() async {
    await _crm.updateUserByAdmin(widget.userId, {
      kUserVerificationStatus: _verificationStatus,
      kUserRole: _role,
      kUserIsBanned: _isBanned,
    });
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userData[kUserName]?.toString() ?? '—';
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
        actions: [
          TextButton(onPressed: _save, child: const Text('Сохранить')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Верификация'),
          _dropdown(
            value: _verificationStatus,
            items: const ['none', 'pending', 'verified'],
            labels: const ['Нет', 'На проверке', 'Верифицирован'],
            onChanged: (v) => setState(() => _verificationStatus = v ?? 'none'),
          ),
          const SizedBox(height: 24),
          _section('Роль'),
          _dropdown(
            value: _role,
            items: const ['user', 'organizer', 'admin'],
            labels: const ['Пользователь', 'Организатор', 'Админ'],
            onChanged: (v) => setState(() => _role = v ?? 'user'),
          ),
          const SizedBox(height: 24),
          _section('Блокировка'),
          SwitchListTile(
            value: _isBanned,
            onChanged: (v) => setState(() => _isBanned = v),
            title: const Text('Заблокировать пользователя'),
            subtitle: Text(_isBanned ? 'Доступ запрещён' : 'Доступ разрешён', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required List<String> labels,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: List.generate(items.length, (i) => DropdownMenuItem(value: items[i], child: Text(labels[i]))),
        onChanged: onChanged,
      ),
    );
  }
}
