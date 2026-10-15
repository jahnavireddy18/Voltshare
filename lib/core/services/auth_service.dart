import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/models/user_model.dart';

/// Firebase Auth wrapper providing real authentication.
///
/// Roles are stored in Firestore, NOT in client-side claims, to prevent
/// tampering. Every role check reads from the `users` collection.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static const _usersCollection = 'users';

  /// Current Firebase Auth user (null if not signed in).
  User? get currentFirebaseUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Whether the user is currently signed in.
  bool get isSignedIn => _auth.currentUser != null;

  /// Register a new user with email and password.
  ///
  /// Creates both a Firebase Auth account and a Firestore user document.
  Future<UserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String phone = '',
    UserRole role = UserRole.user,
  }) async {
    // Create Firebase Auth account.
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    await credential.user!.updateDisplayName(name);

    // Create Firestore user document.
    final now = DateTime.now();
    final userModel = UserModel(
      id: uid,
      name: name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      role: role,
      status: AccountStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(_usersCollection)
        .doc(uid)
        .set(userModel.toJson());

    // Send verification email (non-blocking).
    try {
      await credential.user!.sendEmailVerification();
    } catch (e) {
      debugPrint('Email verification send failed: $e');
    }

    return userModel;
  }

  /// Sign in with email and password.
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    final userModel = await getUserProfile(uid);

    if (userModel == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'User profile not found in database.',
      );
    }

    if (userModel.status == AccountStatus.suspended) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'user-suspended',
        message: 'Your account has been suspended. Contact support.',
      );
    }

    return userModel;
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Get the current user's profile from Firestore.
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUserProfile(user.uid);
  }

  /// Get a user profile by UID.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc =
        await _firestore.collection(_usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Get the current user's role from Firestore (server-authoritative).
  Future<UserRole> getCurrentUserRole() async {
    final profile = await getCurrentUserProfile();
    return profile?.role ?? UserRole.user;
  }

  /// Update the user's role in Firestore.
  /// This should only be called during initial onboarding or by admin.
  Future<void> updateUserRole(String uid, UserRole role) async {
    await _firestore.collection(_usersCollection).doc(uid).update({
      'role': role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update user profile fields.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(_usersCollection).doc(uid).update(data);
  }
}

/// Custom exception for auth errors with user-friendly messages.
class FirebaseAuthException implements Exception {
  final String code;
  final String message;

  FirebaseAuthException({required this.code, required this.message});

  @override
  String toString() => message;

  /// Convert Firebase error codes to user-friendly messages.
  static String friendlyMessage(dynamic error) {
    if (error is FirebaseAuthException) return error.message;

    final code = error is FirebaseException ? error.code : '';
    return switch (code) {
      'email-already-in-use' => 'An account with this email already exists.',
      'invalid-email' => 'Please enter a valid email address.',
      'weak-password' => 'Password must be at least 6 characters.',
      'user-not-found' => 'No account found with this email.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'invalid-credential' => 'Invalid email or password.',
      'too-many-requests' =>
        'Too many attempts. Please try again later.',
      'user-disabled' => 'This account has been disabled.',
      'network-request-failed' =>
        'Network error. Please check your connection.',
      _ => 'An unexpected error occurred. Please try again.',
    };
  }
}
