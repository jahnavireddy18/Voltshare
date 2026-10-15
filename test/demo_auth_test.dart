import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnest_app/core/config/auth_mode_config.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/services/demo_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DemoAuthService Phone Validation Tests', () {
    test('Accepts valid 10-digit Indian numbers and normalizes them', () {
      expect(DemoAuthService.isValidIndianPhone('9876543210'), isTrue);
      expect(DemoAuthService.isValidIndianPhone('+919876543210'), isTrue);
      expect(DemoAuthService.isValidIndianPhone('+91 98765-43210'), isTrue);
      expect(DemoAuthService.isValidIndianPhone('09876543210'), isTrue);

      expect(DemoAuthService.normalizeIndianPhone('+91 98765-43210'), equals('9876543210'));
      expect(DemoAuthService.normalizeIndianPhone('09876543210'), equals('9876543210'));
    });

    test('Rejects incomplete or invalid phone numbers', () {
      expect(DemoAuthService.isValidIndianPhone(''), isFalse);
      expect(DemoAuthService.isValidIndianPhone('abc'), isFalse);
      expect(DemoAuthService.isValidIndianPhone('987654321'), isFalse); // 9 digits
      expect(DemoAuthService.isValidIndianPhone('12345'), isFalse); // under 10 digits
      expect(DemoAuthService.isValidIndianPhone('9876543210987'), isFalse); // > 12 digits
    });

    test('New phone number creates a demo profile', () async {
      final service = DemoAuthService();
      final user = await service.authenticateWithPhone(
        phone: '9876543210',
        name: 'Test Driver',
        role: UserRole.user,
      );

      expect(user.id, equals('demo_9876543210'));
      expect(user.name, equals('Test Driver'));
      expect(user.phone, equals('9876543210'));
      expect(user.role, equals(UserRole.user));

      final saved = await service.getSavedSession();
      expect(saved?.id, equals(user.id));
    });

    test('Returning phone number reuses existing profile without duplicate', () async {
      final service = DemoAuthService();
      final user1 = await service.authenticateWithPhone(
        phone: '9876543210',
        name: 'Original Name',
      );

      final user2 = await service.authenticateWithPhone(
        phone: '9876543210',
      );

      expect(user1.id, equals(user2.id));
      expect(user2.name, equals('Original Name'));
    });

    test('Sign out clears active session in DemoAuthService', () async {
      final service = DemoAuthService();
      await service.authenticateWithPhone(phone: '9876543210');
      expect(await service.getSavedSession(), isNotNull);

      await service.signOut();
      expect(await service.getSavedSession(), isNull);
    });
  });

  group('Flexible 4-Digit Demo OTP & Role Tests', () {
    test('AuthModeConfig validates 4-digit numeric OTPs and preserves leading zeros', () {
      expect(AuthModeConfig.isValidDemoOtp('1234'), isTrue);
      expect(AuthModeConfig.isValidDemoOtp('5678'), isTrue);
      expect(AuthModeConfig.isValidDemoOtp('0000'), isTrue);
      expect(AuthModeConfig.isValidDemoOtp('9999'), isTrue);
      expect(AuthModeConfig.isValidDemoOtp('0047'), isTrue); // Leading zeros preserved

      // Invalid OTPs
      expect(AuthModeConfig.isValidDemoOtp(''), isFalse);
      expect(AuthModeConfig.isValidDemoOtp('123'), isFalse); // 3 digits
      expect(AuthModeConfig.isValidDemoOtp('12345'), isFalse); // 5 digits
      expect(AuthModeConfig.isValidDemoOtp('abcd'), isFalse); // Non-numeric
    });

    test('Scenario 1: Any valid 10-digit phone number with OTP 1234 succeeds', () async {
      final provider = AuthProvider();
      final user = await provider.verifyDemoOtp(
        phoneNumber: '9876543210',
        otp: '1234',
      );

      expect(user.phone, equals('9876543210'));
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser?.id, equals('demo_9876543210'));

      await provider.signOut();
    });

    test('Scenario 2: Another phone number with OTP 5678 succeeds', () async {
      final provider = AuthProvider();
      final user = await provider.verifyDemoOtp(
        phoneNumber: '8765432109',
        otp: '5678',
      );

      expect(user.phone, equals('8765432109'));
      expect(provider.isAuthenticated, isTrue);

      await provider.signOut();
    });

    test('Scenario 3: OTP with leading zeros such as 0047 succeeds', () async {
      final provider = AuthProvider();
      final user = await provider.verifyDemoOtp(
        phoneNumber: '9123456780',
        otp: '0047',
      );

      expect(user.phone, equals('9123456780'));
      expect(provider.isAuthenticated, isTrue);

      await provider.signOut();
    });

    test('Scenario 4: Incomplete or invalid phone number throws FormatException', () async {
      final provider = AuthProvider();

      expect(
        provider.verifyDemoOtp(phoneNumber: '12345', otp: '1234'),
        throwsA(isA<FormatException>()),
      );

      expect(
        provider.verifyDemoOtp(phoneNumber: '987654321', otp: '1234'),
        throwsA(isA<FormatException>()),
      );
    });

    test('Scenario 5: OTP with fewer or more than 4 digits throws FormatException', () async {
      final provider = AuthProvider();

      // Under 4 digits
      expect(
        provider.verifyDemoOtp(phoneNumber: '9876543210', otp: '123'),
        throwsA(isA<FormatException>()),
      );

      // Over 4 digits
      expect(
        provider.verifyDemoOtp(phoneNumber: '9876543210', otp: '12345'),
        throwsA(isA<FormatException>()),
      );

      // Non-numeric
      expect(
        provider.verifyDemoOtp(phoneNumber: '9876543210', otp: 'abcd'),
        throwsA(isA<FormatException>()),
      );
    });

    test('Scenario 6: Driver login then logout properly clears state', () async {
      final provider = AuthProvider();
      await provider.verifyDemoOtp(phoneNumber: '9876543211', otp: '1234');
      await provider.setRole(UserRole.user);

      expect(provider.isAuthenticated, isTrue);
      expect(provider.isUser, isTrue);

      await provider.signOut();

      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
      expect(provider.isLoggingOut, isFalse);

      final saved = await DemoAuthService().getSavedSession();
      expect(saved, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('demo_auth_active_user_id'), isNull);
    });

    test('Scenario 7: Charger Host login then logout properly clears state', () async {
      final provider = AuthProvider();
      await provider.verifyDemoOtp(phoneNumber: '9876543212', otp: '5678');
      await provider.setRole(UserRole.host);

      expect(provider.isAuthenticated, isTrue);
      expect(provider.isHost, isTrue);

      await provider.signOut();

      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);

      final saved = await DemoAuthService().getSavedSession();
      expect(saved, isNull);
    });

    test('Scenario 8: Society Admin login then logout properly clears state', () async {
      final provider = AuthProvider();
      await provider.verifyDemoOtp(phoneNumber: '9876543213', otp: '0047');
      await provider.setRole(UserRole.admin);

      expect(provider.isAuthenticated, isTrue);
      expect(provider.isAdmin, isTrue);

      await provider.signOut();

      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);

      final saved = await DemoAuthService().getSavedSession();
      expect(saved, isNull);
    });

    test('Scenario 9: Can re-authenticate with valid credentials after logout', () async {
      final provider = AuthProvider();
      await provider.verifyDemoOtp(phoneNumber: '9876543214', otp: '9999');
      expect(provider.isAuthenticated, isTrue);

      await provider.signOut();
      expect(provider.isAuthenticated, isFalse);

      // Log in again with different number and OTP
      final user = await provider.verifyDemoOtp(phoneNumber: '9876543215', otp: '0000');
      expect(provider.isAuthenticated, isTrue);
      expect(user.phone, equals('9876543215'));
    });
  });
}
