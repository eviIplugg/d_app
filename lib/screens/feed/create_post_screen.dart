import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/post_service.dart';

/// Экран создания поста: выбор фото, подпись, опционально поля активности.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final PostService _postService = PostService();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  List<String> _photoPaths = [];
  bool _isActivity = false;
  bool _venueVerified = false;
  bool _loading = false;
  String? _error;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    if (!mounted) return;
    setState(() {
      for (final f in files) {
        if (f.path.isNotEmpty) _photoPaths.add(f.path);
      }
    });
  }

  void _removePhoto(int index) {
    setState(() => _photoPaths.removeAt(index));
  }

  Future<void> _publish() async {
    if (_photoPaths.isEmpty) {
      setState(() => _error = 'Добавьте хотя бы одно фото');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final postId = await _postService.createPost(
        photoFilePaths: _photoPaths,
        caption: _captionController.text.trim(),
        type: _isActivity ? 'activity' : 'personal',
        activityTitle: _isActivity ? _titleController.text.trim().isEmpty ? null : _titleController.text.trim() : null,
        activityDate: _isActivity ? _dateController.text.trim().isEmpty ? null : _dateController.text.trim() : null,
        activityVenue: _isActivity ? _venueController.text.trim().isEmpty ? null : _venueController.text.trim() : null,
        activityVenueVerified: _isActivity && _venueVerified,
        activityPrice: _isActivity ? _priceController.text.trim().isEmpty ? null : _priceController.text.trim() : null,
        activityRating: _isActivity ? _ratingController.text.trim().isEmpty ? null : _ratingController.text.trim() : null,
        activityTag: _isActivity ? _tagController.text.trim().isEmpty ? null : _tagController.text.trim() : null,
      );
      if (!mounted) return;
      if (postId != null) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _loading = false;
          _error = 'Не удалось опубликовать';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _titleController.dispose();
    _dateController.dispose();
    _venueController.dispose();
    _priceController.dispose();
    _ratingController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fieldFill = cs.surfaceContainerHighest;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Новый пост',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _publish,
            child: _loading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                  )
                : Text('Опубликовать', style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Фото
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Icon(Icons.add_photo_alternate, size: 40, color: cs.onSurfaceVariant),
                  ),
                ),
                ...List.generate(_photoPaths.length, (i) {
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(_photoPaths[i])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => _removePhoto(i),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Подпись
          TextField(
            controller: _captionController,
            maxLines: 3,
            style: TextStyle(color: cs.onSurface),
            decoration: InputDecoration(
              labelText: 'Подпись',
              hintText: 'Текст публикации...',
              filled: true,
              fillColor: fieldFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          // Тип: личный / активность
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Личный пост'),
                  selected: !_isActivity,
                  onSelected: (v) => setState(() => _isActivity = !v),
                  selectedColor: cs.primary.withValues(alpha: 0.28),
                  backgroundColor: cs.surfaceContainerHigh,
                  side: BorderSide(color: cs.outlineVariant),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Активность'),
                  selected: _isActivity,
                  onSelected: (v) => setState(() => _isActivity = v),
                  selectedColor: cs.primary.withValues(alpha: 0.28),
                  backgroundColor: cs.surfaceContainerHigh,
                  side: BorderSide(color: cs.outlineVariant),
                ),
              ),
            ],
          ),
          if (_isActivity) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Заголовок',
                hintText: 'Например: Праздник бразильской кухни',
                filled: true,
                fillColor: fieldFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dateController,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Дата и время',
                hintText: 'Пт 22:00',
                filled: true,
                fillColor: fieldFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _venueController,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Место',
                hintText: 'Bukowski Grill',
                filled: true,
                fillColor: fieldFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _venueVerified,
              onChanged: (v) => setState(() => _venueVerified = v ?? false),
              title: Text('Место верифицировано', style: TextStyle(fontSize: 14, color: cs.onSurface)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Цена',
                hintText: '1500 ₽',
                filled: true,
                fillColor: fieldFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ratingController,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Рейтинг',
                hintText: '5.0',
                filled: true,
                fillColor: fieldFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagController,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Тег',
                hintText: 'Открыто',
                filled: true,
                fillColor: fieldFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: cs.error, fontSize: 14)),
          ],
        ],
      ),
    );
  }
}
