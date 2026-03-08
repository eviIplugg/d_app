import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firestore_schema.dart';

/// Мероприятие в ленте: карточка и страница события.
class EventItem {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final List<String> photoUrls;
  final DateTime? dateTime;
  final String? venueId;
  final String? venueName;
  final bool venueVerified;
  final String? address;
  final String? city;
  final String? price;
  final double? rating;
  final String status; // 'open' | 'full'
  final int currentParticipants;
  final int maxParticipants;
  final List<String> likedBy;
  final bool isLiked;
  final bool isJoined;

  const EventItem({
    required this.id,
    this.title = '',
    this.description,
    this.imageUrl,
    this.photoUrls = const [],
    this.dateTime,
    this.venueId,
    this.venueName,
    this.venueVerified = false,
    this.address,
    this.city,
    this.price,
    this.rating,
    this.status = 'open',
    this.currentParticipants = 0,
    this.maxParticipants = 15,
    this.likedBy = const [],
    this.isLiked = false,
    this.isJoined = false,
  });

  String get statusLabel => status == 'full' ? 'Заполнено' : 'Открыто';
  String get dateTimeLabel {
    if (dateTime == null) return '';
    final d = dateTime!;
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final dayName = d.weekday >= 1 && d.weekday <= 7 ? days[d.weekday - 1] : '';
    return '$dayName ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static EventItem fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, {String? currentUserId, bool joined = false}) {
    final d = doc.data() ?? {};
    final t = d[kEventDateTime];
    DateTime? dt;
    if (t is Timestamp) dt = t.toDate();
    else if (t is DateTime) dt = t;
    final photos = d[kEventPhotoUrls];
    final List<String> urls = photos is List
        ? (photos).map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : [];
    final img = d[kEventImageUrl]?.toString();
    final liked = d[kEventLikedBy];
    final List<String> likedList = liked is List
        ? (liked).map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : [];
    return EventItem(
      id: doc.id,
      title: d[kEventTitle]?.toString() ?? '',
      description: d[kEventDescription]?.toString(),
      imageUrl: img?.isNotEmpty == true ? img : (urls.isNotEmpty ? urls.first : null),
      photoUrls: urls.isNotEmpty ? urls : (img != null ? [img] : []),
      dateTime: dt,
      venueId: d[kEventVenueId]?.toString(),
      venueName: d[kEventVenueName]?.toString(),
      venueVerified: d[kEventVenueVerified] == true,
      address: d[kEventAddress]?.toString(),
      city: d[kEventCity]?.toString(),
      price: d[kEventPrice]?.toString(),
      rating: (d[kEventRating] is num) ? (d[kEventRating] as num).toDouble() : null,
      status: d[kEventStatus]?.toString() ?? 'open',
      currentParticipants: (d[kEventCurrentParticipants] is int) ? d[kEventCurrentParticipants] as int : 0,
      maxParticipants: (d[kEventMaxParticipants] is int) ? d[kEventMaxParticipants] as int : 15,
      likedBy: likedList,
      isLiked: currentUserId != null && likedList.contains(currentUserId),
      isJoined: joined,
    );
  }
}

/// Место проведения / организатор.
class VenueItem {
  final String id;
  final String name;
  final String? photoUrl;
  final bool verified;
  final int eventsCount;
  final int subscribersCount;
  final String? address;
  final String? city;

  const VenueItem({
    required this.id,
    this.name = '',
    this.photoUrl,
    this.verified = false,
    this.eventsCount = 0,
    this.subscribersCount = 0,
    this.address,
    this.city,
  });

  static VenueItem fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return VenueItem(
      id: doc.id,
      name: d[kVenueName]?.toString() ?? '',
      photoUrl: d[kVenuePhotoUrl]?.toString(),
      verified: d[kVenueVerified] == true,
      eventsCount: (d[kVenueEventsCount] is int) ? d[kVenueEventsCount] as int : 0,
      subscribersCount: (d[kVenueSubscribersCount] is int) ? d[kVenueSubscribersCount] as int : 0,
      address: d[kVenueAddress]?.toString(),
      city: d[kVenueCity]?.toString(),
    );
  }
}
