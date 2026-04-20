import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../models/feed_post.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/post_service.dart';
import '../../../widgets/story_ring_avatar.dart';
import '../edit_post_screen.dart';
import 'post_comments_sheet.dart';

/// Карточка поста: шапка, фото, подпись под картинкой, активность, комментарии.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onTapAuthor,
    this.hasStory = false,
  });

  final FeedPost post;
  final VoidCallback? onTapAuthor;
  final bool hasStory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLiked =
        AuthService().currentUserId != null && post.isLikedBy(AuthService().currentUserId!);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            authorName: post.authorName,
            authorPhotoUrl: post.authorPhotoUrl,
            authorCity: post.authorCity,
            authorVerified: post.authorVerified,
            hasStory: hasStory,
            onTap: onTapAuthor,
            onMenu: () => _openPostMenu(context, post),
          ),
          _PhotoSection(
            photoUrls: post.displayPhotoUrls,
            isLiked: isLiked,
            likeCount: post.likeCount,
            onLikeTap: () => PostService().toggleLike(post.id),
            surfaceTint: cs.surfaceContainerHighest,
            onOpenGallery: (index) {
              final urls = post.displayPhotoUrls;
              if (urls.isEmpty) return;
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => PostPhotoGalleryScreen(
                    photoUrls: urls,
                    initialIndex: index.clamp(0, urls.length - 1),
                  ),
                ),
              );
            },
          ),
          // Подпись сразу под фото
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Text(
                post.caption,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface,
                  height: 1.35,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.isActivity && post.activityTag != null && post.activityTag!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        post.activityTag!,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                if (post.isActivity && post.activityTitle != null && post.activityTitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      post.activityTitle!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                if (post.isActivity && (post.activityDate != null || post.activityVenue != null))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        if (post.activityDate != null)
                          Text(
                            post.activityDate!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        if (post.activityDate != null && post.activityVenue != null)
                          Text(' ', style: TextStyle(color: cs.onSurfaceVariant)),
                        if (post.activityVenue != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                post.activityVenue!,
                                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                              ),
                              if (post.activityVenueVerified)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(Icons.verified, size: 14, color: cs.primary),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                if (post.isActivity && (post.activityPrice != null || post.activityRating != null))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      [
                        if (post.activityPrice != null) post.activityPrice,
                        if (post.activityRating != null) '⭐ ${post.activityRating}',
                      ].join(' '),
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 8, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showPostCommentsSheet(context, post.id),
                icon: Icon(Icons.chat_bubble_outline, size: 20, color: cs.primary),
                label: Text(
                  'Комментарии',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openPostMenu(BuildContext context, FeedPost post) async {
  final uid = AuthService().currentUserId;
  final isMine = uid != null && uid == post.authorId;
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMine) ...[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Редактировать'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
              title: Text('Удалить', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Пожаловаться'),
            onTap: () => Navigator.pop(ctx, 'report'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted || action == null) return;

  final posts = PostService();
  if (action == 'edit') {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EditPostScreen(post: post)),
    );
    return;
  }
  if (action == 'delete') {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить пост?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await posts.deletePost(post.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пост удалён')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
        }
      }
    }
    return;
  }
  if (action == 'report') {
    final reasonController = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Жалоба на пост'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Что не так?',
            hintText: 'Кратко опишите причину',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Отправить')),
        ],
      ),
    );
    final text = reasonController.text;
    reasonController.dispose();
    if (submit == true && context.mounted) {
      try {
        await posts.reportPost(postId: post.id, reason: text);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Жалоба отправлена')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
        }
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.authorName,
    this.authorPhotoUrl,
    this.authorCity,
    this.authorVerified = false,
    this.hasStory = false,
    this.onTap,
    required this.onMenu,
  });

  final String authorName;
  final String? authorPhotoUrl;
  final String? authorCity;
  final bool authorVerified;
  final bool hasStory;
  final VoidCallback? onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            StoryRingAvatar(
              radius: 20,
              photoUrl: authorPhotoUrl,
              hasStory: hasStory,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          authorName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (authorVerified)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified, size: 16, color: cs.primary),
                        ),
                    ],
                  ),
                  if (authorCity != null && authorCity!.isNotEmpty)
                    Text(
                      authorCity!,
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.more_horiz, color: cs.onSurfaceVariant),
              onPressed: onMenu,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoSection extends StatefulWidget {
  const _PhotoSection({
    required this.photoUrls,
    required this.isLiked,
    required this.likeCount,
    required this.onLikeTap,
    required this.surfaceTint,
    required this.onOpenGallery,
  });

  final List<String> photoUrls;
  final bool isLiked;
  final int likeCount;
  final Future<void> Function() onLikeTap;
  final Color surfaceTint;
  final void Function(int index) onOpenGallery;

  @override
  State<_PhotoSection> createState() => _PhotoSectionState();
}

