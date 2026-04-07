import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../firebase/firestore_schema.dart';
import '../../../services/admin_crm_service.dart';
import 'admin_user_detail_screen.dart';

/// Управление пользователями: список, верификация, роли, блокировка.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminCrmService _crm = AdminCrmService();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _users = [];
  DocumentSnapshot? _lastDoc;
  bool _loading = false;
  bool _selectMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    setState(() => _loading = true);
    final snap = await _crm.getUsers(startAfter: _lastDoc, limit: 30);
    if (!mounted) return;
    setState(() {
      _users.addAll(snap.docs);
      if (snap.docs.isNotEmpty) _lastDoc = snap.docs.last;
      _loading = false;
    });
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) _selectedIds.clear();
    });
  }

  void _toggleSelected(String uid) {
    setState(() {
      if (_selectedIds.contains(uid)) _selectedIds.remove(uid);
      else _selectedIds.add(uid);
    });
  }

  void _selectAllLoaded() {
    setState(() {
      for (final d in _users) {
        _selectedIds.add(d.id);
      }
    });
  }

  Future<void> _bulkUpdateUsers(Map<String, dynamic> updates) async {
    final ids = _selectedIds.toList();
    if (ids.isEmpty) return;
    try {
      await _crm.updateUsersByAdminBulk(ids, updates);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Готово'), backgroundColor: Colors.green));
      setState(() {
        _selectMode = false;
        _selectedIds.clear();
        _users = [];
        _lastDoc = null;
      });
      await _loadMore();
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
          _selectMode ? 'Выбрано: ${_selectedIds.length}' : 'Пользователи',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
        actions: [
          IconButton(
            tooltip: _selectMode ? 'Отменить выбор' : 'Выбрать несколько',
            icon: Icon(_selectMode ? Icons.close : Icons.checklist, color: const Color(0xFF333333)),
            onPressed: _toggleSelectMode,
          ),
          if (_selectMode)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF333333)),
              onSelected: (v) async {
                if (v == 'select_all') {
                  _selectAllLoaded();
                  return;
                }
                if (v == 'ban') return _bulkUpdateUsers({kUserIsBanned: true});
                if (v == 'unban') return _bulkUpdateUsers({kUserIsBanned: false});
                if (v == 'verify') return _bulkUpdateUsers({kUserVerificationStatus: 'verified'});
                if (v == 'pending') return _bulkUpdateUsers({kUserVerificationStatus: 'pending'});
                if (v == 'none') return _bulkUpdateUsers({kUserVerificationStatus: 'none'});
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'select_all', child: Text('Выбрать все (загруженные)')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'ban', child: Text('Забанить')),
                PopupMenuItem(value: 'unban', child: Text('Разбанить')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'verify', child: Text('Верифицировать')),
                PopupMenuItem(value: 'pending', child: Text('В модерацию')),
                PopupMenuItem(value: 'none', child: Text('Сбросить верификацию')),
              ],
            ),
        ],
      ),
      body: _users.isEmpty && !_loading
          ? const Center(child: Text('Нет пользователей'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length + 1,
              itemBuilder: (context, index) {
                if (index == _users.length) {
                  if (_loading) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                  return Center(
                    child: TextButton(
                      onPressed: _loadMore,
                      child: const Text('Загрузить ещё'),
                    ),
                  );
                }
                final doc = _users[index];
                final d = doc.data();
                final name = d[kUserName]?.toString() ?? '—';
                final city = d[kUserCity]?.toString();
                final role = d[kUserRole]?.toString() ?? 'user';
                final verified = d[kUserVerificationStatus]?.toString() == 'verified';
                final banned = d[kUserIsBanned] == true;
                final photos = d[kUserPhotos];
                final photoUrl = photos is List && photos.isNotEmpty ? photos.first?.toString() : null;
                final selected = _selectedIds.contains(doc.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: ListTile(
                    leading: _selectMode
                        ? Checkbox(
                            value: selected,
                            onChanged: (_) => _toggleSelected(doc.id),
                          )
                        : CircleAvatar(
                            backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null || photoUrl.isEmpty ? const Icon(Icons.person) : null,
                          ),
                    title: Row(
                      children: [
                        Expanded(child: Text(name)),
                        if (verified) const Icon(Icons.verified, size: 18, color: Colors.green),
                        if (banned) const Icon(Icons.block, size: 18, color: Colors.red),
                      ],
                    ),
                    subtitle: Text('${city ?? ''} · $role'),
                    trailing: _selectMode ? null : const Icon(Icons.chevron_right),
                    onTap: () async {
                      if (_selectMode) {
                        _toggleSelected(doc.id);
                        return;
                      }
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AdminUserDetailScreen(userId: doc.id)),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
