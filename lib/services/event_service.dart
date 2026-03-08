import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firestore_schema.dart';
import '../models/event_item.dart';
import 'auth/auth_service.dart';

/// Сервис мероприятий: лента по разделам, подписка на организатора, присоединиться к событию.
class EventService {
  EventService._();
  static final EventService _instance = EventService._();
  factory EventService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthService get _auth => AuthService();
  String? get _uid => _auth.currentUserId;

  /// События «рядом с вами» (по городу пользователя или все).
  Future<List<EventItem>> getNearbyEvents({int limit = 20}) async {
    final uid = _uid;
    final q = _firestore
        .collection(kEventsCollection)
        .orderBy(kEventCreatedAt, descending: true)
        .limit(limit);
    final snap = await q.get();
    final joinedIds = uid != null ? await _getJoinedEventIds(uid) : <String>{};
    return snap.docs.map((d) => EventItem.fromFirestore(d, currentUserId: uid, joined: joinedIds.contains(d.id))).toList();
  }

  /// События, на которые пользователь записался (Ваше расписание).
  Future<List<EventItem>> getMyScheduleEvents({int limit = 20}) async {
    final uid = _uid;
    if (uid == null) return [];
    final joinedIds = await _getJoinedEventIds(uid);
    if (joinedIds.isEmpty) return [];
    final events = <EventItem>[];
    for (final eid in joinedIds.take(limit)) {
      final doc = await _firestore.collection(kEventsCollection).doc(eid).get();
      if (doc.exists && doc.data() != null) {
        events.add(EventItem.fromFirestore(doc, currentUserId: uid, joined: true));
      }
    }
    events.sort((a, b) => (b.dateTime ?? DateTime(0)).compareTo(a.dateTime ?? DateTime(0)));
    return events;
  }

  /// Популярные события (по количеству участников или лайков).
  Future<List<EventItem>> getPopularEvents({int limit = 20}) async {
    final uid = _uid;
    final q = _firestore
        .collection(kEventsCollection)
        .orderBy(kEventCurrentParticipants, descending: true)
        .limit(limit);
    final snap = await q.get();
    final joinedIds = uid != null ? await _getJoinedEventIds(uid) : <String>{};
    return snap.docs.map((d) => EventItem.fromFirestore(d, currentUserId: uid, joined: joinedIds.contains(d.id))).toList();
  }

  Future<Set<String>> _getJoinedEventIds(String userId) async {
    final snap = await _firestore
        .collection(kEventParticipantsCollection)
        .where(kEventParticipantUserId, isEqualTo: userId)
        .get();
    return snap.docs.map((d) => d.data()[kEventParticipantEventId]?.toString()).whereType<String>().toSet();
  }

