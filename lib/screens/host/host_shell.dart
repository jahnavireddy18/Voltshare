import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class HostShell extends StatefulWidget {
  final Widget child;
  const HostShell({super.key, required this.child});

  @override
  State<HostShell> createState() => _HostShellState();
}

class _HostShellState extends State<HostShell> {
  int _currentIndex = 0;

  static const _routes = [
    '/host/dashboard',
    '/host/chargers',
    '/host/earnings',
    '/host/settings',
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/host/settings')) {
      _currentIndex = 3;
    } else if (location.startsWith('/host/earnings')) {
      _currentIndex = 2;
    } else if (location.startsWith('/host/chargers')) {
      _currentIndex = 1;
    } else {
      _currentIndex = 0;
    }

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
                icon: Icon(Icons.dashboard_outlined, color: cs.onSurfaceVariant),
                selectedIcon: Icon(Icons.dashboard, color: cs.primary),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.ev_station_outlined, color: cs.onSurfaceVariant),
                selectedIcon: Icon(Icons.ev_station, color: cs.primary),
                label: 'Chargers',
              ),
              NavigationDestination(
                icon: Icon(Icons.attach_money, color: cs.onSurfaceVariant),
                selectedIcon: Icon(Icons.attach_money, color: cs.primary),
                label: 'Earnings',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined, color: cs.onSurfaceVariant),
                selectedIcon: Icon(Icons.settings, color: cs.primary),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
