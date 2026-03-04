import 'package:flutter/material.dart';

import 'feed_content.dart';
import 'feed_filters_screen.dart';

/// Поиск: анкеты по фильтрам и ближайшей геопозиции (сначала тот же город). Фильтры в кнопке AppBar.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final GlobalKey<FeedContentState> _feedKey = GlobalKey<FeedContentState>();

  static const Color _titleColor = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Поиск',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _titleColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: Colors.grey.shade700),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const FeedFiltersScreen()),
              );
              _feedKey.currentState?.loadCandidates();
            },
          ),
        ],
      ),
      body: FeedContent(key: _feedKey),
    );
  }
}
