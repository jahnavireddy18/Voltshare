import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/models/user_model.dart';
import 'package:vnest_app/core/services/auth_service.dart';

/// Centralized auth state provider using ChangeNotifier.
///
/// Listens to Firebase Auth state changes and maintains the current
/// user profile including their role fetched from Firestore.
class AuthProvider extends ChangeNotifier {
  static final AuthProvider _instance = AuthProvider._internal();
  factory AuthProvider() => _instance;

  AuthProvider._internal() {
    _init();
  }

  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  UserRole get userRole => _currentUser?.role ?? UserRole.user;
  String get userId => _currentUser?.id ?? '';

  bool get isUser => userRole == UserRole.user;
  bool get isHost => userRole == UserRole.host;
  bool get isAdmin => userRole == UserRole.admin;

  void _init() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
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
        // Firebase Auth user exists but no Firestore profile — edge case.
        // This can happen if profile creation failed during signup.
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
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Reset password.
  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  /// Update the user's role (for onboarding flow).
  Future<void> setRole(UserRole role) async {
    if (_currentUser == null) return;
    await _authService.updateUserRole(_currentUser!.id, role);
    _currentUser = _currentUser!.copyWith(role: role);
    notifyListeners();
  }

  /// Refresh the current user profile from Firestore.
  Future<void> refreshProfile() async {
    if (_currentUser == null) return;
    _currentUser = await _authService.getUserProfile(_currentUser!.id);
    notifyListeners();
  }
}
