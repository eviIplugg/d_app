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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Активности',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF333333)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF333333)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
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
                                  return Colors.grey.shade200;
                                }),
                                foregroundColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) return Colors.white;
                                  return Colors.grey.shade700;
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
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade100,
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
