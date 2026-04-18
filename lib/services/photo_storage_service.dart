import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import 'image_optimization_service.dart';

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
      final optimized = await ImageOptimizationService.optimizeJpeg(
        file,
        minWidth: 1080,
        minHeight: 1080,
        quality: 72,
      );
      final ref = _storage.ref().child('users').child(uid).child('photos').child('$i.jpg');
      await ref.putFile(
        optimized,
        SettableMetadata(contentType: 'image/jpeg', cacheControl: 'public,max-age=604800'),
      );
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }
}
