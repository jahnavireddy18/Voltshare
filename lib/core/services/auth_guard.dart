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
    final isAuthRoute = state.uri.path == '/login' || 
                        state.uri.path == '/signup' || 
                        state.uri.path == '/forgot-password' ||
                        state.uri.path == '/onboarding';

    // If user is not logged in and trying to access a protected route
    if (!isLoggedIn && !isAuthRoute) {
      // Keep track of the original location they tried to access
      return '/login?from=${state.uri.path}';
    }

    // If user is logged in and trying to access auth routes, redirect to their dashboard
    if (isLoggedIn && isAuthRoute) {
      if (userRole == UserRole.admin) return '/admin-dashboard';
      if (userRole == UserRole.host) return '/host/dashboard';
      return '/home';
    }

    // Role-based access control
    if (isLoggedIn) {
      // Prevent non-admins from accessing admin routes
      if (state.uri.path.startsWith('/admin') && userRole != UserRole.admin) {
        return userRole == UserRole.host ? '/host/dashboard' : '/home';
      }

      // Prevent non-hosts from accessing host routes
      if (state.uri.path.startsWith('/host') && userRole != UserRole.host && userRole != UserRole.admin) {
        return '/home';
      }
      
      // Prevent hosts/admins from accessing pure driver routes? 
      // Often hosts can also be drivers, so maybe we allow it, but for strictness:
      // We can leave driver routes open to hosts/admins if they want to book.
    }

    return null; // No redirect needed
  }
}
