import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../firebase/firestore_schema.dart';

/// Сервис аутентификации: номер телефона и Telegram.
class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// На web сессия IndexedDB поднимается не мгновенно — коротко ждём, чтобы не сбрасывать в Welcome.
  Future<User?> waitForInitialUserOnWeb() async {
    if (!kIsWeb) return _auth.currentUser;
    for (var i = 0; i < 15; i++) {
      final u = _auth.currentUser;
      if (u != null) return u;
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    return _auth.currentUser;
  }

  /// Роль текущего пользователя: 'user' | 'organizer' | 'admin'. По умолчанию 'user'.
  Future<String> getUserRole(String uid) async {
    final profile = await getUserProfile(uid);
    final role = profile?[kUserRole]?.toString();
    return (role == 'admin' || role == 'organizer') ? role! : 'user';
  }

  /// Является ли текущий пользователь админом.
  Future<bool> isAdmin() async {
    final uid = currentUserId;
    if (uid == null) return false;
    return await getUserRole(uid) == 'admin';
  }

  /// Является ли текущий пользователь организатором (имеет роль organizer или владеет хотя бы одним venue).
  Future<bool> isOrganizer() async {
    final uid = currentUserId;
    if (uid == null) return false;
    if (await getUserRole(uid) == 'organizer') return true;
    final snap = await FirebaseFirestore.instance
        .collection(kVenuesCollection)
        .where(kVenueOwnerId, isEqualTo: uid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  final Map<String, Map<String, dynamic>?> _profileCache = {};

  /// Web: результат `signInWithPhoneNumber`, подтверждается через [signInWithPhoneCode].
  ConfirmationResult? _webPhoneConfirmation;

  /// Специальное значение [PhoneAuthCredential.verificationId] на web (код подтверждает [ConfirmationResult]).
  static const String kWebPhoneVerificationId = '__WEB_PHONE__';

  DateTime? _lastPresenceWriteLocal;

  /// Обновить время последней активности (для «в сети»). Не чаще чем раз в [minInterval], чтобы не спамить Firestore.
  Future<void> touchLastActive({Duration minInterval = const Duration(seconds: 45)}) async {
    final uid = currentUserId;
    if (uid == null) return;
    final now = DateTime.now();
    if (_lastPresenceWriteLocal != null && now.difference(_lastPresenceWriteLocal!) < minInterval) {
      return;
    }
    _lastPresenceWriteLocal = now;
    try {
      await _firestore.collection(kUsersCollection).doc(uid).set(
        {kUserLastActiveAt: FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (_) {
      // сеть / правила — не падаем
    }
  }

  /// Получить профиль пользователя из Firestore (для синхронизации на сплеше). Результат кешируется в памяти.
  Future<Map<String, dynamic>?> getUserProfile(String uid, {bool forceRefresh = false}) async {
    if (uid.isEmpty) return null;
    if (!forceRefresh && _profileCache.containsKey(uid)) return _profileCache[uid];
    final snap = await _firestore.collection(kUsersCollection).doc(uid).get();
    if (!snap.exists) {
      _profileCache[uid] = null;
      return null;
    }
    final data = snap.data();
    _profileCache[uid] = data;
    return data;
  }

  /// Сбросить кеш профиля (вызывать после updateUserProfile / saveOrUpdateUser для этого uid).
  void _invalidateProfileCache(String uid) {
    _profileCache.remove(uid);
  }

  void clearAllProfileCache() {
    _profileCache.clear();
  }

  /// Привязать Telegram к уже вошедшему аккаунту (не меняет основной authProvider).
  /// Возвращает null при успехе, иначе текст ошибки.
  Future<String?> linkTelegramToCurrentUser({required String telegramUserId}) async {
    final uid = currentUserId;
    if (uid == null) return 'Выполните вход в аккаунт';
    final id = telegramUserId.trim();
    if (id.isEmpty) return 'Не получен ID Telegram';
    final existing = await findUserByTelegramId(id);
    if (existing != null) {
      final other = existing['uid']?.toString();
      if (other != null && other != uid) {
        return 'Этот Telegram уже привязан к другому аккаунту';
      }
    }
    await updateUserProfile(
      uid: uid,
      profileData: {kUserTelegramUserId: id},
    );
    return null;
  }

  /// Найти существующего пользователя по Telegram ID (для проверки при входе через Telegram).
  /// Возвращает данные документа пользователя (включая name) или null. Требует авторизации.
  Future<Map<String, dynamic>?> findUserByTelegramId(String telegramUserId) async {
    if (telegramUserId.trim().isEmpty) return null;
    final snap = await _firestore
        .collection(kUsersCollection)
        .where(kUserTelegramUserId, isEqualTo: telegramUserId.trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    final data = doc.data();
    data['uid'] = doc.id;
    return data;
  }

  /// Проверить, что пользователь «полностью» зарегистрирован (есть имя и хотя бы пол или фото).
  bool isProfileRegistered(Map<String, dynamic>? profile) {
    if (profile == null) return false;
    final name = profile[kUserName]?.toString().trim();
    if (name == null || name.isEmpty) return false;
    final hasGender = profile[kUserGender] != null && (profile[kUserGender] as String).isNotEmpty;
    final photos = profile[kUserPhotos];
    final hasPhotos = photos is List && photos.isNotEmpty;
    return hasGender || hasPhotos;
  }

  /// Есть ли в профиле имя (для входа в существующий аккаунт — показать «Добро пожаловать» и зайти в приложение).
  bool hasProfileWithName(Map<String, dynamic>? profile) {
    if (profile == null) return false;
    final name = profile[kUserName]?.toString().trim();
    return name != null && name.isNotEmpty;
  }

  /// Вход по номеру телефона: отправка кода (SMS). При ошибке "unavailable" — повтор с задержкой.
  Future<String> sendPhoneCode(String phoneNumber) async {
    const maxAttempts = 3;
    const backoffDelays = [Duration(seconds: 2), Duration(seconds: 4), Duration(seconds: 6)];
    Object? lastError;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) await Future.delayed(backoffDelays[attempt - 1]);
      try {
        return await _sendPhoneCodeOnce(phoneNumber);
      } catch (e) {
        lastError = e;
        final msg = e.toString().toLowerCase();
        final isRetryable = msg.contains('unavailable') ||
            msg.contains('transient') ||
            msg.contains('network') ||
            msg.contains('timeout');
        if (!isRetryable || attempt == maxAttempts - 1) rethrow;
      }
    }
    throw lastError ?? Exception('Не удалось отправить код');
  }

  Future<String> _sendPhoneCodeOnce(String phoneNumber) async {
    final normalized = _normalizePhone(phoneNumber);
    if (kIsWeb) {
      _webPhoneConfirmation = await _auth.signInWithPhoneNumber(normalized);
      return kWebPhoneVerificationId;
    }
    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: normalized,
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (!completer.isCompleted) completer.completeError(Exception('Auto-verified'));
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(Exception(e.message ?? 'Ошибка верификации телефона'));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        _lastResendToken = resendToken;
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 120),
    );
    return completer.future;
  }

  int? _lastResendToken;
  int? get lastResendToken => _lastResendToken;

  /// Вход по коду из SMS (на web — код для [ConfirmationResult]).
  Future<UserCredential> signInWithPhoneCode(String verificationId, String code) async {
    if (kIsWeb && verificationId == kWebPhoneVerificationId) {
      final cr = _webPhoneConfirmation;
      if (cr == null) {
        throw FirebaseAuthException(
          code: 'invalid-verification-id',
          message: 'Сначала запросите код на номер',
        );
      }
      return cr.confirm(code);
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Вход через Telegram (виджет или данные из Telegram).
  /// Только создаёт анонимную сессию и возвращает uid. Проверка по telegram id и сохранение — в экране.
  Future<String?> signInAnonymouslyForTelegram() async {
    final cred = await _auth.signInAnonymously();
    return cred.user?.uid;
  }

  /// Вход по custom token (Cloud Function `telegramSignIn` для существующего аккаунта Telegram).
  Future<UserCredential> signInWithCustomToken(String token) async {
    final cred = await _auth.signInWithCustomToken(token);
    clearAllProfileCache();
    return cred;
  }

  /// Получить ссылку для токен-входа в CRM.
  /// Возвращает URL вида https://dating-app-34f38.web.app/?crm_token=...
  Future<String> issueCrmLoginLink() async {
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    final callable = functions.httpsCallable('issueCrmLoginToken');
    final result = await callable.call();
    final raw = result.data;
    if (raw is! Map) {
      throw FirebaseFunctionsException(code: 'data-loss', message: 'Invalid issueCrmLoginToken response');
    }
    final data = Map<String, dynamic>.from(raw);
    final url = data['crmUrl']?.toString() ?? '';
    if (url.isEmpty) {
      throw FirebaseFunctionsException(code: 'data-loss', message: 'crmUrl is empty');
    }
    return url;
  }

  /// Сохранить/обновить профиль после входа через Telegram (имя и telegramUserId).
  Future<void> saveTelegramUser({
    required String uid,
    required String telegramName,
    String? telegramUserId,
  }) async {
    final String? normalizedPhone = null;
    await saveOrUpdateUser(
      uid: uid,
      authProvider: 'telegram',
      phoneNumber: normalizedPhone,
      profileData: {
        kUserName: telegramName.trim().isEmpty ? 'Пользователь' : telegramName.trim(),
        if (telegramUserId != null && telegramUserId.isNotEmpty) kUserTelegramUserId: telegramUserId,
      },
    );
  }

  /// Вход через Telegram (виджет или данные из Telegram). Создаёт анонимного пользователя Firebase и сохраняет имя в Firestore.
  /// При временной недоступности Firestore — повтор с задержкой; после входа всегда возвращает uid.
  Future<String?> signInWithTelegram({
    String? phoneNumber,
    required String telegramName,
    String? telegramUserId,
  }) async {
    final cred = await _auth.signInAnonymously();
    final uid = cred.user?.uid;
    if (uid == null) return null;
    final String? normalizedPhone = (phoneNumber != null && phoneNumber.trim().isNotEmpty)
        ? _normalizePhone(phoneNumber)
        : null;
    const maxAttempts = 3;
    const backoffDelays = [Duration(seconds: 2), Duration(seconds: 4), Duration(seconds: 6)];
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) await Future.delayed(backoffDelays[attempt - 1]);
      try {
        await saveOrUpdateUser(
          uid: uid,
          authProvider: 'telegram',
          phoneNumber: normalizedPhone,
          profileData: {
            kUserName: telegramName.trim().isEmpty ? 'Пользователь' : telegramName.trim(),
            if (telegramUserId != null && telegramUserId.isNotEmpty) kUserTelegramUserId: telegramUserId,
          },
        );
        break;
      } catch (e) {
        final msg = e.toString().toLowerCase();
        final isRetryable = msg.contains('unavailable') ||
            msg.contains('transient') ||
            msg.contains('network') ||
            msg.contains('timeout');
        if (!isRetryable) rethrow;
      }
    }
    return uid;
  }

  /// Выход.
  Future<void> signOut() async {
    _profileCache.clear();
    _webPhoneConfirmation = null;
    await _auth.signOut();
  }

  /// Сохранение/обновление профиля пользователя в Firestore после входа.
  Future<void> saveOrUpdateUser({
    required String uid,
    required String authProvider,
    String? phoneNumber,
    Map<String, dynamic>? profileData,
  }) async {
    final ref = _firestore.collection(kUsersCollection).doc(uid);
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      kUserAuthProvider: authProvider,
      kUserUpdatedAt: now,
      kUserLastActiveAt: now,
    };
    if (phoneNumber != null) data[kUserPhoneNumber] = phoneNumber;
    if (profileData != null) data.addAll(profileData);

    final snap = await ref.get();
    if (snap.exists) {
      await ref.update(data);
    } else {
      data[kUserCreatedAt] = now;
      data[kUserVerificationStatus] = 'none';
      await ref.set(data);
    }
    _invalidateProfileCache(uid);
  }

  /// Обновление профиля пользователя (имя, био, фото и т.д.) без смены authProvider.
  /// [profileData] может содержать DateTime — они будут сохранены как Timestamp.
  Future<void> updateUserProfile({
    required String uid,
    Map<String, dynamic>? profileData,
  }) async {
    if (profileData == null || profileData.isEmpty) return;
    final ref = _firestore.collection(kUsersCollection).doc(uid);
    final data = <String, dynamic>{};
    for (final e in profileData.entries) {
      if (e.value is DateTime) {
        data[e.key] = Timestamp.fromDate(e.value as DateTime);
      } else {
        data[e.key] = e.value;
      }
    }
    data[kUserUpdatedAt] = FieldValue.serverTimestamp();
    data[kUserLastActiveAt] = FieldValue.serverTimestamp();
    await ref.set(data, SetOptions(merge: true));
    _invalidateProfileCache(uid);
  }

  static String _normalizePhone(String phone) {
    String s = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (s.startsWith('8') && s.length == 11) {
      s = '+7${s.substring(1)}';
    } else if (s.startsWith('7') && s.length == 11) {
      s = '+$s';
    } else if (!s.startsWith('+')) {
      s = '+7$s';
    }
    return s;
  }
}
