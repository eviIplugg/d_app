import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../models/feed_post.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/post_service.dart';

/// Карточка поста в стиле Instagram: аватар, имя, верификация, город, фото/карусель, лайк, тег, заголовок, дата/место/цена/рейтинг, подпись.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onTapAuthor,
  });

  final FeedPost post;
  final VoidCallback? onTapAuthor;

  static const Color _text = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    final isLiked = AuthService().currentUserId != null && post.isLikedBy(AuthService().currentUserId!);
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            authorName: post.authorName,
            authorPhotoUrl: post.authorPhotoUrl,
            authorCity: post.authorCity,
            authorVerified: post.authorVerified,
            onTap: onTapAuthor,
          ),
          _PhotoSection(
            photoUrls: post.displayPhotoUrls,
            isLiked: isLiked,
            likeCount: post.likeCount,
            onLikeTap: () => PostService().toggleLike(post.id),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.isActivity && post.activityTag != null && post.activityTag!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        post.activityTag!,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade800),
                      ),
                    ),
                  ),
                if (post.isActivity && post.activityTitle != null && post.activityTitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      post.activityTitle!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text),
                    ),
                  ),
                if (post.isActivity && (post.activityDate != null || post.activityVenue != null))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        if (post.activityDate != null) Text(post.activityDate!, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                        if (post.activityDate != null && post.activityVenue != null) Text(' ', style: TextStyle(color: Colors.grey.shade700)),
                        if (post.activityVenue != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(post.activityVenue!, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                              if (post.activityVenueVerified) Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(Icons.verified, size: 14, color: Colors.blue.shade700),
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
                      [if (post.activityPrice != null) post.activityPrice, if (post.activityRating != null) '⭐ ${post.activityRating}'].join(' '),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                _AuthorLine(
                  authorName: post.authorName,
                  authorPhotoUrl: post.authorPhotoUrl,
                  authorVerified: post.authorVerified,
                  authorCity: post.authorCity,
                  onTap: onTapAuthor,
                ),
                if (post.caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      post.caption,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.3),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.authorName,
    this.authorPhotoUrl,
    this.authorCity,
    this.authorVerified = false,
    this.onTap,
  });

  final String authorName;
  final String? authorPhotoUrl;
  final String? authorCity;
  final bool authorVerified;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: authorPhotoUrl != null && authorPhotoUrl!.isNotEmpty ? NetworkImage(authorPhotoUrl!) : null,
              child: authorPhotoUrl == null || authorPhotoUrl!.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
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
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _PostCardStatic._text),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (authorVerified) Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.verified, size: 16, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                  if (authorCity != null && authorCity!.isNotEmpty)
                    Text(
                      authorCity!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.more_horiz, color: Colors.grey.shade700),
              onPressed: () {},
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
  });

  final List<String> photoUrls;
  final bool isLiked;
  final int likeCount;
  final VoidCallback onLikeTap;

  @override
  State<_PhotoSection> createState() => _PhotoSectionState();
}

class _PhotoSectionState extends State<_PhotoSection> {
  int _currentPage = 0;

  Widget _postImage(String url) {
    if (url.startsWith('data:')) {
      try {
        final base64 = url.contains(',') ? url.split(',').last : url;
        final bytes = base64Decode(base64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, _) => const Center(child: Icon(Icons.broken_image, size: 48)),
        );
      } catch (_) {
        return const Center(child: Icon(Icons.broken_image, size: 48));
      }
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, _) => const Center(child: Icon(Icons.broken_image, size: 48)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photoUrls.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey)),
      );
    }
    return SizedBox(
      height: 360,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.photoUrls.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (ctx, i) => _postImage(widget.photoUrls[i]),
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
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onLikeTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.isLiked ? Icons.favorite : Icons.favorite_border, color: widget.isLiked ? Colors.red : Colors.white, size: 22),
                        if (widget.likeCount > 0) ...[
                          const SizedBox(width: 4),
                          Text('${widget.likeCount}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorLine extends StatelessWidget {
  const _AuthorLine({
    required this.authorName,
    this.authorPhotoUrl,
    this.authorVerified = false,
    this.authorCity,
    this.onTap,
  });

  final String authorName;
  final String? authorPhotoUrl;
  final bool authorVerified;
  final String? authorCity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundImage: authorPhotoUrl != null && authorPhotoUrl!.isNotEmpty ? NetworkImage(authorPhotoUrl!) : null,
            child: authorPhotoUrl == null || authorPhotoUrl!.isEmpty ? const Icon(Icons.person, size: 14, color: Colors.grey) : null,
          ),
          const SizedBox(width: 6),
          Text(
            authorName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _PostCardStatic._text),
          ),
          if (authorVerified) Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Icon(Icons.verified, size: 14, color: Colors.blue.shade700),
          ),
          if (authorCity != null && authorCity!.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(authorCity!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ],
      ),
    );
  }
}

class _PostCardStatic {
  static const Color _text = Color(0xFF333333);
}
