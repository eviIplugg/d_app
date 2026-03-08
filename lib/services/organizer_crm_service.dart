import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firestore_schema.dart';
import 'auth/auth_service.dart';

/// Сервис CRM для организаторов: мои места, мои мероприятия, создание/редактирование.
class OrganizerCrmService {
  OrganizerCrmService._();
  static final OrganizerCrmService _instance = OrganizerCrmService._();
  factory OrganizerCrmService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthService get _auth => AuthService();
  String? get _uid => _auth.currentUserId;

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
    String? address,
    String? city,
    bool verified = false,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Не авторизован');
    final data = <String, dynamic>{
      kVenueName: name,
      kVenueOwnerId: uid,
      kVenueVerified: verified,
      kVenueEventsCount: 0,
      kVenueSubscribersCount: 0,
    };
    if (photoUrl != null) data[kVenuePhotoUrl] = photoUrl;
    if (address != null) data[kVenueAddress] = address;
    if (city != null) data[kVenueCity] = city;

    if (venueId != null && venueId.isNotEmpty) {
      final doc = await _firestore.collection(kVenuesCollection).doc(venueId).get();
      if (doc.exists && doc.data()?[kVenueOwnerId] == uid) {
        await doc.reference.update(data);
        return venueId;
      }
    }
    final ref = _firestore.collection(kVenuesCollection).doc();
    await ref.set(data);
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
        return eventId;
      }
    }
    final ref = _firestore.collection(kEventsCollection).doc();
    await ref.set(data);
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
