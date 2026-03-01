import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'activities_screen.dart';
import 'search_screen.dart';
import 'chats_screen.dart';
import 'profile_screen.dart';

/// Главный экран приложения с нижней навигацией: Лента, Активности, Поиск, Чаты, Профиль.
class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentIndex = 0;

  // Счётчики для бейджей (пока 0; позже — из Firestore/Stream: сообщения, новые в поиске)
  final int _searchUnreadCount = 0;
  final int _chatsUnreadCount = 0;

  static const List<_NavDestination> _destinations = [
    _NavDestination(icon: Icons.home_outlined, label: 'Лента'),
    _NavDestination(icon: Icons.explore_outlined, label: 'Активности'),
    _NavDestination(icon: Icons.search, label: 'Поиск', hasBadge: true),
    _NavDestination(icon: Icons.chat_bubble_outline, label: 'Чаты', hasBadge: true),
    _NavDestination(icon: Icons.person_outline, label: 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          FeedScreen(),
          ActivitiesScreen(),
          SearchScreen(),
          ChatsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_destinations.length, (index) {
                final d = _destinations[index];
                final isSelected = _currentIndex == index;
                int? badgeCount;
                if (index == 2) badgeCount = _searchUnreadCount;
                if (index == 3) badgeCount = _chatsUnreadCount;
                return InkWell(
                  onTap: () => setState(() => _currentIndex = index),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Badge(
                          isLabelVisible: badgeCount != null && badgeCount > 0,
                          label: badgeCount != null ? Text('$badgeCount') : null,
                          backgroundColor: Colors.red,
                          child: Icon(
                            d.icon,
                            size: 26,
                            color: isSelected ? const Color(0xFF81262B) : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? const Color(0xFF81262B) : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final String label;
  final bool hasBadge;

  const _NavDestination({
    required this.icon,
    required this.label,
    this.hasBadge = false,
  });
}
