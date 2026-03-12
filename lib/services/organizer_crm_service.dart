import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase/firestore_schema.dart';
import 'auth/auth_service.dart';

/// Сервис CRM для организаторов: мои места, мои мероприятия, создание/редактирование.
class OrganizerCrmService {
  OrganizerCrmService._();
  static final OrganizerCrmService _instance = OrganizerCrmService._();
  factory OrganizerCrmService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  AuthService get _auth => AuthService();
  String? get _uid => _auth.currentUserId;

  Future<String?> _uploadVenuePhoto({required String venueId, required String filePath}) async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('venues').child(venueId).child('photo').child('photo_$ts.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String?> _uploadEventBanner({required String eventId, required String filePath}) async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('events').child(eventId).child('banner').child('banner_$ts.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<List<String>> _uploadEventGallery({required String eventId, required List<String> filePaths}) async {
    final urls = <String>[];
    for (var i = 0; i < filePaths.length; i++) {
      final p = filePaths[i];
      if (p.trim().isEmpty) continue;
      final file = File(p);
      if (!await file.exists()) continue;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('events').child(eventId).child('photos').child('${ts}_$i.jpg');
      await ref.putFile(file);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  /// Места, владельцем которых является текущий пользователь.
  Future<List<Map<String, dynamic>>> getMyVenues() async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _firestore
        .collection(kVenuesCollection)
        .where(kVenueOwnerId, isEqualTo: uid)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Мероприятия моих мест.
  Future<List<Map<String, dynamic>>> getMyEvents({int limit = 50}) async {
    final venues = await getMyVenues();
    final venueIds = venues.map((v) => v['id'] as String).toList();
    if (venueIds.isEmpty) return [];
    final events = <Map<String, dynamic>>[];
    for (final vid in venueIds) {
      final snap = await _firestore
          .collection(kEventsCollection)
          .where(kEventVenueId, isEqualTo: vid)
          .orderBy(kEventCreatedAt, descending: true)
          .limit(limit)
          .get();
      for (final d in snap.docs) {
        events.add({'id': d.id, ...d.data()});
      }
    }
    events.sort((a, b) {
      final at = a[kEventCreatedAt];
      final bt = b[kEventCreatedAt];
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      final ats = at is Timestamp ? at.toDate() : at as DateTime?;
      final bts = bt is Timestamp ? bt.toDate() : bt as DateTime?;
      if (ats == null || bts == null) return 0;
      return bts.compareTo(ats);
    });
    return events.take(limit).toList();
  }

  /// Создать или обновить место проведения.
  Future<String> saveVenue({
    String? venueId,
    required String name,
    String? photoUrl,
    String? photoFilePath,
    String? address,
    String? city,
    bool verified = false,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Не авторизован');
    final createData = <String, dynamic>{
      kVenueName: name,
      kVenueOwnerId: uid,
      kVenueVerified: verified,
      kVenueEventsCount: 0,
      kVenueSubscribersCount: 0,
    };
    final updateData = <String, dynamic>{
      kVenueName: name,
      kVenueOwnerId: uid,
      kVenueVerified: verified,
    };
    if (photoUrl != null) {
      createData[kVenuePhotoUrl] = photoUrl;
      updateData[kVenuePhotoUrl] = photoUrl;
    }
    if (address != null) {
      createData[kVenueAddress] = address;
      updateData[kVenueAddress] = address;
    }
    if (city != null) {
      createData[kVenueCity] = city;
      updateData[kVenueCity] = city;
    }

    if (venueId != null && venueId.isNotEmpty) {
      final doc = await _firestore.collection(kVenuesCollection).doc(venueId).get();
      if (doc.exists && doc.data()?[kVenueOwnerId] == uid) {
        await doc.reference.update(updateData);
        if (photoFilePath != null && photoFilePath.trim().isNotEmpty) {
          final url = await _uploadVenuePhoto(venueId: venueId, filePath: photoFilePath);
          if (url != null) await doc.reference.update({kVenuePhotoUrl: url});
        }
        return venueId;
      }
    }
    final ref = _firestore.collection(kVenuesCollection).doc();
    await ref.set(createData);
    if (photoFilePath != null && photoFilePath.trim().isNotEmpty) {
      final url = await _uploadVenuePhoto(venueId: ref.id, filePath: photoFilePath);
      if (url != null) await ref.update({kVenuePhotoUrl: url});
    }
    return ref.id;
  }

  /// Создать или обновить мероприятие.
  Future<String> saveEvent({
    String? eventId,
    required String venueId,
    required String title,
    String? description,
    String? imageUrl,
    List<String>? photoUrls,
    String? bannerFilePath,
    List<String>? galleryFilePaths,
    required DateTime dateTime,
    String? address,
    String? city,
    String? price,
    double? rating,
    int maxParticipants = 15,
    String? venueName,
    bool venueVerified = false,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Не авторизован');
    final venueDoc = await _firestore.collection(kVenuesCollection).doc(venueId).get();
    if (!venueDoc.exists || venueDoc.data()?[kVenueOwnerId] != uid) {
      throw Exception('Место проведения не найдено или нет прав');
    }
    final data = <String, dynamic>{
      kEventTitle: title,
      kEventVenueId: venueId,
      kEventVenueName: venueName ?? venueDoc.data()?[kVenueName],
      kEventVenueVerified: venueVerified,
      kEventDateTime: Timestamp.fromDate(dateTime),
      kEventCreatedBy: uid,
      kEventCreatedAt: FieldValue.serverTimestamp(),
      kEventStatus: 'open',
      kEventCurrentParticipants: 0,
      kEventMaxParticipants: maxParticipants,
      kEventLikedBy: <String>[],
    };
    if (description != null) data[kEventDescription] = description;
    if (imageUrl != null) data[kEventImageUrl] = imageUrl;
    if (photoUrls != null) data[kEventPhotoUrls] = photoUrls;
    if (address != null) data[kEventAddress] = address;
    if (city != null) data[kEventCity] = city;
    if (price != null) data[kEventPrice] = price;
    if (rating != null) data[kEventRating] = rating;

    if (eventId != null && eventId.isNotEmpty) {
      final eventDoc = await _firestore.collection(kEventsCollection).doc(eventId).get();
      if (eventDoc.exists && eventDoc.data()?[kEventCreatedBy] == uid) {
        data.remove(kEventCreatedAt);
        data.remove(kEventCurrentParticipants);
        data.remove(kEventLikedBy);
        await eventDoc.reference.update(data);
        // Файлы в Storage
        if (bannerFilePath != null && bannerFilePath.trim().isNotEmpty) {
          final url = await _uploadEventBanner(eventId: eventId, filePath: bannerFilePath);
          if (url != null) await eventDoc.reference.update({kEventImageUrl: url});
        }
        if (galleryFilePaths != null && galleryFilePaths.isNotEmpty) {
          final urls = await _uploadEventGallery(eventId: eventId, filePaths: galleryFilePaths);
          if (urls.isNotEmpty) {
            final existing = List<String>.from((eventDoc.data()?[kEventPhotoUrls] as List?)?.map((e) => e.toString()) ?? []);
            await eventDoc.reference.update({kEventPhotoUrls: [...existing, ...urls]});
          }
        }
        return eventId;
      }
    }
    final ref = _firestore.collection(kEventsCollection).doc();
    await ref.set(data);
    // Файлы в Storage для нового мероприятия
    if (bannerFilePath != null && bannerFilePath.trim().isNotEmpty) {
      final url = await _uploadEventBanner(eventId: ref.id, filePath: bannerFilePath);
      if (url != null) await ref.update({kEventImageUrl: url});
    }
    if (galleryFilePaths != null && galleryFilePaths.isNotEmpty) {
      final urls = await _uploadEventGallery(eventId: ref.id, filePaths: galleryFilePaths);
      if (urls.isNotEmpty) await ref.update({kEventPhotoUrls: urls});
    }
    return ref.id;
  }

  /// Удалить мероприятие (только своё).
  Future<void> deleteEvent(String eventId) async {
    final uid = _uid;
    if (uid == null) return;
    final doc = await _firestore.collection(kEventsCollection).doc(eventId).get();
    if (doc.exists && doc.data()?[kEventCreatedBy] == uid) {
      await doc.reference.delete();
    }
  }
}
