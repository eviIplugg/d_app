import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../firebase/firestore_schema.dart';
import '../../models/story_item.dart';
import '../../models/feed_post.dart';
import '../../services/auth/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/story_service.dart';
import '../../widgets/story_ring_avatar.dart';
import 'create_post_screen.dart';
import 'story_viewer_screen.dart';
import 'widgets/post_card.dart';

/// Лента в стиле Instagram: ряд «сторис» (Добавить + аватары мэтчей), ниже — список постов.
class FeedPostsBody extends StatefulWidget {
  const FeedPostsBody({super.key});

  @override
  State<FeedPostsBody> createState() => _FeedPostsBodyState();
}

class _FeedPostsBodyState extends State<FeedPostsBody> {
  final PostService _postService = PostService();
  final StoryService _storyService = StoryService();
  final AuthService _auth = AuthService();
  Map<String, _AuthorInfo> _authors = {};
  final Set<String> _authorIdsQueued = {};
  Timer? _authorDebounce;

  @override
  void dispose() {
    _authorDebounce?.cancel();
    super.dispose();
  }

  /// Не вызывать загрузку авторов из build напрямую — только через debounce.
  void _scheduleAuthorLoads(Iterable<String> authorIds) {
    var any = false;
    for (final id in authorIds) {
      if (id.trim().isEmpty || _authors.containsKey(id)) continue;
      _authorIdsQueued.add(id);
      any = true;
    }
    if (!any) return;
    _authorDebounce?.cancel();
    _authorDebounce = Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      final ids = _authorIdsQueued.toList();
      _authorIdsQueued.clear();
      _loadAuthors(ids);
    });
  }

  Future<void> _loadAuthors(Iterable<String> authorIds) async {
    if (authorIds.isEmpty) return;
    final ids = authorIds.where((id) => id.trim().isNotEmpty && !_authors.containsKey(id)).toSet().toList();
    if (ids.isEmpty) return;
    final futures = ids.map((id) => _auth.getUserProfile(id, forceRefresh: true));
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
        photoUrlsIn: p.photoUrls,
        photoDataUrlsIn: p.photoDataUrls,
        caption: p.caption,
        createdAt: p.createdAt,
        type: p.type,
        likeCount: p.likeCount,
        likedByIn: p.likedBy,
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

  Future<void> _openCreateStory() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Публикуем историю...')),
    );
    final id = await _storyService.createStory(image: xFile);
    if (!mounted) return;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось опубликовать историю'), backgroundColor: Colors.red),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('История опубликована на 24 часа'), backgroundColor: Colors.green),
    );
  }

  Future<void> _openCreateMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_stories),
              title: const Text('Добавить историю (24 часа)'),
              onTap: () => Navigator.of(ctx).pop('story'),
            ),
            ListTile(
              leading: const Icon(Icons.add_photo_alternate_outlined),
              title: const Text('Создать пост'),
              onTap: () => Navigator.of(ctx).pop('post'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'story') {
      await _openCreateStory();
    } else if (choice == 'post') {
      _openCreatePost();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StoryBucket>>(
      stream: _storyService.streamStoryBuckets(),
      builder: (context, storySnap) {
        final storyBuckets = storySnap.data ?? const <StoryBucket>[];
        final storiesByAuthor = <String, StoryBucket>{for (final b in storyBuckets) b.authorId: b};
        return CustomScrollView(
          cacheExtent: 320,
          slivers: [
            SliverToBoxAdapter(
              child: _StoriesRow(
                onAddTap: _openCreateMenu,
                buckets: storyBuckets,
              ),
            ),
            StreamBuilder<List<FeedPost>>(
              stream: _postService.streamPosts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final theme = Theme.of(context);
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'Не удалось загрузить ленту',
                              style: theme.textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error?.toString() ?? 'Ошибка',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () => setState(() {}),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Повторить'),
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
                  final theme = Theme.of(context);
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_outlined, size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text('Пока нет постов', style: theme.textTheme.titleMedium),
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
                _scheduleAuthorLoads(posts.map((p) => p.authorId));
                final enriched = _enrichPosts(posts);
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = enriched[index];
                      final authorStories = storiesByAuthor[post.authorId];
                      return RepaintBoundary(
                        child: PostCard(
                          post: post,
                          hasStory: authorStories != null,
                          onTapAuthor: authorStories == null
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => StoryViewerScreen(
                                        stories: authorStories.stories,
                                        authorName: authorStories.authorName,
                                        authorPhotoUrl: authorStories.authorPhotoUrl,
                                      ),
                                    ),
                                  );
                                },
                        ),
                      );
                    },
                    childCount: enriched.length,
                    addAutomaticKeepAlives: true,
                    addRepaintBoundaries: false,
                  ),
                );
              },
            ),
          ],
        );
      },
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
  const _StoriesRow({required this.onAddTap, required this.buckets});

  final VoidCallback onAddTap;
  final List<StoryBucket> buckets;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 88,
        child: Builder(
          builder: (context) {
            final take = buckets.length > 12 ? 12 : buckets.length;
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 1 + take,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _AddStoryChip(onTap: onAddTap),
                  );
                }
                final bucket = buckets[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _StoryAvatar(
                    name: bucket.authorName,
                    photoUrl: bucket.authorPhotoUrl,
                    hasNew: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StoryViewerScreen(
                            stories: bucket.stories,
                            authorName: bucket.authorName,
                            authorPhotoUrl: bucket.authorPhotoUrl,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
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
    return SizedBox(
      width: 56,
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 2),
              ),
              child: Icon(Icons.add, color: Theme.of(context).colorScheme.primary, size: 32),
            ),
            const SizedBox(height: 6),
            Text(
              'Добавить',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    required this.onTap,
  });

  final String name;
  final String? photoUrl;
  final bool hasNew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StoryRingAvatar(
              radius: 28,
              photoUrl: photoUrl,
              hasStory: hasNew,
            ),
            const SizedBox(height: 4),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
