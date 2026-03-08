import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../firebase/firestore_schema.dart';
import '../../../services/admin_crm_service.dart';
import 'admin_user_edit_screen.dart';

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
        title: const Text('Пользователи', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
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
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
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
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminUserEditScreen(userId: doc.id, userData: d),
                        ),
                      );
                      _loadMore();
                    },
                  ),
                );
              },
            ),
    );
  }
}
