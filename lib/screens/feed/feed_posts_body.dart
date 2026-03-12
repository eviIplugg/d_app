import 'package:flutter/material.dart';
import '../../firebase/firestore_schema.dart';
import '../../models/feed_post.dart';
import '../../services/auth/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/post_service.dart';
import 'create_post_screen.dart';
import 'widgets/post_card.dart';

/// Лента в стиле Instagram: ряд «сторис» (Добавить + аватары мэтчей), ниже — список постов.
class FeedPostsBody extends StatefulWidget {
  const FeedPostsBody({super.key});

  @override
  State<FeedPostsBody> createState() => _FeedPostsBodyState();
}

class _FeedPostsBodyState extends State<FeedPostsBody> {
  final PostService _postService = PostService();
  final AuthService _auth = AuthService();
  Map<String, _AuthorInfo> _authors = {};

  Future<void> _loadAuthors(Iterable<String> authorIds) async {
    if (authorIds.isEmpty) return;
    final ids = authorIds.toSet().toList();
    final futures = ids.map((id) => _auth.getUserProfile(id));
    final results = await Future.wait(futures);
    if (!mounted) return;
    final map = <String, _AuthorInfo>{};
    for (var i = 0; i < ids.length; i++) {
      final d = results[i];
      if (d == null) continue;
      final photos = d[kUserPhotos];
      String? photoUrl;
      if (photos is List && photos.isNotEmpty) photoUrl = photos.first?.toString();
      map[ids[i]] = _AuthorInfo(
        name: d[kUserName]?.toString() ?? 'Пользователь',
        photoUrl: photoUrl,
        city: d[kUserCity]?.toString(),
        verified: d[kUserVerificationStatus] == 'verified',
      );
    }
    setState(() => _authors = {..._authors, ...map});
  }

  List<FeedPost> _enrichPosts(List<FeedPost> posts) {
    return posts.map((p) {
      final info = _authors[p.authorId];
      if (info == null) return p;
      final copy = FeedPost(
        id: p.id,
        authorId: p.authorId,
        photoUrls: p.photoUrls,
        photoDataUrls: p.photoDataUrls,
        caption: p.caption,
        createdAt: p.createdAt,
        type: p.type,
        likeCount: p.likeCount,
        likedBy: p.likedBy,
        activityTitle: p.activityTitle,
        activityDate: p.activityDate,
        activityVenue: p.activityVenue,
        activityVenueVerified: p.activityVenueVerified,
        activityPrice: p.activityPrice,
        activityRating: p.activityRating,
        activityTag: p.activityTag,
      );
      copy.authorName = info.name;
      copy.authorPhotoUrl = info.photoUrl;
      copy.authorCity = info.city;
      copy.authorVerified = info.verified;
      return copy;
    }).toList();
  }

  void _openCreatePost() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const CreatePostScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _StoriesRow(onAddTap: _openCreatePost),
        ),
        StreamBuilder<List<FeedPost>>(
          stream: _postService.streamPosts(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Не удалось загрузить ленту',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error?.toString() ?? 'Ошибка',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Повторить'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF81262B)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF81262B))));
            }
            final posts = snapshot.data ?? [];
            if (posts.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Пока нет постов', style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _openCreatePost,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить пост'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final authorIds = posts.map((p) => p.authorId).toSet().where((id) => !_authors.containsKey(id));
            if (authorIds.isNotEmpty) {
              _loadAuthors(authorIds);
            }
            final enriched = _enrichPosts(posts);
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => PostCard(post: enriched[index]),
                childCount: enriched.length,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AuthorInfo {
  final String name;
  final String? photoUrl;
  final String? city;
  final bool verified;
  _AuthorInfo({required this.name, this.photoUrl, this.city, this.verified = false});
}

class _StoriesRow extends StatelessWidget {
  const _StoriesRow({required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 88,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _AddStoryChip(onTap: onAddTap),
            StreamBuilder<List<ChatListItem>>(
              stream: ChatService().streamChatList(),
              builder: (context, snapshot) {
                final list = snapshot.data ?? [];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: list.take(12).map((item) => Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _StoryAvatar(
                      name: item.otherName,
                      photoUrl: item.otherPhotoUrl,
                      hasNew: item.unreadCount > 0,
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStoryChip extends StatelessWidget {
  const _AddStoryChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.grey.shade400, width: 2),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 6),
            Text(
              'Добавить',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  const _StoryAvatar({
    required this.name,
    this.photoUrl,
    this.hasNew = false,
  });

  final String name;
  final String? photoUrl;
  final bool hasNew;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: hasNew
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF81262B), width: 2),
                )
              : null,
          child: CircleAvatar(
            radius: 28,
            backgroundImage: photoUrl != null && photoUrl!.isNotEmpty ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null || photoUrl!.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 56,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
