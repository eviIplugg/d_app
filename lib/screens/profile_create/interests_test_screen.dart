import 'package:flutter/material.dart';
import 'profile_completion_screen.dart';
import '../../models/profile_draft.dart';
import 'profile_flow_steps.dart';

class InterestsTestScreen extends StatefulWidget {
  final ProfileDraft draft;

  const InterestsTestScreen({super.key, required this.draft});

  @override
  State<InterestsTestScreen> createState() => _InterestsTestScreenState();
}

class _InterestsTestScreenState extends State<InterestsTestScreen> {
  final Set<String> _selectedInterests = {};

  final List<Map<String, dynamic>> _interests = [
    {'name': 'Спорт', 'icon': Icons.sports_soccer},
    {'name': 'Еда', 'icon': Icons.restaurant},
    {'name': 'Искусство', 'icon': Icons.palette},
    {'name': 'Кино', 'icon': Icons.movie},
    {'name': 'Музыка', 'icon': Icons.music_note},
    {'name': 'Книги', 'icon': Icons.book},
    {'name': 'Путешествия', 'icon': Icons.flight},
    {'name': 'Технологии', 'icon': Icons.computer},
    {'name': 'Другое', 'icon': Icons.more_horiz},
  ];

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  void _handleNext() {
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы один интерес'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileCompletionScreen(draft: widget.draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
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
                  const Expanded(
                    child: Text(
                      'Интересы',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Progress bar
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 8 / kProfileTotalSteps,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF81262B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Question
                    const Text(
                      'Чем вы сейчас увлекаетесь?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Interests grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: _interests.length,
                      itemBuilder: (context, index) {
                        final interest = _interests[index];
                        final isSelected = _selectedInterests.contains(interest['name']);
                        return _buildInterestChip(
                          interest['name'] as String,
                          interest['icon'] as IconData,
                          isSelected,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Selected count
                    Text(
                      'Выбрано ${_selectedInterests.length} ${_selectedInterests.length == 1 ? 'категория' : 'категории'}',
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

  Widget _buildInterestChip(String name, IconData icon, bool isSelected) {
    return InkWell(
      onTap: () => _toggleInterest(name),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF81262B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF81262B) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : const Color(0xFF81262B),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
