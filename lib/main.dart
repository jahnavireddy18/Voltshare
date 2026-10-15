import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vnest_app/core/router/app_router.dart';
import 'package:vnest_app/core/theme/app_theme.dart';
import 'package:vnest_app/core/theme/theme_notifier.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/services/notification_service.dart';

import 'package:vnest_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved theme preference.
  await ThemeNotifier().load();

  // Firebase & notifications may fail on web or without proper config.
  // Don't let that block the UI from rendering.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (!kIsWeb) {
      await NotificationService().initialize(AppRouter.router);
      // Using a hardcoded demo user ID for registration
      await NotificationService().registerToken('user_demo_01');
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(const VNestApp());
}

class VNestApp extends StatelessWidget {
  const VNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeNotifier(),
      builder: (context, _) {
        return ListenableBuilder(
          listenable: AuthProvider(),
          builder: (context, _) {
            return MaterialApp.router(
              title: 'VoltShare',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeNotifier().themeMode,
              routerConfig: AppRouter.router,
            );
          },
        );
      },
    );
  }
}

