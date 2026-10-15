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

  group('DemoAuthService Tests', () {
    test('Phone validation accepts valid formats and rejects invalid ones', () {
      expect(DemoAuthService.isValidPhone('9876543210'), isTrue);
      expect(DemoAuthService.isValidPhone('+919876543210'), isTrue);
      expect(DemoAuthService.isValidPhone('+91 98765-43210'), isTrue);
      expect(DemoAuthService.isValidPhone('1234567'), isTrue);

      expect(DemoAuthService.isValidPhone(''), isFalse);
      expect(DemoAuthService.isValidPhone('abc'), isFalse);
      expect(DemoAuthService.isValidPhone('12345'), isFalse); // under 7 digits
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

      // Saved session matches
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

    test('Sign out clears active session', () async {
      final service = DemoAuthService();
      await service.authenticateWithPhone(phone: '9876543210');
      expect(await service.getSavedSession(), isNotNull);

      await service.signOut();
      expect(await service.getSavedSession(), isNull);
    });
  });

  group('AuthProvider Demo Mode Tests', () {
    test('Accepts 123456 and rejects incorrect OTP', () async {
      final provider = AuthProvider();

      // Incorrect OTP throws
      expect(
        () => provider.verifyDemoOtp(
          phoneNumber: '9876543210',
          otp: '000000',
        ),
        throwsA(isA<FormatException>()),
      );

      // Correct OTP succeeds
      final user = await provider.verifyDemoOtp(
        phoneNumber: '9876543210',
        otp: AuthModeConfig.demoOtp,
      );
      expect(user.phone, equals('9876543210'));
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser?.id, equals('demo_9876543210'));

      // Sign out
      await provider.signOut();
      expect(provider.isAuthenticated, isFalse);
    });
  });
}
