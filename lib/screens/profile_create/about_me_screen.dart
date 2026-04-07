import 'package:flutter/material.dart';
import 'geolocation_permission_screen.dart';
import '../../models/profile_draft.dart';
import '../../utils/education_levels.dart';
import '../city_picker_screen.dart';
import 'profile_flow_steps.dart';

class AboutMeScreen extends StatefulWidget {
  final ProfileDraft draft;

  const AboutMeScreen({super.key, required this.draft});

  @override
  State<AboutMeScreen> createState() => _AboutMeScreenState();
}

class _AboutMeScreenState extends State<AboutMeScreen> {
  late final TextEditingController _bioController;
  late String _city;
  late String _educationLevel;
  late String _job;
  late String _university;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.draft.bio);
    _city = widget.draft.city;
    _educationLevel = widget.draft.educationLevel;
    _job = widget.draft.job;
    _university = widget.draft.university;
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  void _handleNext() {
    widget.draft.bio = _bioController.text.trim();
    widget.draft.city = _city.trim();
    widget.draft.job = _job.trim();
    widget.draft.educationLevel = _educationLevel;
    widget.draft.university = _university.trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GeolocationPermissionScreen(draft: widget.draft)),
    );
  }

  Future<void> _editField({
    required String title,
    required String initialValue,
    required ValueChanged<String> onSaved,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Введите значение',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    onSaved(result.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress bar
            _buildHeader(step: 5, totalSteps: kProfileTotalSteps),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Title
                    const Text(
                      'Расскажите о себе',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Bio section
                    const Text(
                      'Био',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _bioController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Расскажите о себе...',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () {
                              // TODO: Open bio editor
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Basic information section
                    const Text(
                      'Основная информация',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Город', _city, () async {
                      final picked = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(builder: (context) => CityPickerScreen(initialCity: _city.isEmpty ? null : _city)),
                      );
                      if (picked != null) setState(() => _city = picked);
                    }),
                    _buildInfoRow('Работа', _job.isEmpty ? 'Добавить' : _job, () {
                      _editField(
                        title: 'Работа',
                        initialValue: _job,
                        onSaved: (v) => setState(() => _job = v),
                      );
                    }),
                    _buildInfoRow('Уровень образования', educationLevelLabel(_educationLevel) ?? 'Выберите', () async {
                      final chosen = await showModalBottomSheet<String>(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final e in kEducationLevels)
                                ListTile(
                                  title: Text(e.value),
                                  onTap: () => Navigator.pop(ctx, e.key),
                                ),
                            ],
                          ),
                        ),
                      );
                      if (chosen != null) setState(() => _educationLevel = chosen);
                    }),
                    _buildInfoRow('Название вуза', _university.isEmpty ? 'Добавить' : _university, () {
                      _editField(
                        title: 'Название вуза',
                        initialValue: _university,
                        onSaved: (v) => setState(() => _university = v),
                      );
                    }),
                    const SizedBox(height: 16),
                    Text(
                      'Больше деталей вы сможете внести в настройках профиля',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Next button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF81262B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Далее',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, VoidCallback onTap) {
    final displayValue = value.trim().isEmpty ? 'Добавить' : value;
    final isPlaceholder = value.trim().isEmpty;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            Row(
              children: [
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isPlaceholder ? Colors.grey.shade500 : const Color(0xFF333333),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({required int step, required int totalSteps}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: step / totalSteps,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF81262B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              '$step/$totalSteps',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
