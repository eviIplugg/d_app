class StoryItem {
  StoryItem({
    required this.id,
    required this.authorId,
    required this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
    this.caption,
    this.authorName,
    this.authorPhotoUrl,
  });

  final String id;
  final String authorId;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? caption;
  final String? authorName;
  final String? authorPhotoUrl;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class StoryBucket {
  StoryBucket({
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.stories,
  });

  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final List<StoryItem> stories;

  DateTime get latestCreatedAt => stories.last.createdAt;
}
