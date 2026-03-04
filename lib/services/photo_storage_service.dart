import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Загрузка фото пользователя в Firebase Storage и получение URL.
class PhotoStorageService {
  PhotoStorageService._();
  static final PhotoStorageService _instance = PhotoStorageService._();
  factory PhotoStorageService() => _instance;

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Загружает локальные файлы (пути из draft.photos) в users/{uid}/photos/ и возвращает список URL.
  Future<List<String>> uploadUserPhotos(String uid, List<String?> photoPaths) async {
    final urls = <String>[];
    for (var i = 0; i < photoPaths.length; i++) {
      final path = photoPaths[i];
      if (path == null || path.trim().isEmpty) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      final ref = _storage.ref().child('users').child(uid).child('photos').child('$i.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }
}
