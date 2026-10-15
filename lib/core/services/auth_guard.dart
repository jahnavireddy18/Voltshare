import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';

/// Middleware for route protection and role-based access control.
class AuthGuard {
  static String? redirect(BuildContext context, GoRouterState state) {
    final authProvider = AuthProvider();

    // Allow navigation if auth state is still initializing
    if (!authProvider.isInitialized) return null;

    final isLoggedIn = authProvider.isAuthenticated;
    final userRole = authProvider.userRole;
    final currentPath = state.uri.path;

    final isPublicRoute = currentPath == '/login' ||
        currentPath == '/signup' ||
        currentPath == '/forgot-password' ||
        currentPath == '/onboarding' ||
        currentPath == '/otp-verification' ||
        currentPath == '/otp-success' ||
        currentPath == '/role-selection' ||
        currentPath == '/terms-of-service' ||
        currentPath == '/terms' ||
        currentPath == '/privacy-policy' ||
        currentPath == '/privacy' ||
        currentPath == '/help-support' ||
        currentPath == '/live-chat';

    // If user is not logged in and trying to access a protected route
    if (!isLoggedIn && !isPublicRoute) {
      return '/login';
    }

    // If user is logged in:
    if (isLoggedIn) {
      // Allow completing post-OTP success animation & role selection without kickback
      if (currentPath == '/otp-success' || currentPath == '/role-selection') {
        return null;
      }

      // If user tries to visit login, signup, onboarding, or otp verification when already authenticated
      if (currentPath == '/login' ||
          currentPath == '/signup' ||
          currentPath == '/onboarding' ||
          currentPath == '/otp-verification' ||
          currentPath == '/forgot-password') {
        if (userRole == UserRole.admin) return '/admin-dashboard';
        if (userRole == UserRole.host) return '/host/dashboard';
        return '/home';
      }

      // Role-based access control
      if (currentPath.startsWith('/admin') && userRole != UserRole.admin) {
        return userRole == UserRole.host ? '/host/dashboard' : '/home';
      }

      if (currentPath.startsWith('/host') &&
          userRole != UserRole.host &&
          userRole != UserRole.admin) {
        return '/home';
      }
    }

    return null; // No redirect needed
  }
}
