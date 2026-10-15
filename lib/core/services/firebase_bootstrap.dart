import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:vnest_app/core/services/bookings_repository.dart';
import 'package:vnest_app/core/services/grid_analytics_service.dart';

/// Bootstraps Firebase and wires repositories into analytics.
class FirebaseBootstrap {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<GridAnalyticsService> initAnalytics() async {
    final analytics = GridAnalyticsService();

    try {
      if (!_initialized) {
        await Firebase.initializeApp();
        _initialized = true;
      }
      analytics.configureRepository(FirestoreBookingsRepository());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase unavailable, using demo bookings: $e');
      }
      analytics.useDemoData();
    }

    return analytics;
  }
}
