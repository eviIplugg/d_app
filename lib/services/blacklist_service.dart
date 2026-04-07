import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../firebase/firestore_schema.dart';

class BlacklistService {
  BlacklistService._();
  static final BlacklistService _instance = BlacklistService._();
  factory BlacklistService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String _sha256Hex(String input) {
    final bytes = utf8.encode(input.trim());
    return sha256.convert(bytes).toString();
  }

  Future<bool> isPhoneBlacklisted(String? phoneE164) async {
    final v = phoneE164?.trim();
    if (v == null || v.isEmpty) return false;
    final hash = _sha256Hex(v);
    final docId = 'phone_$hash';
    final snap = await _firestore.collection(kBlacklistCollection).doc(docId).get();
    return snap.exists;
  }

  Future<bool> isTelegramBlacklisted(String? telegramUserId) async {
    final v = telegramUserId?.trim();
    if (v == null || v.isEmpty) return false;
    final hash = _sha256Hex(v);
    final docId = 'telegram_$hash';
    final snap = await _firestore.collection(kBlacklistCollection).doc(docId).get();
    return snap.exists;
  }
}

