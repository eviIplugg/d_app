import 'package:flutter/material.dart';
import 'cultural_dna_test_screen.dart';
import '../../firebase/firestore_schema.dart';
import '../../models/profile_draft.dart';
import '../../services/auth/auth_service.dart';
import '../../services/location_service.dart';
import 'profile_flow_steps.dart';

class GeolocationPermissionScreen extends StatelessWidget {
  final ProfileDraft draft;

  const GeolocationPermissionScreen({super.key, required this.draft});

  Future<void> _enableAndContinue(BuildContext context) async {
    try {
      final loc = await LocationService.getCurrentLocation();
      final auth = AuthService();
      final uid = auth.currentUserId;
      if (uid != null) {
        await auth.updateUserProfile(uid: uid, profileData: {
          kUserGeoLat: loc.lat,
          kUserGeoLng: loc.lng,
          kUserGeoUpdatedAt: DateTime.now(),
        });
      }
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CulturalDNATestScreen(draft: draft),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.orange),
      );
      // Если навсегда запрещено — удобно дать быстрый переход в настройки.
      // Не блокируем флоу: пользователь может нажать «Позже».
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, step: 6, totalSteps: kProfileTotalSteps),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Map icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        size: 60,
                        color: Color(0xFF81262B),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title
                    const Text(
                      'Геолокация отключена',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Text(
                      'Настоящие встречи начинаются рядом.\nРазрешите доступ к вашей локации, чтобы\nувидеть тех, кто рядом с вами.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    // Enable button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _enableAndContinue(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF81262B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Включить геолокацию',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Later button
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CulturalDNATestScreen(draft: draft),
                          ),
                        );
                      },
                      child: const Text(
                        'Позже',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required int step, required int totalSteps}) {
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
