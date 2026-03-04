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
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          onPressed: () {},
        ),
        title: const Text('Лента', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
        actions: const [],
      ),
      body: const FeedPostsBody(),
    );
  }
}
