/// Authentication mode configuration for VoltShare.
///
/// To force production Firebase Phone/Email authentication:
/// build with `--dart-define=AUTH_MODE=production`.
///
/// By default, `AUTH_MODE=demo` is active for hackathon demonstrations,
/// offline reliability, and fast verification where ANY 4-digit numeric OTP
/// (from 0000 to 9999) is accepted for any valid 10-digit Indian mobile number.
///
/// CRITICAL SECURITY NOTICE:
/// Arbitrary OTP acceptance is strictly a DEMO-ONLY hackathon mechanism.
/// It must NEVER be enabled in production environments or builds with real customer data.
class AuthModeConfig {
  static const String authMode = String.fromEnvironment(
    'AUTH_MODE',
    defaultValue: 'demo',
  );

  /// Whether demo authentication mode is active.
  static bool get isDemoMode => authMode.trim().toLowerCase() == 'demo';

  /// Default 4-digit demo OTP (useful for autofill and hints).
  static const String defaultDemoOtp = '1234';

  /// Legacy demo OTP reference maintained for backwards compatibility.
  static const String demoOtp = '1234';

  /// Validates whether an entered OTP is valid for Demo Mode.
  /// Accepts ANY 4-digit numeric string (0000 to 9999), preserving leading zeros like '0047'.
  static bool isValidDemoOtp(String otp) {
    if (!isDemoMode) return false;
    final trimmed = otp.trim();
    return trimmed.length == 4 && RegExp(r'^[0-9]{4}$').hasMatch(trimmed);
  }
}
