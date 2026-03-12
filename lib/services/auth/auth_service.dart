import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vkid_flutter_sdk/library_vkid.dart' hide User;
import '../../firebase/firestore_schema.dart';

/// Сервис аутентификации: номер телефона и VK ID.
class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

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

  /// Получить профиль пользователя из Firestore (для синхронизации на сплеше).
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snap = await _firestore.collection(kUsersCollection).doc(uid).get();
    if (!snap.exists) return null;
    return snap.data();
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

  /// Вход по коду из SMS.
  Future<UserCredential> signInWithPhoneCode(String verificationId, String code) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Вызвать при открытии экрана выбора способа входа (для предзагрузки VK ID SDK).
  Future<void> ensureVKInitialized() async {
    await VKID.getInstance();
  }

  /// Вход через VK ID (официальный SDK vkid_flutter_sdk).
  Future<UserCredential?> signInWithVK() async {
    final vkid = await VKID.getInstance();
    final completer = Completer<AuthData>();
    vkid.authorize(
      onAuth: (AuthData data) {
        if (!completer.isCompleted) completer.complete(data);
      },
      onError: (AuthError error) {
        if (!completer.isCompleted) {
          final msg = switch (error) {
            AuthOtherError(description: final d) => d.isNotEmpty ? d : 'Ошибка VK ID',
            _ => 'Ошибка VK ID',
          };
          completer.completeError(Exception(msg));
        }
      },
      params: const AuthParams(),
    );
    final authData = await completer.future;
    final credential = OAuthProvider('vk.com').credential(
      accessToken: authData.token,
      idToken: authData.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Вход через Telegram (виджет или данные из Telegram).
  /// Только создаёт анонимную сессию и возвращает uid. Проверка по telegram id и сохранение — в экране.
  Future<String?> signInAnonymouslyForTelegram() async {
    final cred = await _auth.signInAnonymously();
    return cred.user?.uid;
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
    try {
      final vkid = await VKID.getInstance();
      vkid.logout();
    } catch (_) {}
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
