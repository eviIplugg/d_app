import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/profile_draft.dart';

class ProfileCompletionScreen extends StatelessWidget {
  final ProfileDraft draft;

  const ProfileCompletionScreen({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    final name = draft.name.trim().isEmpty ? '!' : ', ${draft.name.trim()}!';
    final mainPhotoPath = draft.photos.isNotEmpty ? draft.photos.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              top: 40,
              left: 20,
              child: Icon(
                Icons.local_florist,
                size: 40,
                color: Colors.orange.shade200,
              ),
            ),
            Positioned(
              top: 120,
              right: 30,
              child: Icon(
                Icons.local_florist,
                size: 30,
                color: Colors.orange.shade200,
              ),
            ),
            Positioned(
              bottom: 200,
              left: 30,
              child: Icon(
                Icons.arrow_upward,
                size: 30,
                color: Colors.orange.shade200,
              ),
            ),
            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Profile picture placeholder
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade300,
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: mainPhotoPath != null && mainPhotoPath.trim().isNotEmpty
                          ? ClipOval(
                              child: Image.file(
                                File(mainPhotoPath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Color(0xFF81262B),
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 60,
                              color: Color(0xFF81262B),
                            ),
                    ),
                    const SizedBox(height: 24),
                    // Congratulations message
                    Text(
                      'Готово$name',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // Start button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Navigate to main app screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Профиль создан! Переход в приложение...'),
                            ),
                          );
                        },
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
                          'Начать знакомства',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF333333)),
                onPressed: () {
                  // TODO: Handle close action
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
