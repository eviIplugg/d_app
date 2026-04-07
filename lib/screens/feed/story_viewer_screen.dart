import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/story_item.dart';

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.authorName,
    this.authorPhotoUrl,
  });

  final List<StoryItem> stories;
  final String authorName;
  final String? authorPhotoUrl;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  static const Duration _storyDuration = Duration(seconds: 6);
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _progress = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) return;
      final next = _progress + 60 / _storyDuration.inMilliseconds;
      if (next >= 1) {
        _next();
      } else {
        setState(() => _progress = next);
      }
    });
  }

  void _next() {
    if (_index >= widget.stories.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index++;
      _progress = 0;
    });
    _controller.animateToPage(_index, duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
    _startTicker();
  }

  void _prev() {
    if (_index <= 0) return;
    setState(() {
      _index--;
      _progress = 0;
    });
    _controller.animateToPage(_index, duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
    _startTicker();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.stories[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              itemBuilder: (context, i) => Image.network(
                widget.stories[i].imageUrl,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image_outlined, color: Colors.white70, size: 56),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(widget.stories.length, (i) {
                  final value = i < _index ? 1.0 : (i == _index ? _progress : 0.0);
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              top: 18,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: widget.authorPhotoUrl != null && widget.authorPhotoUrl!.isNotEmpty
                        ? NetworkImage(widget.authorPhotoUrl!)
                        : null,
                    child: widget.authorPhotoUrl == null || widget.authorPhotoUrl!.isEmpty
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.authorName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            if ((active.caption ?? '').trim().isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    active.caption!.trim(),
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _prev,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _next,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
