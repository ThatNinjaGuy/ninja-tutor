import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

/// Main navigation wrapper with bottom navigation bar
class MainNavigation extends ConsumerWidget {
  const MainNavigation({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);
    
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationProvider.notifier).state = index;
          _navigateToIndex(context, index);
        },
      ),
    );
  }

  void _navigateToIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.reading);
        break;
      case 2:
        context.go(AppRoutes.practice);
        break;
      case 3:
        context.go(AppRoutes.library);
        break;
      case 4:
        context.go(AppRoutes.notes);
        break;
    }
  }
}

/// Custom bottom navigation bar
class _BottomNavigationBar extends StatelessWidget {
  const _BottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: AppConstants.smallPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavigationItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Dashboard',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavigationItem(
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book,
                label: 'Reading',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavigationItem(
                icon: Icons.quiz_outlined,
                activeIcon: Icons.quiz,
                label: 'Practice',
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavigationItem(
                icon: Icons.library_books_outlined,
                activeIcon: Icons.library_books,
                label: 'Library',
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavigationItem(
                icon: Icons.sticky_note_2_outlined,
                activeIcon: Icons.sticky_note_2,
                label: 'Notes',
                isSelected: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual navigation item
class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppConstants.shortAnimation,
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected 
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: AppConstants.shortAnimation,
              style: theme.textTheme.labelSmall!.copyWith(
                color: isSelected 
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Responsive navigation for different screen sizes
class ResponsiveNavigation extends StatelessWidget {
  const ResponsiveNavigation({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Use side navigation for desktop/tablet
    if (screenWidth >= AppConstants.tabletBreakpoint) {
      return _SideNavigation(child: child);
    }
    
    // Use bottom navigation for mobile
    return MainNavigation(child: child);
  }
}

/// Side navigation for larger screens
class _SideNavigation extends ConsumerWidget {
  const _SideNavigation({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Row(
        children: [
          // Side navigation rail
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              ref.read(navigationProvider.notifier).state = index;
              _navigateToIndex(context, index);
            },
            backgroundColor: theme.colorScheme.surface,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: Text('Reading'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.quiz_outlined),
                selectedIcon: Icon(Icons.quiz),
                label: Text('Practice'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.library_books_outlined),
                selectedIcon: Icon(Icons.library_books),
                label: Text('Library'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.sticky_note_2_outlined),
                selectedIcon: Icon(Icons.sticky_note_2),
                label: Text('Notes'),
              ),
            ],
          ),
          
          // Vertical divider
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
          
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }

  void _navigateToIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.reading);
        break;
      case 2:
        context.go(AppRoutes.practice);
        break;
      case 3:
        context.go(AppRoutes.library);
        break;
      case 4:
        context.go(AppRoutes.notes);
        break;
    }
  }
}
