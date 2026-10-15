import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/services/auth_guard.dart';
import 'package:vnest_app/core/models/charger_model.dart';
import 'package:vnest_app/core/models/booking_model.dart';
import 'package:vnest_app/core/models/session_model.dart';
import 'package:vnest_app/screens/onboarding/onboarding_screen.dart';
import 'package:vnest_app/screens/auth/login_screen.dart';
import 'package:vnest_app/screens/auth/signup_screen.dart';
import 'package:vnest_app/screens/auth/forgot_password_screen.dart';
import 'package:vnest_app/screens/auth/otp_verification_screen.dart';
import 'package:vnest_app/screens/auth/otp_success_screen.dart';
import 'package:vnest_app/screens/auth/role_selection_screen.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/screens/home/charger_map_screen.dart';
import 'package:vnest_app/screens/home/charger_details_screen.dart';
import 'package:vnest_app/screens/booking/book_confirm_screen.dart';
import 'package:vnest_app/screens/booking/booking_success_screen.dart';
import 'package:vnest_app/screens/booking/booking_history_screen.dart';
import 'package:vnest_app/screens/booking/booking_details_screen.dart';
import 'package:vnest_app/screens/session/arrived_map_screen.dart';
import 'package:vnest_app/screens/session/active_session_screen.dart';
import 'package:vnest_app/screens/profile/profile_screen.dart';
import 'package:vnest_app/screens/profile/payment_methods_screen.dart';
import 'package:vnest_app/screens/profile/notification_preferences_screen.dart';
import 'package:vnest_app/screens/profile/help_support_screen.dart';
import 'package:vnest_app/screens/profile/privacy_screen.dart';
import 'package:vnest_app/screens/profile/privacy_policy_screen.dart';
import 'package:vnest_app/screens/profile/terms_of_service_screen.dart';
import 'package:vnest_app/screens/profile/vehicles_screen.dart';
import 'package:vnest_app/screens/profile/favorites_screen.dart';
import 'package:vnest_app/screens/shell/app_shell.dart';
import 'package:vnest_app/screens/trips/trip_planner_screen.dart';
import 'package:vnest_app/screens/energy/energy_screen.dart';
import 'package:vnest_app/screens/carplay/car_dashboard_screen.dart';
import 'package:vnest_app/screens/host/host_telemetry_dashboard_screen.dart';
import 'package:vnest_app/screens/host/host_shell.dart';
import 'package:vnest_app/screens/host/host_dashboard_screen.dart';
import 'package:vnest_app/screens/host/fleet_manager_screen.dart';
import 'package:vnest_app/screens/host/charger_form_screen.dart';
import 'package:vnest_app/screens/host/host_chat_screen.dart';
import 'package:vnest_app/screens/host/rate_session_screen.dart';
import 'package:vnest_app/screens/host/host_placeholder_screens.dart';
import 'package:vnest_app/screens/admin/society_admin_dashboard_screen.dart';
import 'package:vnest_app/screens/support/live_chat_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: AuthProvider(),
    redirect: AuthGuard.redirect,
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SignupScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/otp-verification',
        name: 'otp-verification',
        pageBuilder: (context, state) {
          final extra = state.extra;
          String phone = '';
          String? name;
          UserRole? role;
          if (extra is Map<String, dynamic>) {
            phone = extra['phoneNumber'] as String? ?? '';
            name = extra['name'] as String?;
            role = extra['role'] as UserRole?;
          } else if (extra is String) {
            phone = extra;
          } else {
            phone = state.uri.queryParameters['phone'] ?? '';
          }
          return CustomTransitionPage(
            key: state.pageKey,
            child: OtpVerificationScreen(
              phoneNumber: phone,
              name: name,
              role: role,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              final tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: Curves.easeInOutCubic));
              return SlideTransition(
                  position: animation.drive(tween), child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/otp-success',
        name: 'otp-success',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OtpSuccessScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RoleSelectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),

      // App Shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChargerMapScreen(),
            ),
          ),
          GoRoute(
            path: '/trips',
            name: 'trips',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TripPlannerScreen(),
            ),
          ),
          GoRoute(
            path: '/energy',
            name: 'energy',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EnergyScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Detail screens (outside shell)
      GoRoute(
        path: '/charger-details',
        name: 'charger-details',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ChargerDetailsScreen(chargerId: state.extra as String),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/book-confirm',
        name: 'book-confirm',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BookConfirmScreen(charger: state.extra as ChargerModel),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/booking-success',
        name: 'booking-success',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BookingSuccessScreen(booking: state.extra as BookingModel),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/booking-history',
        name: 'booking-history',
        builder: (context, state) => const BookingHistoryScreen(),
      ),
      GoRoute(
        path: '/booking-details',
        name: 'booking-details',
        builder: (context, state) => BookingDetailsScreen(booking: state.extra as BookingModel),
      ),
      GoRoute(
        path: '/arrived',
        name: 'arrived',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ArrivedMapScreen(booking: state.extra as BookingModel),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/active-session',
        name: 'active-session',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ActiveSessionScreen(session: state.extra as SessionModel),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/carplay',
        name: 'carplay',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CarDashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/payment-methods',
        name: 'payment-methods',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PaymentMethodsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/vehicles',
        name: 'vehicles',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const VehiclesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FavoritesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationPreferencesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/help-support',
        name: 'help-support',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HelpSupportScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PrivacyScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy-policy',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PrivacyPolicyScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/terms-of-service',
        name: 'terms-of-service',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TermsOfServiceScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/terms',
        name: 'terms',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TermsOfServiceScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/live-chat',
        name: 'live-chat',
        pageBuilder: (context, state) {
          final topic = state.uri.queryParameters['topic'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: LiveChatScreen(initialTopic: topic),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              final tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: Curves.easeInOutCubic));
              return SlideTransition(
                  position: animation.drive(tween), child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/host-telemetry',
        name: 'host-telemetry',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HostTelemetryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      // Host Shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => HostShell(child: child),
        routes: [
          GoRoute(
            path: '/host/dashboard',
            name: 'host-dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HostDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/host/chargers',
            name: 'host-chargers',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HostChargersScreen(),
            ),
          ),
          GoRoute(
            path: '/host/earnings',
            name: 'host-earnings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HostEarningsScreen(),
            ),
          ),
          GoRoute(
            path: '/host/settings',
            name: 'host-settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HostSettingsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/host/chat',
        name: 'host-chat',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HostChatScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/host/rate-session',
        name: 'host-rate-session',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RateSessionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/host/fleet-manager',
        name: 'host-fleet-manager',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FleetManagerScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/host/charger-form',
        name: 'host-charger-form',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ChargerFormScreen(chargerId: state.extra as String?),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/admin-dashboard',
        name: 'admin-dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SocietyAdminDashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      ),
    ],
  );
}
