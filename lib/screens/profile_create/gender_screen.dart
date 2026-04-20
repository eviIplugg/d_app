import 'package:flutter/material.dart';
import 'photos_screen.dart';
import '../../models/profile_draft.dart';
import 'profile_flow_steps.dart';

class GenderScreen extends StatefulWidget {
  final ProfileDraft draft;

  const GenderScreen({super.key, required this.draft});

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  String? _selectedGender;
  String? _selectedPreference;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.draft.gender;
    _selectedPreference = widget.draft.preference;
  }

  void _handleNext() {
    if (_selectedGender == null || _selectedPreference == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите пол и предпочтения'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.draft.gender = _selectedGender;
    widget.draft.preference = _selectedPreference;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PhotosScreen(draft: widget.draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : const Color(0xFFF3F3F3);
    final text = isDark ? Colors.white : const Color(0xFF333333);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress bar
            _buildHeader(step: 3, totalSteps: kProfileTotalSteps),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Gender selection
                    Text(
                      'Ваш пол',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGenderChip(
                            label: 'Мужской',
                            isSelected: _selectedGender == 'male',
                            isDark: isDark,
                            onTap: () {
                              setState(() {
                                _selectedGender = 'male';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGenderChip(
                            label: 'Женский',
                            isSelected: _selectedGender == 'female',
                            isDark: isDark,
                            onTap: () {
                              setState(() {
                                _selectedGender = 'female';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    // Preference selection
                    Text(
                      'Кого показывать',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPreferenceChip(
                            label: 'Мужчин',
                            isSelected: _selectedPreference == 'men',
                            isDark: isDark,
                            onTap: () {
                              setState(() {
                                _selectedPreference = 'men';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPreferenceChip(
                            label: 'Женщин',
                            isSelected: _selectedPreference == 'women',
                            isDark: isDark,
                            onTap: () {
                              setState(() {
                                _selectedPreference = 'women';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPreferenceChip(
                            label: 'Всех',
                            isSelected: _selectedPreference == 'everyone',
                            isDark: isDark,
                            onTap: () {
                              setState(() {
                                _selectedPreference = 'everyone';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
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

  Widget _buildGenderChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF81262B) : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF333333)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF81262B) : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF333333)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required int step, required int totalSteps}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : const Color(0xFF333333);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: text,
            ),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          // Progress bar
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
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
          // Step counter
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              '$step/$totalSteps',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
