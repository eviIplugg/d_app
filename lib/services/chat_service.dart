import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../firebase/firestore_schema.dart';
import 'image_optimization_service.dart';
import 'auth/auth_service.dart';

/// Модель чата для списка (другой пользователь, последнее сообщение, непрочитанные).
class ChatListItem {
  final String matchId;
  final String otherUserId;
  final String otherName;
  final String? otherPhotoUrl;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final int unreadCount;
  /// Последняя активность собеседника (для «в сети»).
  final DateTime? otherLastActiveAt;

  ChatListItem({
    required this.matchId,
    required this.otherUserId,
    required this.otherName,
    this.otherPhotoUrl,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.unreadCount = 0,
    this.otherLastActiveAt,
  });
}

/// Модель сообщения в чате.
class ChatMessage {
  final String id;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final DateTime createdAt;
  final List<String> readBy;

  ChatMessage({
    required this.id,
    required this.senderId,
    this.text,
    this.imageUrl,
    required this.createdAt,
    this.readBy = const [],
  });

  bool get isText => text != null && text!.isNotEmpty;
  bool get isImage => imageUrl != null && imageUrl!.isNotEmpty;
}

/// Сервис чатов: список диалогов (мэтчи), сообщения, отправка, непрочитанные.
class ChatService {
  ChatService._();
  static final ChatService _instance = ChatService._();
  factory ChatService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  AuthService get _auth => AuthService();

  String? get _uid => _auth.currentUserId;

  /// Список чатов текущего пользователя (мэтчи + последнее сообщение + непрочитанные).
  Future<List<ChatListItem>> getChatList() async {
    final uid = _uid;
    if (uid == null) return [];

    final matchesSnap = await _firestore
        .collection(kMatchesCollection)
        .where(kMatchUserId1, isEqualTo: uid)
        .get();
    final matchesSnap2 = await _firestore
        .collection(kMatchesCollection)
        .where(kMatchUserId2, isEqualTo: uid)
        .get();

    final list = <ChatListItem>[];
    final seen = <String>{};

    void process(DocumentSnapshot<Map<String, dynamic>> doc) {
      final d = doc.data()!;
      final id1 = d[kMatchUserId1] as String?;
      final id2 = d[kMatchUserId2] as String?;
      if (id1 == null || id2 == null) return;
      if (id1 != uid && id2 != uid) return;
      final matchId = doc.id;
      if (seen.contains(matchId)) return;
      seen.add(matchId);
      final otherId = id1 == uid ? id2 : id1;
      final unread = id1 == uid
          ? (d[kMatchUnreadCount1] as int? ?? 0)
          : (d[kMatchUnreadCount2] as int? ?? 0);
      list.add(ChatListItem(
        matchId: matchId,
        otherUserId: otherId,
        otherName: 'Пользователь',
        unreadCount: unread,
      ));
    }

    for (final doc in matchesSnap.docs) {
      process(doc);
    }
    for (final doc in matchesSnap2.docs) {
      process(doc);
    }

    // Параллельно: чат + профиль по каждому мэтчу (раньше было N последовательных round-trip).
    if (list.isNotEmpty) {
      final enriched = await Future.wait(
        list.map((item) async {
          final pair = await Future.wait<DocumentSnapshot<Map<String, dynamic>>>([
            _firestore.collection(kChatsCollection).doc(item.matchId).get(),
            _firestore.collection(kUsersCollection).doc(item.otherUserId).get(),
          ]);
          final chatDoc = pair[0];
          final userDoc = pair[1];
          final userData = userDoc.data();
          final name = userData?[kUserName]?.toString() ?? 'Пользователь';
          final photos = userData?[kUserPhotos];
          final photoUrl = photos is List && photos.isNotEmpty ? photos.first?.toString() : null;
          DateTime? otherLastActive;
          final la = userData?[kUserLastActiveAt];
          if (la is Timestamp) otherLastActive = la.toDate();

          String? preview;
          DateTime? lastAt;
          String? lastSenderId;
          if (chatDoc.exists && chatDoc.data() != null) {
            final chatData = chatDoc.data()!;
            preview = chatData[kChatLastMessagePreview]?.toString();
            lastSenderId = chatData[kChatLastMessageSenderId]?.toString();
            final t = chatData[kChatLastMessageAt];
            if (t is Timestamp) lastAt = t.toDate();
          }

          return ChatListItem(
            matchId: item.matchId,
            otherUserId: item.otherUserId,
            otherName: name,
            otherPhotoUrl: photoUrl,
            lastMessagePreview: preview,
            lastMessageAt: lastAt,
            lastMessageSenderId: lastSenderId,
            unreadCount: item.unreadCount,
            otherLastActiveAt: otherLastActive,
          );
        }),
      );
      list
        ..clear()
        ..addAll(enriched);
    }

    list.sort((a, b) {
      final at = a.lastMessageAt ?? DateTime(0);
      final bt = b.lastMessageAt ?? DateTime(0);
      return bt.compareTo(at);
    });
    return list;
  }

  /// Стрим списка чатов (для обновления при новых сообщениях).
  Stream<List<ChatListItem>> streamChatList() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    final a = _firestore
        .collection(kMatchesCollection)
        .where(kMatchUserId1, isEqualTo: uid)
        .snapshots();
    final b = _firestore
        .collection(kMatchesCollection)
        .where(kMatchUserId2, isEqualTo: uid)
        .snapshots();

    late StreamController<List<ChatListItem>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subA;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subB;

