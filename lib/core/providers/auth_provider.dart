import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vnest_app/core/config/auth_mode_config.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/models/user_model.dart';
import 'package:vnest_app/core/services/auth_service.dart';
import 'package:vnest_app/core/services/demo_auth_service.dart';

/// Centralized auth state provider using ChangeNotifier.
///
/// In Demo Mode (`AUTH_MODE=demo`):
/// - Manages local mock profiles via [DemoAuthService].
/// - Validates fixed demo OTP (123456) without sending SMS.
/// - Persists sessions across app restarts without Firebase dependencies.
///
/// In Production Mode (`AUTH_MODE=production`):
/// - Listens to Firebase Auth state changes and maintains the current
///   user profile from Firestore.
class AuthProvider extends ChangeNotifier {
  static final AuthProvider _instance = AuthProvider._internal();
  factory AuthProvider() => _instance;

  AuthProvider._internal() {
    _init();
  }

  final AuthService _authService = AuthService();
  final DemoAuthService _demoService = DemoAuthService();

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isInitialized = false;
  bool _isLoggingOut = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggingOut => _isLoggingOut;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  UserRole get userRole => _currentUser?.role ?? UserRole.user;
  String get userId => _currentUser?.id ?? '';
  bool get isDemoMode => AuthModeConfig.isDemoMode;

  bool get isUser => userRole == UserRole.user;
  bool get isHost => userRole == UserRole.host;
  bool get isAdmin => userRole == UserRole.admin;

  Future<void> _init() async {
    if (AuthModeConfig.isDemoMode) {
      try {
        final saved = await _demoService.getSavedSession();
        _currentUser = saved;
      } catch (e) {
        debugPrint('Demo auth session restore error: $e');
        _currentUser = null;
      } finally {
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
      }
      return;
    }

    try {
      _authService.authStateChanges.listen(_onAuthStateChanged);
    } catch (e) {
      debugPrint('Firebase Auth listener error: $e');
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      _currentUser = await _authService.getUserProfile(firebaseUser.uid);
      if (_currentUser == null) {
        debugPrint('Auth user exists but no Firestore profile for ${firebaseUser.uid}');
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _currentUser = null;
    }

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  /// Verify Demo OTP: accepts ANY 4-digit numeric OTP (0000-9999) in demo mode
  /// and authenticates the user with their normalized 10-digit Indian phone number.
  ///
  /// CRITICAL SECURITY NOTICE:
  /// Arbitrary OTP acceptance is restricted strictly to Demo Mode (`AUTH_MODE=demo`).
  /// In Production Mode (`AUTH_MODE=production`), this method throws an error
  /// and the real Firebase Authentication flow must be used.
  Future<UserModel> verifyDemoOtp({
    required String phoneNumber,
    required String otp,
    String? name,
    UserRole? role,
  }) async {
    if (!AuthModeConfig.isDemoMode) {
      throw const UnsupportedError(
        'Flexible Demo OTP verification is disabled in production mode. '
        'Real phone authentication with SMS delivery is required.',
      );
    }

    final trimmedOtp = otp.trim();
    if (!AuthModeConfig.isValidDemoOtp(trimmedOtp)) {
      if (trimmedOtp.length != 4) {
        throw const FormatException('Please enter a 4-digit OTP.');
      }
      throw const FormatException(
          'Invalid OTP. Please enter a 4-digit numeric code (0000-9999).');
    }

    if (!DemoAuthService.isValidIndianPhone(phoneNumber)) {
      throw const FormatException(
          'Please enter a valid 10-digit Indian mobile number.');
    }

    final normalizedPhone = DemoAuthService.normalizeIndianPhone(phoneNumber);

    _isLoading = true;
    notifyListeners();

    try {
      final user = await _demoService.authenticateWithPhone(
        phone: normalizedPhone,
        name: name,
        role: role,
      );
      _currentUser = user;
      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign up with email and password.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    String phone = '',
    UserRole role = UserRole.user,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (AuthModeConfig.isDemoMode) {
        final resolvedPhone = phone.isNotEmpty
            ? phone
            : (email.replaceAll(RegExp(r'[^0-9]'), '').isEmpty ? '9876543210' : email);
        final user = await _demoService.authenticateWithPhone(
          phone: resolvedPhone,
          name: name,
          role: role,
        );
        _currentUser = user;
        return user;
      }

      final user = await _authService.signUpWithEmail(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      _currentUser = user;
      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (AuthModeConfig.isDemoMode) {
        final digits = email.replaceAll(RegExp(r'[^0-9]'), '');
        final phone = digits.isNotEmpty ? digits : '9876543210';
        final user = await _demoService.authenticateWithPhone(
          phone: phone,
          name: email.contains('@') ? email.split('@').first : 'Demo User',
        );
        _currentUser = user;
        return user;
      }

      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      _currentUser = user;
      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out reliably across both Demo and Production/Firebase modes.
  /// Clears local session, SharedPreferences, cached profile, and notifies listeners.
  /// Robust against network and offline errors.
  Future<void> signOut() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    _isLoading = true;
    notifyListeners();

    try {
      if (AuthModeConfig.isDemoMode) {
        await _demoService.signOut();
      } else {
        try {
          await _authService.signOut();
        } catch (e) {
          debugPrint('AuthService.signOut() error: $e');
        }
      }
    } finally {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('demo_auth_active_user_id');
      } catch (e) {
        debugPrint('SharedPreferences cleanup error: $e');
      }
      _currentUser = null;
      _isLoading = false;
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  /// Show a consistent, role-agnostic logout confirmation dialog,
  /// execute sign-out, clear navigation history, and redirect cleanly to /login.
  static Future<void> showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final cs = Theme.of(dialogCtx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded, color: cs.error, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Log Out',
                style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to log out of VoltShare? You will need to sign in again to access your account.',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            FilledButton(
              key: const Key('confirm_logout_button'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(
                'Log Out',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        await AuthProvider().signOut();
        if (context.mounted) {
          context.go('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Logged out successfully',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to sign out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Reset password.
  Future<void> resetPassword(String email) async {
    if (AuthModeConfig.isDemoMode) {
      return; // No-op in demo mode
    }
    await _authService.resetPassword(email);
  }

  /// Update the user's role (for onboarding / role selection flow).
  Future<void> setRole(UserRole role) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(role: role);

    if (AuthModeConfig.isDemoMode) {
      await _demoService.updateUser(_currentUser!);
    } else {
      await _authService.updateUserRole(_currentUser!.id, role);
    }
    notifyListeners();
  }

  /// Refresh the current user profile.
  Future<void> refreshProfile() async {
    if (_currentUser == null) return;
    if (AuthModeConfig.isDemoMode) {
      _currentUser = await _demoService.getUserById(_currentUser!.id);
    } else {
      _currentUser = await _authService.getUserProfile(_currentUser!.id);
    }
    notifyListeners();
  }
}
