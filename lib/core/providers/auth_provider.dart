import 'package:flutter/foundation.dart';
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

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
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

  /// Verify Demo OTP (123456) and authenticate the user.
  Future<UserModel> verifyDemoOtp({
    required String phoneNumber,
    required String otp,
    String? name,
    UserRole? role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (otp.trim() != AuthModeConfig.demoOtp) {
        throw const FormatException('Invalid OTP. In demo mode, enter 123456.');
      }

      final user = await _demoService.authenticateWithPhone(
        phone: phoneNumber,
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

  /// Sign out.
  Future<void> signOut() async {
    if (AuthModeConfig.isDemoMode) {
      await _demoService.signOut();
      _currentUser = null;
      notifyListeners();
      return;
    }

    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
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
