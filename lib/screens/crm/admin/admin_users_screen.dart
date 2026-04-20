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
  final TextEditingController _searchCtrl = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _users = [];
  List<DocumentSnapshot<Map<String, dynamic>>> _searchResults = [];
  DocumentSnapshot? _lastDoc;
  bool _loading = false;
  bool _searching = false;
  String? _searchError;
  bool _selectMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
      if (_selectedIds.contains(uid)) {
        _selectedIds.remove(uid);
      } else {
        _selectedIds.add(uid);
      }
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

  Future<void> _searchUsers() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final found = await _crm.searchUsersByNameOrId(q, limit: 30);
      if (!mounted) return;
      setState(() => _searchResults = found);
    } catch (e) {
      if (!mounted) return;
      setState(() => _searchError = 'Ошибка поиска: $e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _grantAdmin(String userId) async {
    try {
      await _crm.updateUserByAdmin(userId, {kUserRole: 'admin'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Права администратора выданы'), backgroundColor: Colors.green),
      );
      await _searchUsers();
      setState(() {
        _users = [];
        _lastDoc = null;
      });
      await _loadMore();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось выдать права: $e'), backgroundColor: Colors.red),
      );
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchUsers(),
                    decoration: InputDecoration(
                      hintText: 'Поиск: имя или UID',
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: _searchUsers,
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Сбросить поиск',
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {
                      _searchResults = [];
                      _searchError = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
          ),
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(_searchError!, style: const TextStyle(color: Colors.red)),
              ),
            ),
          Expanded(
            child: (_searchCtrl.text.trim().isNotEmpty)
                ? (_searchResults.isEmpty && !_searching
                    ? const Center(child: Text('Ничего не найдено'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final doc = _searchResults[index];
                          final d = doc.data() ?? <String, dynamic>{};
                          final name = d[kUserName]?.toString() ?? '—';
                          final city = d[kUserCity]?.toString();
                          final role = d[kUserRole]?.toString() ?? 'user';
                          final banned = d[kUserIsBanned] == true;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: ListTile(
                              title: Text('$name  (${doc.id})'),
                              subtitle: Text('${city ?? ''} · $role${banned ? ' · banned' : ''}'),
                              trailing: role == 'admin'
                                  ? const Chip(label: Text('admin'))
                                  : FilledButton(
                                      onPressed: () => _grantAdmin(doc.id),
                                      child: const Text('Сделать админом'),
                                    ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AdminUserDetailScreen(userId: doc.id)),
                                );
                              },
                            ),
                          );
                        },
                      ))
                : (_users.isEmpty && !_loading
                    ? const Center(child: Text('Нет пользователей'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _users.length) {
                            if (_loading) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
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
                      )),
          ),
        ],
      ),
    );
  }
}
