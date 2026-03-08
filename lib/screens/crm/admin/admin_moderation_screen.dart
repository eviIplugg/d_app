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
        title: const Text('Модерация', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
        actions: [
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
      body: StreamBuilder(
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
              return _PostModerationCard(
                post: post,
                status: status,
                onApprove: () => _crm.setPostModerationStatus(post.id, 'approved'),
                onReject: () => _crm.setPostModerationStatus(post.id, 'rejected'),
                onDelete: () => _crm.deletePost(post.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _PostModerationCard extends StatelessWidget {
  final FeedPost post;
  final String status;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const _PostModerationCard({
    required this.post,
    required this.status,
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
                    if (status == 'pending') ...[
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
