import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firestore_schema.dart';

/// Модель пользователя для карточки в ленте (данные из Firestore users).
class FeedUser {
  final String uid;
  final String name;
  final int? age;
  final String? city;
  final double? distanceKm;
  final String relationshipGoalLabel;
  final bool isVerified;
  final List<String> photoUrls;
  final String? bio;
  final List<String> interests;

  const FeedUser({
    required this.uid,
    required this.name,
    this.age,
    this.city,
    this.distanceKm,
    this.relationshipGoalLabel = '',
    this.isVerified = false,
    this.photoUrls = const [],
    this.bio,
    this.interests = const [],
  });

  static FeedUser fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final photos = d[kUserPhotos];
    final List<String> urls = photos is List
        ? (photos).map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : [];
    final inter = d[kUserInterests];
    final List<String> interestList = inter is List
        ? (inter).map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : [];

    int? age;
    final birthdate = d[kUserBirthdate];
    if (birthdate is Timestamp) {
      final bd = birthdate.toDate();
      final now = DateTime.now();
      age = now.year - bd.year;
      if (now.month < bd.month || (now.month == bd.month && now.day < bd.day)) age--;
    } else if (d['age'] != null) {
      age = (d['age'] is int) ? d['age'] as int : int.tryParse(d['age'].toString());
    }

    final goal = d[kUserRelationshipGoal]?.toString() ?? '';
    final goalLabel = goal == 'friendship'
        ? 'Дружба'
        : goal == 'communication'
            ? 'Общение'
            : goal == 'relationship'
                ? 'Отношения'
                : goal.isNotEmpty
                    ? goal
                    : '';

    final status = d[kUserVerificationStatus]?.toString() ?? 'none';

    return FeedUser(
      uid: doc.id,
      name: d[kUserName]?.toString().trim() ?? 'Без имени',
      age: age,
      city: d[kUserCity]?.toString(),
      distanceKm: null,
      relationshipGoalLabel: goalLabel,
      isVerified: status == 'verified',
      photoUrls: urls,
      bio: d[kUserBio]?.toString(),
      interests: interestList,
    );
  }
}
