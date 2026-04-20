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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Поиск',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: theme.colorScheme.onSurfaceVariant),
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
