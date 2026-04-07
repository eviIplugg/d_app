import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../firebase/firestore_schema.dart';
import '../../../models/feed_post.dart';
import '../../../services/admin_crm_service.dart';

class AdminUserPostsScreen extends StatefulWidget {
  const AdminUserPostsScreen({super.key, required this.userId});
  final String userId;

  @override
  State<AdminUserPostsScreen> createState() => _AdminUserPostsScreenState();
}

class _AdminUserPostsScreenState extends State<AdminUserPostsScreen> {
  final AdminCrmService _crm = AdminCrmService();
  bool _selectMode = false;
  final Set<String> _selected = {};
  /// Без orderBy в запросе — не требует составного индекса; сортировка на клиенте.
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _loadPosts();
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) _selected.clear();
    });
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) _selected.remove(id);
      else _selected.add(id);
    });
  }

  Future<void> _bulkDelete() async {
    if (_selected.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Удалить посты (${_selected.length})?'),
        content: const Text('Действие необратимо.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _crm.deletePostsBulk(_selected.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Удалено'), backgroundColor: Colors.green));
      setState(() {
        _selectMode = false;
        _selected.clear();
        _postsFuture = _loadPosts();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadPosts() async {
    final snap = await FirebaseFirestore.instance
        .collection(kPostsCollection)
        .where(kPostAuthorId, isEqualTo: widget.userId)
        .get();
    final docs = [...snap.docs]..sort((a, b) {
        final ta = a.data()[kPostCreatedAt];
        final tb = b.data()[kPostCreatedAt];
        final da = ta is Timestamp ? ta.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
        final db = tb is Timestamp ? tb.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
    return docs;
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
          _selectMode ? 'Выбрано: ${_selected.length}' : 'Посты',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
        actions: [
          IconButton(
            tooltip: _selectMode ? 'Отменить выбор' : 'Выбрать несколько',
            icon: Icon(_selectMode ? Icons.close : Icons.checklist, color: const Color(0xFF333333)),
            onPressed: _toggleSelectMode,
          ),
          if (_selectMode)
            IconButton(
              tooltip: 'Удалить выбранные',
              onPressed: _selected.isEmpty ? null : _bulkDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
            ),
        ],
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF81262B)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
                    const SizedBox(height: 16),
                    Text('Ошибка загрузки: ${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 12),
                    Text(
                      'Если ошибка про индекс — выполните: firebase deploy --only firestore:indexes',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }
          final docs = snapshot.data ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Постов нет'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final post = FeedPost.fromFirestore(docs[index]);
              final photoUrl = post.displayPhotoUrls.isNotEmpty ? post.displayPhotoUrls.first : null;
              final selected = _selected.contains(post.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: _selectMode
                      ? Checkbox(value: selected, onChanged: (_) => _toggle(post.id))
                      : (photoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(photoUrl, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                            )
                          : const Icon(Icons.photo)),
                  title: Text(post.caption.isEmpty ? '(без подписи)' : post.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${post.type} · ${post.createdAt.toLocal()}'.split('.').first, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  trailing: _selectMode
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.delete_outline),
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
                            if (ok == true) {
                              await _crm.deletePost(post.id);
                              if (mounted) setState(() => _postsFuture = _loadPosts());
                            }
                          },
                        ),
                  onTap: _selectMode ? () => _toggle(post.id) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