class _PhotoSectionState extends State<_PhotoSection> {
  int _currentPage = 0;
  late bool _isLikedLocal;
  late int _likeCountLocal;

  @override
  void initState() {
    super.initState();
    _isLikedLocal = widget.isLiked;
    _likeCountLocal = widget.likeCount;
  }

  @override
  void didUpdateWidget(covariant _PhotoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) _isLikedLocal = widget.isLiked;
    if (oldWidget.likeCount != widget.likeCount) _likeCountLocal = widget.likeCount;
  }

  void _handleLikeTap() {
    final prevLiked = _isLikedLocal;
    final prevCount = _likeCountLocal;
    setState(() {
      _isLikedLocal = !prevLiked;
      _likeCountLocal = prevLiked ? (_likeCountLocal > 0 ? _likeCountLocal - 1 : 0) : _likeCountLocal + 1;
    });
    widget.onLikeTap().then(
      (_) {},
      onError: (Object e, StackTrace _) {
        if (!mounted) return;
        setState(() {
          _isLikedLocal = prevLiked;
          _likeCountLocal = prevCount;
        });
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Не удалось: $e'), backgroundColor: Colors.red),
        );
      },
    );
  }

  Widget _postImage(String url) {
    if (url.startsWith('data:')) {
      try {
        final base64 = url.contains(',') ? url.split(',').last : url;
        final bytes = base64Decode(base64);
        return SizedBox.expand(
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 48)),
          ),
        );
      } catch (_) {
        return const Center(child: Icon(Icons.broken_image, size: 48));
      }
    }
    return SizedBox.expand(
      child: Image.network(
      url,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return ColoredBox(
          color: widget.surfaceTint,
          child: SizedBox(
            height: 300,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 48)),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.photoUrls.isEmpty) {
      return SizedBox(
        height: 200,
        child: ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(Icons.image_not_supported, size: 48, color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }
    return SizedBox(
      height: 268,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () => widget.onOpenGallery(_currentPage),
        child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.photoUrls.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (ctx, i) => RepaintBoundary(child: _postImage(widget.photoUrls[i])),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Material(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
              child: IconButton(
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                onPressed: () => widget.onOpenGallery(_currentPage),
                tooltip: 'На весь экран',
              ),
            ),
          ),
          if (widget.photoUrls.length > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPage + 1}/${widget.photoUrls.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          Positioned(
            bottom: 12,
            right: 12,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleLikeTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLikedLocal ? Icons.favorite : Icons.favorite_border,
                      color: _isLikedLocal ? Colors.redAccent : Colors.white,
                      size: 22,
                    ),
                    if (_likeCountLocal > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '$_likeCountLocal',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

/// Полноэкранный просмотр фото поста с листанием.
class PostPhotoGalleryScreen extends StatefulWidget {
  const PostPhotoGalleryScreen({
    super.key,
    required this.photoUrls,
    this.initialIndex = 0,
  });

  final List<String> photoUrls;
  final int initialIndex;

  @override
  State<PostPhotoGalleryScreen> createState() => _PostPhotoGalleryScreenState();
}

class _PostPhotoGalleryScreenState extends State<PostPhotoGalleryScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    final max = widget.photoUrls.isEmpty ? 0 : widget.photoUrls.length - 1;
    final start = widget.initialIndex.clamp(0, max);
    _index = start;
    _controller = PageController(initialPage: start);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _pageImage(String url) {
    if (url.startsWith('data:')) {
      try {
        final base64 = url.contains(',') ? url.split(',').last : url;
        final bytes = base64Decode(base64);
        return InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.memory(bytes, fit: BoxFit.contain),
        );
      } catch (_) {
        return const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.white54));
      }
    }
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(color: Colors.white54));
        },
        errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.white54)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.photoUrls.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          n > 0 ? '${_index + 1} / $n' : '0',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: n == 0
          ? const Center(child: Text('Нет фото', style: TextStyle(color: Colors.white70)))
          : PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: n,
              itemBuilder: (_, i) => Center(child: _pageImage(widget.photoUrls[i])),
            ),
    );
  }
}

