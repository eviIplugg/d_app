import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import '../../utils/web_layout.dart';
import 'activities_screen.dart';
import 'chats_screen.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

/// Главный экран: на узком вебе и мобилке — нижняя навигация; на широком вебе — [NavigationRail].
class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentIndex = 0;

  final int _searchUnreadCount = 0;

  static const List<_NavDestination> _destinations = [
    _NavDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Лента',
    ),
    _NavDestination(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: 'Активности',
    ),
    _NavDestination(
      icon: Icons.search,
      selectedIcon: Icons.search,
      label: 'Поиск',
      hasBadge: true,
    ),
    _NavDestination(
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      label: 'Чаты',
      hasBadge: true,
    ),
    _NavDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Профиль',
    ),
  ];

  static const List<Widget> _tabChildren = [
    RepaintBoundary(child: FeedScreen()),
    RepaintBoundary(child: ActivitiesScreen()),
    RepaintBoundary(child: SearchScreen()),
    RepaintBoundary(child: ChatsScreen()),
    RepaintBoundary(child: ProfileScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return StreamBuilder<int>(
      stream: ChatService().streamTotalUnreadCount(),
      builder: (context, snapshot) {
        final chatsUnreadCount = snapshot.data ?? 0;
        final useRail = WebLayout.useSideNavigation(context);
        final extendedRail = WebLayout.useExtendedRail(context);
        final narrowMax = WebLayout.narrowWebMaxWidth(context);

        Widget tabStack = IndexedStack(
          index: _currentIndex,
          children: _tabChildren,
        );

        if (narrowMax != null) {
          tabStack = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: narrowMax),
              child: tabStack,
            ),
          );
        } else if (useRail) {
          tabStack = Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: WebLayout.desktopContentMaxWidth),
              child: tabStack,
            ),
          );
        }

        if (useRail) {
          return Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NavigationRail(
                  extended: extendedRail,
                  backgroundColor: theme.colorScheme.surface,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (i) => setState(() => _currentIndex = i),
                  labelType: extendedRail
                      ? NavigationRailLabelType.all
                      : NavigationRailLabelType.selected,
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Text(
                      'Ring me.',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                  destinations: [
                    for (var i = 0; i < _destinations.length; i++)
                      _railDestination(
                        context,
                        _destinations[i],
                        i,
                        chatsUnreadCount,
                        _currentIndex == i,
                        primary,
                        onSurfaceVariant,
                      ),
                  ],
                ),
                VerticalDivider(thickness: 1, width: 1, color: theme.dividerColor),
                Expanded(child: tabStack),
              ],
            ),
          );
        }

        Widget bottomBar = Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.06),
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
                  if (index == 3) badgeCount = chatsUnreadCount;
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
                            backgroundColor: theme.colorScheme.error,
                            child: Icon(
                              isSelected ? d.selectedIcon : d.icon,
                              size: 26,
                              color: isSelected ? primary : onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isSelected ? primary : onSurfaceVariant,
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
        );

        if (narrowMax != null) {
          bottomBar = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: narrowMax),
              child: bottomBar,
            ),
          );
        }

        return Scaffold(
          body: tabStack,
          bottomNavigationBar: RepaintBoundary(child: bottomBar),
        );
      },
    );
  }

  NavigationRailDestination _railDestination(
    BuildContext context,
    _NavDestination d,
    int index,
    int chatsUnread,
    bool selected,
    Color primary,
    Color onSurfaceVariant,
  ) {
    int? badgeCount;
    if (index == 2) badgeCount = _searchUnreadCount;
    if (index == 3) badgeCount = chatsUnread;

    Widget iconWidget(IconData iconData) {
      final icon = Icon(iconData, color: selected ? primary : onSurfaceVariant);
      if (badgeCount == null || badgeCount <= 0) return icon;
      return Badge(
        label: Text('$badgeCount'),
        backgroundColor: Theme.of(context).colorScheme.error,
        child: icon,
      );
    }

    return NavigationRailDestination(
      icon: iconWidget(d.icon),
      selectedIcon: iconWidget(d.selectedIcon),
      label: Text(d.label),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool hasBadge;

  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.hasBadge = false,
  });
}