    Timer? debounce;
    controller = StreamController<List<ChatListItem>>(onListen: () async {
      controller.add(await getChatList());
      void onUpdate(_) {
        debounce?.cancel();
        debounce = Timer(const Duration(milliseconds: 400), () async {
          if (controller.isClosed) return;
          try {
            controller.add(await getChatList());
          } catch (_) {
            if (!controller.isClosed) controller.add(<ChatListItem>[]);
          }
        });
      }
      subA = a.listen(onUpdate);
      subB = b.listen(onUpdate);
    }, onCancel: () {
      debounce?.cancel();
      subA?.cancel();
      subB?.cancel();
    });

    return controller.stream;
  }

  /// Стрим общего числа непрочитанных (для бейджа на вкладке «Чаты»).
  Stream<int> streamTotalUnreadCount() =>
      streamChatList().map((list) => list.fold<int>(0, (s, c) => s + c.unreadCount));

  /// Сообщения чата (стрим).
  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _firestore
        .collection(kChatsCollection)
        .doc(chatId)
        .collection(kMessagesSubcollection)
        .orderBy(kMessageCreatedAt, descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              final t = data[kMessageCreatedAt];
              final readBy = data[kMessageReadBy];
              return ChatMessage(
                id: d.id,
                senderId: data[kMessageSenderId]?.toString() ?? '',
                text: data[kMessageText]?.toString(),
                imageUrl: data[kMessageImageUrl]?.toString(),
                createdAt: t is Timestamp ? t.toDate() : DateTime.now(),
                readBy: readBy is List ? readBy.map((e) => e.toString()).toList() : [],
              );
            }).toList());
  }

  /// Отправить текстовое сообщение.
  Future<void> sendText(String chatId, String text) async {
    final uid = _uid;
    if (uid == null || text.trim().isEmpty) return;
    await _addMessage(chatId, senderId: uid, text: text.trim());
  }

  /// Отправить сообщение с изображением (URL после загрузки в Storage).
  Future<void> sendImage(String chatId, String imageUrl) async {
    final uid = _uid;
    if (uid == null) return;
    await _addMessage(chatId, senderId: uid, imageUrl: imageUrl);
  }

  Future<void> _addMessage(
    String chatId, {
    required String senderId,
    String? text,
    String? imageUrl,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final matchDoc = await _firestore.collection(kMatchesCollection).doc(chatId).get();
    if (!matchDoc.exists) return;
    final matchData = matchDoc.data()!;
    final id1 = matchData[kMatchUserId1] as String?;
    final id2 = matchData[kMatchUserId2] as String?;
    if (id1 == null || id2 == null) return;
    final isUser1 = id1 == uid;

    final messagesRef = _firestore
        .collection(kChatsCollection)
        .doc(chatId)
        .collection(kMessagesSubcollection);

    await messagesRef.add({
      kMessageSenderId: senderId,
      kMessageText: text ?? '',
      if (imageUrl != null) kMessageImageUrl: imageUrl,
      kMessageType: imageUrl != null ? 'image' : 'text',
      kMessageCreatedAt: FieldValue.serverTimestamp(),
      kMessageReadBy: [senderId],
    });

    final preview = text != null && text.isNotEmpty
        ? (text.length > 50 ? '${text.substring(0, 50)}...' : text)
        : '📷 Фото';

    final chatRef = _firestore.collection(kChatsCollection).doc(chatId);
    await chatRef.set({
      kChatParticipantIds: [id1, id2],
      kChatLastMessageAt: FieldValue.serverTimestamp(),
      kChatLastMessagePreview: preview,
      kChatLastMessageSenderId: senderId,
    }, SetOptions(merge: true));

    await _firestore.collection(kMatchesCollection).doc(chatId).update({
      kMatchLastActivityAt: FieldValue.serverTimestamp(),
      if (isUser1) kMatchUnreadCount2: FieldValue.increment(1),
      if (!isUser1) kMatchUnreadCount1: FieldValue.increment(1),
    });
  }

  /// Отметить чат как прочитанный (обнулить счётчик непрочитанных для текущего пользователя).
  Future<void> markAsRead(String chatId) async {
    final uid = _uid;
    if (uid == null) return;
    final matchDoc = await _firestore.collection(kMatchesCollection).doc(chatId).get();
    if (!matchDoc.exists) return;
    final d = matchDoc.data()!;
    final id1 = d[kMatchUserId1] as String?;
    final id2 = d[kMatchUserId2] as String?;
    if (id1 == uid) {
      await _firestore.collection(kMatchesCollection).doc(chatId).update({kMatchUnreadCount1: 0});
    } else if (id2 == uid) {
      await _firestore.collection(kMatchesCollection).doc(chatId).update({kMatchUnreadCount2: 0});
    }
  }

  /// Общее количество непрочитанных сообщений (для бейджа на вкладке «Чаты»).
  Future<int> getTotalUnreadCount() async {
    final list = await getChatList();
    return list.fold<int>(0, (total, c) => total + c.unreadCount);
  }

  /// Загрузить изображение в Storage и вернуть URL (для отправки в чат).
  Future<String> uploadChatImage(String chatId, File file) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');
    final optimized = await ImageOptimizationService.optimizeJpeg(
      file,
      minWidth: 1280,
      minHeight: 1280,
      quality: 74,
    );
    final ref = _storage
        .ref()
        .child('chats')
        .child(chatId)
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(
      optimized,
      SettableMetadata(contentType: 'image/jpeg', cacheControl: 'public,max-age=604800'),
    );
    return ref.getDownloadURL();
  }
}
