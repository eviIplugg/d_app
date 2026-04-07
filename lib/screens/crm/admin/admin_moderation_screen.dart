import 'package:flutter/material.dart';
import '../../../firebase/firestore_schema.dart';
import '../../../models/feed_post.dart';
import '../../../services/admin_crm_service.dart';

/// Модерация постов и фото: список на проверке, одобрить/отклонить.
class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  final AdminCrmService _crm = AdminCrmService();
  String _filter = 'pending';
  bool _selectMode = false;
  final Set<String> _selectedPostIds = {};

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) _selectedPostIds.clear();
    });
  }

  void _togglePostSelected(String postId) {
    setState(() {
      if (_selectedPostIds.contains(postId)) _selectedPostIds.remove(postId);
      else _selectedPostIds.add(postId);
    });
  }

  Future<void> _bulkSetStatus(String status) async {
    final ids = _selectedPostIds.toList();
    if (ids.isEmpty) return;
    try {
      await _crm.setPostsModerationStatusBulk(ids, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Готово'), backgroundColor: Colors.green));
      setState(() {
        _selectMode = false;
        _selectedPostIds.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _bulkDelete() async {
    final ids = _selectedPostIds.toList();
    if (ids.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Удалить посты (${ids.length})?'),
        content: const Text('Действие необратимо.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _crm.deletePostsBulk(ids);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Удалено'), backgroundColor: Colors.green));
      setState(() {
        _selectMode = false;
        _selectedPostIds.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _selectMode ? 'Выбрано: ${_selectedPostIds.length}' : 'Модерация',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
        actions: [
          IconButton(
            tooltip: _selectMode ? 'Отменить выбор' : 'Выбрать несколько',
            icon: Icon(_selectMode ? Icons.close : Icons.checklist, color: const Color(0xFF333333)),
            onPressed: _toggleSelectMode,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Color(0xFF333333)),
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'pending', child: Text('На проверке')),
              const PopupMenuItem(value: 'approved', child: Text('Одобренные')),
              const PopupMenuItem(value: 'rejected', child: Text('Отклонённые')),
              const PopupMenuItem(value: 'all', child: Text('Все')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectMode)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _selectedPostIds.isEmpty ? null : () => _bulkSetStatus('approved'),
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: const Text('Одобрить', style: TextStyle(color: Colors.green)),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _selectedPostIds.isEmpty ? null : () => _bulkSetStatus('rejected'),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Отклонить', style: TextStyle(color: Colors.red)),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Удалить',
                    onPressed: _selectedPostIds.isEmpty ? null : _bulkDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder(
        stream: _filter == 'all'
            ? _crm.streamPostsForModeration(limit: 80)
            : _crm.streamPostsForModeration(status: _filter, limit: 80),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF81262B)));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Нет постов для модерации', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final post = FeedPost.fromFirestore(doc);
              final status = doc.data()[kPostModerationStatus]?.toString() ?? 'pending';
              final selected = _selectedPostIds.contains(post.id);
              return _PostModerationCard(
                post: post,
                status: status,
                selectMode: _selectMode,
                selected: selected,
                onToggleSelected: () => _togglePostSelected(post.id),
                onApprove: () => _crm.setPostModerationStatus(post.id, 'approved'),
                onReject: () => _crm.setPostModerationStatus(post.id, 'rejected'),
                onDelete: () => _crm.deletePost(post.id),
              );
            },
          );
        },
      ),
          ),
        ],
      ),
    );
  }
}

class _PostModerationCard extends StatelessWidget {
  final FeedPost post;
  final String status;
  final bool selectMode;
  final bool selected;
  final VoidCallback onToggleSelected;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const _PostModerationCard({
    required this.post,
    required this.status,
    required this.selectMode,
    required this.selected,
    required this.onToggleSelected,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = post.displayPhotoUrls.isNotEmpty ? post.displayPhotoUrls.first : null;
    final isDataUrl = photoUrl != null && photoUrl.startsWith('data:');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectMode)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
              child: Row(
                children: [
                  Checkbox(value: selected, onChanged: (_) => onToggleSelected()),
                  const Text('Выбрать'),
                ],
              ),
            ),
          if (photoUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: isDataUrl
                  ? Image.network(photoUrl, height: 200, width: double.infinity, fit: BoxFit.cover)
                  : Image.network(
                      photoUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                    ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Автор: ${post.authorId}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                if (post.caption.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(post.caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _statusChip(status),
                    const Spacer(),
                    if (!selectMode && status == 'pending') ...[
                      TextButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 18, color: Colors.red),
                        label: const Text('Отклонить', style: TextStyle(color: Colors.red)),
                      ),
                      TextButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check, size: 18, color: Colors.green),
                        label: const Text('Одобрить', style: TextStyle(color: Colors.green)),
                      ),
                    ],
                    if (!selectMode)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Удалить пост?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
                                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (ok == true) onDelete();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String s) {
    Color color = Colors.orange;
    String label = 'На проверке';
    if (s == 'approved') {
      color = Colors.green;
      label = 'Одобрен';
    } else if (s == 'rejected') {
      color = Colors.red;
      label = 'Отклонён';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
