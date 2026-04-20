import 'package:flutter/material.dart';

import '../../models/feed_post.dart';
import '../../services/post_service.dart';

/// Редактирование текста поста (подпись и поля активности). Фото не меняются.
class EditPostScreen extends StatefulWidget {
  const EditPostScreen({super.key, required this.post});

  final FeedPost post;

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final PostService _postService = PostService();
  late final TextEditingController _captionController;
  late final TextEditingController _titleController;
  late final TextEditingController _dateController;
  late final TextEditingController _venueController;
  late final TextEditingController _priceController;
  late final TextEditingController _ratingController;
  late final TextEditingController _tagController;
  late bool _venueVerified;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    _captionController = TextEditingController(text: p.caption);
    _titleController = TextEditingController(text: p.activityTitle ?? '');
    _dateController = TextEditingController(text: p.activityDate ?? '');
    _venueController = TextEditingController(text: p.activityVenue ?? '');
    _priceController = TextEditingController(text: p.activityPrice ?? '');
    _ratingController = TextEditingController(text: p.activityRating ?? '');
    _tagController = TextEditingController(text: p.activityTag ?? '');
    _venueVerified = p.activityVenueVerified;
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

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = widget.post;
      await _postService.updatePost(
        postId: p.id,
        caption: _captionController.text.trim(),
        activityTitle: p.isActivity ? _titleController.text.trim() : null,
        activityDate: p.isActivity ? _dateController.text.trim() : null,
        activityVenue: p.isActivity ? _venueController.text.trim() : null,
        activityVenueVerified: p.isActivity ? _venueVerified : null,
        activityPrice: p.isActivity ? _priceController.text.trim() : null,
        activityRating: p.isActivity ? _ratingController.text.trim() : null,
        activityTag: p.isActivity ? _tagController.text.trim() : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urls = widget.post.displayPhotoUrls;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Редактировать пост'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                  )
                : Text('Сохранить', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final u = urls[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: u.startsWith('data:')
                        ? const ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.image))
                        : Image.network(u, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _captionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Подпись',
              border: OutlineInputBorder(),
            ),
          ),
          if (widget.post.isActivity) ...[
            const SizedBox(height: 12),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Заголовок', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _dateController, decoration: const InputDecoration(labelText: 'Дата и время', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _venueController, decoration: const InputDecoration(labelText: 'Место', border: OutlineInputBorder())),
            CheckboxListTile(
              value: _venueVerified,
              onChanged: (v) => setState(() => _venueVerified = v ?? false),
              title: const Text('Место верифицировано'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Цена', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _ratingController, decoration: const InputDecoration(labelText: 'Рейтинг', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _tagController, decoration: const InputDecoration(labelText: 'Тег', border: OutlineInputBorder())),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
