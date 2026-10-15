/// Authentication mode configuration for VoltShare.
///
/// To force production Firebase Phone/Email authentication:
/// build with `--dart-define=AUTH_MODE=production`.
///
/// By default, `AUTH_MODE=demo` is active for hackathon demonstrations,
/// offline reliability, and fast verification with the fixed code `123456`.
class AuthModeConfig {
  static const String authMode = String.fromEnvironment(
    'AUTH_MODE',
    defaultValue: 'demo',
  );

  /// Whether demo authentication mode is active.
  static bool get isDemoMode => authMode.trim().toLowerCase() == 'demo';

  /// Fixed demo OTP for testing.
  static const String demoOtp = '123456';
}