  /// Подписаться на организатора (venue).
  Future<void> subscribeToVenue(String venueId) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore.collection(kEventSubscriptionsCollection).doc('${uid}_$venueId').set({
      kEventSubscriptionUserId: uid,
      kEventSubscriptionVenueId: venueId,
    });
    await _incrementVenueSubscribers(venueId, 1);
  }

  /// Отписаться от организатора.
  Future<void> unsubscribeFromVenue(String venueId) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore.collection(kEventSubscriptionsCollection).doc('${uid}_$venueId').delete();
    await _incrementVenueSubscribers(venueId, -1);
  }

  Future<void> _incrementVenueSubscribers(String venueId, int delta) async {
    final ref = _firestore.collection(kVenuesCollection).doc(venueId);
    final doc = await ref.get();
    if (doc.exists) {
      final current = (doc.data()?[kVenueSubscribersCount] as num?)?.toInt() ?? 0;
      await ref.update({kVenueSubscribersCount: (current + delta).clamp(0, 999999)});
    }
  }

  /// Проверить, подписан ли пользователь на venue.
  Future<bool> isSubscribedToVenue(String venueId) async {
    final uid = _uid;
    if (uid == null) return false;
    final doc = await _firestore.collection(kEventSubscriptionsCollection).doc('${uid}_$venueId').get();
    return doc.exists;
  }

  /// Присоединиться к мероприятию.
  Future<void> joinEvent(String eventId) async {
    final uid = _uid;
    if (uid == null) return;
    final existing = await _firestore
        .collection(kEventParticipantsCollection)
        .where(kEventParticipantEventId, isEqualTo: eventId)
        .where(kEventParticipantUserId, isEqualTo: uid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return; // уже участвует
    await _firestore.collection(kEventParticipantsCollection).add({
      kEventParticipantEventId: eventId,
      kEventParticipantUserId: uid,
    });
    final eventRef = _firestore.collection(kEventsCollection).doc(eventId);
    final eventSnap = await eventRef.get();
    if (eventSnap.exists) {
      final current = (eventSnap.data()?[kEventCurrentParticipants] as num?)?.toInt() ?? 0;
      final max = (eventSnap.data()?[kEventMaxParticipants] as num?)?.toInt() ?? 15;
      await eventRef.update({
        kEventCurrentParticipants: (current + 1).clamp(0, max),
        kEventStatus: current + 1 >= max ? 'full' : 'open',
      });
    }
  }

  /// Покинуть мероприятие.
  Future<void> leaveEvent(String eventId) async {
    final uid = _uid;
    if (uid == null) return;
    final snap = await _firestore
        .collection(kEventParticipantsCollection)
        .where(kEventParticipantEventId, isEqualTo: eventId)
        .where(kEventParticipantUserId, isEqualTo: uid)
        .limit(1)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
    final eventRef = _firestore.collection(kEventsCollection).doc(eventId);
    final eventSnap = await eventRef.get();
    if (eventSnap.exists) {
      final current = (eventSnap.data()?[kEventCurrentParticipants] as num?)?.toInt() ?? 0;
      await eventRef.update({
        kEventCurrentParticipants: (current - 1).clamp(0, 999),
        kEventStatus: 'open',
      });
    }
  }

  /// Переключить лайк мероприятия.
  Future<void> toggleEventLike(String eventId) async {
    final uid = _uid;
    if (uid == null) return;
    final ref = _firestore.collection(kEventsCollection).doc(eventId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final likedBy = List<String>.from((data[kEventLikedBy] as List?)?.map((e) => e.toString()) ?? []);
      if (likedBy.contains(uid)) {
        likedBy.remove(uid);
      } else {
        likedBy.add(uid);
      }
      tx.update(ref, {kEventLikedBy: likedBy});
    });
  }

  /// Получить мероприятие по id.
  Future<EventItem?> getEvent(String eventId) async {
    final uid = _uid;
    final doc = await _firestore.collection(kEventsCollection).doc(eventId).get();
    if (!doc.exists || doc.data() == null) return null;
    final joinedIds = uid != null ? await _getJoinedEventIds(uid) : <String>{};
    return EventItem.fromFirestore(doc, currentUserId: uid, joined: joinedIds.contains(eventId));
  }

  /// Получить организатора по id.
  Future<VenueItem?> getVenue(String venueId) async {
    final doc = await _firestore.collection(kVenuesCollection).doc(venueId).get();
    if (!doc.exists || doc.data() == null) return null;
    return VenueItem.fromFirestore(doc);
  }

  /// Список мест проведения (для вкладки «Места проведения»).
  Future<List<VenueItem>> getVenues({int limit = 30}) async {
    final snap = await _firestore.collection(kVenuesCollection).limit(limit).get();
    return snap.docs.map((d) => VenueItem.fromFirestore(d)).toList();
  }

  /// Поиск мероприятий по строке.
  Future<List<EventItem>> searchEvents(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return getNearbyEvents(limit: limit);
    final uid = _uid;
    final snap = await _firestore.collection(kEventsCollection).limit(limit * 2).get();
    final q = query.trim().toLowerCase();
    final filtered = snap.docs.where((d) {
      final data = d.data();
      final title = (data[kEventTitle] as String?)?.toLowerCase() ?? '';
      final venue = (data[kEventVenueName] as String?)?.toLowerCase() ?? '';
      return title.contains(q) || venue.contains(q);
    }).take(limit).toList();
    final joinedIds = uid != null ? await _getJoinedEventIds(uid) : <String>{};
    return filtered.map((d) => EventItem.fromFirestore(d, currentUserId: uid, joined: joinedIds.contains(d.id))).toList();
  }
}
