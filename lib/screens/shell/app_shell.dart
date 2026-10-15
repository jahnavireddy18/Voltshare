import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _routes = ['/home', '/trips', '/energy', '/profile'];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/profile')) {
      _currentIndex = 3;
    } else if (location.startsWith('/energy')) {
      _currentIndex = 2;
    } else if (location.startsWith('/trips')) {
      _currentIndex = 1;
    } else {
      _currentIndex = 0;
    }

    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: isDark ? 0.05 : 0.3)),
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: NavigationBar(
            backgroundColor: cs.surfaceContainer,
            surfaceTintColor: Colors.transparent,
            indicatorColor: cs.primary.withValues(alpha: 0.1),
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTap,
            height: 72,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: cs.onSurfaceVariant),
                selectedIcon: Icon(Icons.home, color: cs.primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.route_outlined, color: cs.onSurfaceVariant),
                selectedIcon: Icon(Icons.route, color: cs.primary),
                label: 'Trips',
              ),
              NavigationDestination(
                icon: Icon(Icons.bolt_outlined, color: cs.onSurfaceVariant),
                selectedIcon: Icon(Icons.bolt, color: cs.primary),
                label: 'Energy',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline, color: cs.onSurfaceVariant),
                selectedIcon: Icon(Icons.person, color: cs.primary),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
