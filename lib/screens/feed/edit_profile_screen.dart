import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../firebase/firestore_schema.dart';
import '../../services/auth/auth_service.dart';

/// Экран редактирования профиля: имя, дата рождения, пол, кого ищу, город, о себе, работа, образование, цель.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _jobController = TextEditingController();
  final _educationController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  DateTime? _birthdate;
  String _gender = 'male';
  String _preference = 'women';
  String _relationshipGoal = 'friendship';

  static const Color _accent = Color(0xFF81262B);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUserId;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final profile = await _auth.getUserProfile(uid);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (profile != null) {
        _nameController.text = profile[kUserName]?.toString() ?? '';
        _cityController.text = profile[kUserCity]?.toString() ?? '';
        _bioController.text = profile[kUserBio]?.toString() ?? '';
        _jobController.text = profile[kUserJob]?.toString() ?? '';
        _educationController.text = profile[kUserEducation]?.toString() ?? '';
        final b = profile[kUserBirthdate];
        if (b is Timestamp) _birthdate = b.toDate();
        else if (b is DateTime) _birthdate = b;
        _gender = profile[kUserGender]?.toString() ?? 'male';
        _preference = profile[kUserPreference]?.toString() ?? 'women';
        _relationshipGoal = profile[kUserRelationshipGoal]?.toString() ?? 'friendship';
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _birthdate == null) {
      if (_birthdate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Укажите дату рождения'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    final uid = _auth.currentUserId;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await _auth.updateUserProfile(uid: uid, profileData: {
        kUserName: _nameController.text.trim(),
        kUserBirthdate: _birthdate!,
        kUserGender: _gender,
        kUserPreference: _preference,
        kUserCity: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        kUserBio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        kUserJob: _jobController.text.trim().isEmpty ? null : _jobController.text.trim(),
        kUserEducation: _educationController.text.trim().isEmpty ? null : _educationController.text.trim(),
        kUserRelationshipGoal: _relationshipGoal,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль сохранён'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _jobController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F3F3),
        appBar: AppBar(backgroundColor: Colors.white, title: const Text('Редактирование профиля', style: TextStyle(color: Color(0xFF333333)))),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Color(0xFF333333)), onPressed: () => Navigator.pop(context)),
        title: const Text('Редактирование профиля', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: _accent)) : const Text('Сохранить', style: TextStyle(fontWeight: FontWeight.w600, color: _accent)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Имя'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Введите имя' : null,
            ),
            const SizedBox(height: 16),
            _sectionTitle('Дата рождения'),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _birthdate ?? DateTime(2000, 1, 1),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _birthdate = date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Text(_birthdate != null ? '${_birthdate!.day.toString().padLeft(2, '0')}.${_birthdate!.month.toString().padLeft(2, '0')}.${_birthdate!.year}' : 'Выберите дату', style: TextStyle(fontSize: 16, color: _birthdate != null ? const Color(0xFF333333) : Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Пол'),
            _choiceRow(['Мужской', 'Женский', 'Другой'], ['male', 'female', 'other'], _gender, (v) => setState(() => _gender = v)),
            const SizedBox(height: 20),
            _sectionTitle('Кого ищу'),
            _choiceRow(['Мужчин', 'Женщин', 'Всех'], ['men', 'women', 'everyone'], _preference, (v) => setState(() => _preference = v)),
            const SizedBox(height: 20),
            _sectionTitle('Цель знакомства'),
            _choiceRow(['Дружба', 'Общение', 'Отношения'], ['friendship', 'communication', 'relationship'], _relationshipGoal, (v) => setState(() => _relationshipGoal = v)),
            const SizedBox(height: 16),
            TextFormField(controller: _cityController, decoration: _inputDecoration('Город')),
            const SizedBox(height: 16),
            TextFormField(controller: _bioController, decoration: _inputDecoration('О себе'), maxLines: 4),
            const SizedBox(height: 16),
            TextFormField(controller: _jobController, decoration: _inputDecoration('Работа')),
            const SizedBox(height: 16),
            TextFormField(controller: _educationController, decoration: _inputDecoration('Образование')),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
    );
  }

  Widget _choiceRow(List<String> labels, List<String> values, String current, ValueChanged<String> onSelected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = values[i] == current;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
              child: FilterChip(
                label: Text(labels[i], style: TextStyle(fontSize: 13)),
                selected: selected,
                onSelected: (_) => onSelected(values[i]),
                selectedColor: _accent.withValues(alpha: 0.3),
                checkmarkColor: _accent,
              ),
            ),
          );
        }),
      ),
    );
  }
}
