import 'package:flutter/material.dart';
import 'package:vnest_app/core/services/firebase_bootstrap.dart';
import 'package:vnest_app/core/services/grid_analytics_service.dart';
import 'package:vnest_app/screens/energy/grid_load_dashboard_screen.dart';

/// Energy tab — hosts the Grid Load Distribution Dashboard.
class EnergyScreen extends StatefulWidget {
  const EnergyScreen({super.key});

  @override
  State<EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends State<EnergyScreen> {
  GridAnalyticsService? _analytics;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final analytics = await FirebaseBootstrap.initAnalytics();
    if (mounted) setState(() => _analytics = analytics);
  }

  @override
  Widget build(BuildContext context) {
    if (_analytics == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return GridLoadDashboardScreen(analytics: _analytics!);
  }
}
