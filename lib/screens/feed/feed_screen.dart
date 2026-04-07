import 'package:flutter/material.dart';
import 'feed_posts_body.dart';

/// Лента в стиле Instagram: сторис + посты. Добавление постов через кнопку «Добавить» в сторис.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Лента'),
      ),
      body: const FeedPostsBody(),
    );
  }
}
