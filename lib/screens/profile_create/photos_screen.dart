import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'about_me_screen.dart';
import '../../models/profile_draft.dart';
import 'photo_crop_screen.dart';
import 'photo_permission_screen.dart';
import 'photo_preview_screen.dart';
import 'profile_flow_steps.dart';

class PhotosScreen extends StatefulWidget {
  final ProfileDraft draft;

  const PhotosScreen({super.key, required this.draft});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final int _mainPhotoIndex = 0;
  final ImagePicker _picker = ImagePicker();

  Future<void> _handlePhotoTap(int index) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Выбрать из галереи'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Сделать фото'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final ok = await _ensurePermissionForSource(source);
    if (!ok) return;

    if (!mounted) return;

    XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2048,
    );

    // Если камера отменена, просто выходим
    if (picked == null) return;

    File file = File(picked.path);

    // Для камеры показываем предпросмотр "Использовать фото"
    if (!mounted) return;
    if (source == ImageSource.camera) {
      final used = await Navigator.push<File?>(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoPreviewScreen(imageFile: file),
        ),
      );
      if (used == null) return;
      file = used;
    }

    // Экран обрезки (пока возвращает тот же файл)
    if (!mounted) return;
    final cropped = await Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoCropScreen(imageFile: file),
      ),
    );
    if (cropped != null) {
      file = cropped;
    }

    setState(() {
      widget.draft.photos[index] = file.path;
    });
  }

  Future<bool> _ensurePermissionForSource(ImageSource source) async {
    if (source == ImageSource.camera) {
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus.isGranted) return true;

      if (!mounted) return false;
      final res = await Navigator.push<bool?>(
        context,
        MaterialPageRoute(
          builder: (context) => const PhotoPermissionScreen(type: PhotoPermissionType.camera),
        ),
      );
      return res == true;
    }

    final photosStatus = await Permission.photos.request();
    if (photosStatus.isGranted || photosStatus.isLimited) return true;

    // На некоторых Android-устройствах может потребоваться storage
    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) return true;

    if (!mounted) return false;
    final res = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (context) => const PhotoPermissionScreen(type: PhotoPermissionType.gallery),
      ),
    );
    return res == true;
  }

  void _handleMainPhotoEdit() {
    _handlePhotoTap(_mainPhotoIndex);
  }

  void _handleNext() {
    final photoCount = widget.draft.photos.where((photo) => photo != null).length;
    if (photoCount < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте минимум 3 фотографии'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AboutMeScreen(draft: widget.draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress bar
            _buildHeader(step: 4, totalSteps: kProfileTotalSteps),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Title
                    const Text(
                      'Добавьте минимум 3 фотографии',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF81262B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      'Фото помогают начать историю — добавьте свое, чтобы привлечь внимание.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Photo grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        return _buildPhotoPlaceholder(index);
                      },
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(int index) {
    final photoPath = widget.draft.photos[index];
    final hasPhoto = photoPath != null && photoPath.isNotEmpty;
    final isMainPhoto = index == _mainPhotoIndex;

    return GestureDetector(
      onTap: () => _handlePhotoTap(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Photo or placeholder
            if (hasPhoto)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(photoPath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Color(0xFF81262B),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Center(
                child: Icon(
                  Icons.camera_alt,
                  size: 32,
                  color: Colors.grey.shade400,
                ),
              ),
            // Main photo label
            if (isMainPhoto)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Главное фото',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            // Edit button for main photo
            if (isMainPhoto)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _handleMainPhotoEdit,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF333333),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
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
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
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
          // Step counter
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
