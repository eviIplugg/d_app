import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firestore_schema.dart';

/// Пост в ленте: личный (фото + подпись) или активность (событие с местом, ценой и т.д.).
class FeedPost {
  final String id;
  final String authorId;
  final List<String> photoUrls;
  final List<String> photoDataUrls; // data:image/jpeg;base64,... когда нет Storage
  final String caption;
  final DateTime createdAt;
  final String type; // 'personal' | 'activity'
  final int likeCount;
  final List<String> likedBy;

  // Автор (подгружается отдельно)
  String authorName = 'Пользователь';
  String? authorPhotoUrl;
  String? authorCity;
  bool authorVerified = false;

  // Поля активности
  final String? activityTitle;
  final String? activityDate;
  final String? activityVenue;
  final bool activityVenueVerified;
  final String? activityPrice;
  final String? activityRating;
  final String? activityTag;

  FeedPost({
    required this.id,
    required this.authorId,
    List<String>? photoUrlsIn,
    List<String>? photoDataUrlsIn,
    this.caption = '',
    required this.createdAt,
    this.type = 'personal',
    this.likeCount = 0,
    List<String>? likedByIn,
    this.activityTitle,
    this.activityDate,
    this.activityVenue,
    this.activityVenueVerified = false,
    this.activityPrice,
    this.activityRating,
    this.activityTag,
  })  : photoUrls = _nonEmptyStringList(photoUrlsIn),
        photoDataUrls = _nonEmptyStringList(photoDataUrlsIn),
        likedBy = _nonEmptyStringList(likedByIn);

  static List<String> _nonEmptyStringList(List<String>? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return List<String>.from(raw.map((e) => e.trim()).where((s) => s.isNotEmpty));
  }

  bool get isActivity => type == 'activity';
  bool isLikedBy(String userId) => likedBy.contains(userId);

  /// URL или data URL для отображения (сначала photoUrls, иначе photoDataUrls).
  List<String> get displayPhotoUrls {
    if (photoUrls.isNotEmpty) return List<String>.from(photoUrls);
    if (photoDataUrls.isNotEmpty) return List<String>.from(photoDataUrls);
    return const <String>[];
  }

  static FeedPost fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final photos = d[kPostPhotoUrls];
    final List<String> urls = photos is List
        ? (photos).map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : [];
    final liked = d[kPostLikedBy];
    final List<String> likedList = liked is List
        ? (liked).map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : [];
    final t = d[kPostCreatedAt];
    final createdAt = t is Timestamp ? t.toDate() : DateTime.now();

    final dataUrls = d[kPostPhotoDataUrls];
    final List<String> dataUrlList = dataUrls is List
        ? (dataUrls).map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : [];
    return FeedPost(
      id: doc.id,
      authorId: d[kPostAuthorId]?.toString() ?? '',
      photoUrlsIn: urls,
      photoDataUrlsIn: dataUrlList,
      caption: d[kPostCaption]?.toString() ?? '',
      createdAt: createdAt,
      type: d[kPostType]?.toString() ?? 'personal',
      likeCount: (d[kPostLikeCount] is int) ? d[kPostLikeCount] as int : 0,
      likedByIn: likedList,
      activityTitle: d[kPostActivityTitle]?.toString(),
      activityDate: d[kPostActivityDate]?.toString(),
      activityVenue: d[kPostActivityVenue]?.toString(),
      activityVenueVerified: d[kPostActivityVenueVerified] == true,
      activityPrice: d[kPostActivityPrice]?.toString(),
      activityRating: d[kPostActivityRating]?.toString(),
      activityTag: d[kPostActivityTag]?.toString(),
    );
  }
}
