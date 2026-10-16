import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/services/demo_auth_service.dart';
import 'package:vnest_app/core/theme/app_theme.dart';
import 'package:vnest_app/widgets/common/vs_text_field.dart';
import 'package:vnest_app/widgets/common/vs_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handlePhoneContinue() {
    if (_isLoading) return;
    final rawPhone = _phoneController.text;
    final cleaned = DemoAuthService.normalizeIndianPhone(rawPhone);

    if (cleaned.isEmpty) {
      setState(() => _errorMessage = 'Please enter your 10-digit mobile number.');
      return;
    }

    if (!DemoAuthService.isValidIndianPhone(rawPhone)) {
      setState(() => _errorMessage =
          'Please enter a valid 10-digit Indian mobile number.');
      return;
    }

    setState(() => _errorMessage = null);
    context.push('/otp-verification', extra: {
      'phoneNumber': cleaned,
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 36),
                    // Title
                    Text(
                      "INDIA'S #1",
                      style: GoogleFonts.sora(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
                    Text(
                      'EV CHARGING APP',
                      style: GoogleFonts.sora(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 200.ms)
                        .slideY(begin: -0.2),
                    const SizedBox(height: 16),
                    // Brand badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat())
                              .fadeIn()
                              .then()
                              .fadeOut()
                              .then()
                              .fadeIn(),
                          const SizedBox(width: 8),
                          Text(
                            'VoltShare',
                            style: GoogleFonts.sora(
                              fontSize: 20,
                              color: AppColors.primary,
                              fontStyle: FontStyle.italic,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .scale(begin: const Offset(0.8, 0.8)),
                    const SizedBox(height: 32),

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: cs.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: cs.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.manrope(
                                  color: cs.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Phone Auth Form
                    VsTextField(
                      controller: _phoneController,
                      hint: '10-digit mobile number (e.g. 98765 43210)',
                      prefixIcon: Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                    ).animate().fadeIn().slideY(begin: 0.1),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: VsButton(
                        label: 'Continue with OTP',
                        onPressed: _handlePhoneContinue,
                        isLoading: _isLoading,
                        width: double.infinity,
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),
                    const SizedBox(height: 32),

                    // Terms
                    Text.rich(
                      TextSpan(
                        text: 'By continuing, you agree to our\n',
                        style: GoogleFonts.manrope(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: GoogleFonts.manrope(
                              decoration: TextDecoration.underline,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => context.push('/terms-of-service'),
                          ),
                          const TextSpan(text: ' • '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: GoogleFonts.manrope(
                              decoration: TextDecoration.underline,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => context.push('/privacy-policy'),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 1000.ms),
                  ],
                ),
              ),
            ),
            // Bottom indicator bar
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 16),
              child: Container(
                width: 128,
                height: 6,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
