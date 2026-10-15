import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/models/user_model.dart';

/// Local offline-first authentication service for hackathon demonstrations.
///
/// Features:
/// - Reuses existing demo user profiles by phone number (no duplicates).
/// - Persists demo active sessions across app restarts using SharedPreferences.
/// - Validates phone number formats without sending external SMS.
/// - Fully isolated from Firebase Phone Authentication.
class DemoAuthService {
  static final DemoAuthService _instance = DemoAuthService._internal();
  factory DemoAuthService() => _instance;
  DemoAuthService._internal();

  static const String _keyActiveUserId = 'demo_auth_active_user_id';
  static const String _keyUsersPrefix = 'demo_auth_user_';

  /// Strip formatting characters like spaces, hyphens, and parentheses.
  static String normalizePhone(String raw) {
    return raw.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
  }

  /// Basic phone validation: 7-15 digits with optional '+' prefix.
  static bool isValidPhone(String phone) {
    final cleaned = normalizePhone(phone);
    if (cleaned.isEmpty) return false;
    final regex = RegExp(r'^\+?[0-9]{7,15}$');
    return regex.hasMatch(cleaned);
  }

  /// Get the active persisted session, if one exists.
  Future<UserModel?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(_keyActiveUserId);
    if (activeId == null || activeId.isEmpty) return null;
    return getUserById(activeId);
  }

  /// Get a demo user profile by user ID.
  Future<UserModel?> getUserById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('$_keyUsersPrefix$id');
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Get a demo user profile by phone number.
  Future<UserModel?> getUserByPhone(String phone) async {
    final cleaned = normalizePhone(phone);
    final id = 'demo_$cleaned';
    return getUserById(id);
  }

  /// Authenticate with a phone number:
  /// - If the phone number already exists, retrieves and returns that profile.
  /// - If it is a new phone number, creates and saves a new demo profile.
  /// - Marks the profile as the active session.
  Future<UserModel> authenticateWithPhone({
    required String phone,
    String? name,
    UserRole? role,
  }) async {
    final cleaned = normalizePhone(phone);
    final existing = await getUserByPhone(cleaned);
    final prefs = await SharedPreferences.getInstance();

    if (existing != null) {
      UserModel updated = existing;
      final shouldUpdateName = name != null && name.trim().isNotEmpty && name.trim() != existing.name;
      final shouldUpdateRole = role != null && role != existing.role;

      if (shouldUpdateName || shouldUpdateRole) {
        updated = existing.copyWith(
          name: shouldUpdateName ? name.trim() : existing.name,
          role: role ?? existing.role,
        );
        await prefs.setString(
          '$_keyUsersPrefix${updated.id}',
          jsonEncode(updated.toLocalJson()),
        );
      }
      await prefs.setString(_keyActiveUserId, updated.id);
      return updated;
    }

    // New profile creation
    final now = DateTime.now();
    final phoneSuffix = cleaned.length >= 4 ? cleaned.substring(cleaned.length - 4) : cleaned;
    final displayName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : 'Demo User $phoneSuffix';

    final newUser = UserModel(
      id: 'demo_$cleaned',
      name: displayName,
      phone: cleaned,
      email: '$cleaned@voltshare.demo',
      role: role ?? UserRole.user,
      status: AccountStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    await prefs.setString(
      '$_keyUsersPrefix${newUser.id}',
      jsonEncode(newUser.toLocalJson()),
    );
    await prefs.setString(_keyActiveUserId, newUser.id);
    return newUser;
  }

  /// Sign out by clearing the active demo session ID.
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveUserId);
  }

  /// Update an existing demo user's data (e.g. role update).
  Future<void> updateUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyUsersPrefix${user.id}',
      jsonEncode(user.toLocalJson()),
    );
  }
}
