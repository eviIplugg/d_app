import 'package:flutter/material.dart';
import 'dart:async';
import 'feed_events_body.dart';

/// Активности: мероприятия и места проведения. Вкладки, поиск, секции с карточками событий.
class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  int _tabIndex = 0; // 0 = Мероприятия, 1 = Места проведения
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _debouncedQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 260), () {
        if (!mounted) return;
        final q = _searchController.text.trim();
        if (_debouncedQuery != q) {
          setState(() => _debouncedQuery = q);
        }
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Активности',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: theme.colorScheme.onSurface),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.search, color: theme.colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final compact = c.maxWidth < 360;
                      return Row(
                        children: [
                          Expanded(
                            child: SegmentedButton<int>(
                              segments: [
                                ButtonSegment(value: 0, label: Text(compact ? 'События' : 'Мероприятия')),
                                ButtonSegment(value: 1, label: Text(compact ? 'Места' : 'Места проведения')),
                              ],
                              selected: {_tabIndex},
                              onSelectionChanged: (s) => setState(() => _tabIndex = s.first),
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) return const Color(0xFF81262B);
                                  return isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200;
                                }),
                                foregroundColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) return Colors.white;
                                  return isDark ? Colors.white70 : Colors.grey.shade700;
                                }),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск',
                      prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.grey),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2B2B2B) : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FeedEventsBody(
              tabIndex: _tabIndex,
              searchQuery: _debouncedQuery,
            ),
          ),
        ],
      ),
    );
  }
}
