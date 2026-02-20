import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum PhotoPermissionType { gallery, camera }

class PhotoPermissionScreen extends StatefulWidget {
  final PhotoPermissionType type;

  const PhotoPermissionScreen({super.key, required this.type});

  @override
  State<PhotoPermissionScreen> createState() => _PhotoPermissionScreenState();
}

class _PhotoPermissionScreenState extends State<PhotoPermissionScreen> {
  PermissionStatus? _lastStatus;

  Future<void> _requestPermission() async {
    PermissionStatus status;

    if (widget.type == PhotoPermissionType.camera) {
      status = await Permission.camera.request();
    } else {
      status = await Permission.photos.request();
      if (!(status.isGranted || status.isLimited)) {
        // Fallback для некоторых Android-устройств
        status = await Permission.storage.request();
      }
    }

    if (!mounted) return;

    if (status.isGranted || status.isLimited) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _lastStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCamera = widget.type == PhotoPermissionType.camera;
    final title = isCamera ? 'Разрешите доступ к камере' : 'Разрешите доступ к фото';
    final description = isCamera
        ? 'Приложению нужен доступ к камере, чтобы вы могли сделать фото профиля.'
        : 'Приложению необходим доступ к вашей галерее для загрузки фотографий профиля.';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(),
              // Camera icon
              Icon(
                isCamera ? Icons.photo_camera : Icons.photo_library,
                size: 80,
                color: const Color(0xFF81262B),
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              if (_lastStatus != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Доступ не предоставлен. Вы можете разрешить его в настройках.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              // Next button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _requestPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF81262B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              const SizedBox(height: 16),
              // Back / Settings
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Назад',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              if (_lastStatus?.isPermanentlyDenied == true ||
                  _lastStatus?.isRestricted == true) ...[
                TextButton(
                  onPressed: () async {
                    await openAppSettings();
                  },
                  child: const Text(
                    'Открыть настройки',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF81262B),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
