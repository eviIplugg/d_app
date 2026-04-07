import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../firebase/firestore_schema.dart';
import 'admin_user_chat_messages_screen.dart';

class AdminUserChatsScreen extends StatefulWidget {
  const AdminUserChatsScreen({super.key, required this.userId});
  final String userId;

  @override
  State<AdminUserChatsScreen> createState() => _AdminUserChatsScreenState();
}

class _AdminUserChatsScreenState extends State<AdminUserChatsScreen> {
  /// Без orderBy — не нужен составной индекс; сортировка на клиенте.
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _chatsFuture;

  @override
  void initState() {
    super.initState();
    _chatsFuture = _loadChats();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadChats() async {
    final snap = await FirebaseFirestore.instance
        .collection(kChatsCollection)
        .where(kChatParticipantIds, arrayContains: widget.userId)
        .get();
    final docs = [...snap.docs]..sort((a, b) {
        final ta = a.data()[kChatLastMessageAt];
        final tb = b.data()[kChatLastMessageAt];
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
        title: const Text('Чаты', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        future: _chatsFuture,
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
                  ],
                ),
              ),
            );
          }
          final docs = snapshot.data ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Чатов нет'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();
              final lastPreview = d[kChatLastMessagePreview]?.toString();
              final participants = (d[kChatParticipantIds] is List)
                  ? (d[kChatParticipantIds] as List).map((e) => e.toString()).toList()
                  : <String>[];
              final otherIds = participants.where((p) => p != widget.userId).toList();
              final other = otherIds.isNotEmpty ? otherIds.first : '—';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text('Чат: ${doc.id}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('Собеседник: $other\n${lastPreview ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminUserChatMessagesScreen(chatId: doc.id)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

