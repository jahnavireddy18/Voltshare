import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/services/auth_service.dart';
import 'package:vnest_app/core/theme/app_theme.dart';
import 'package:vnest_app/widgets/common/vs_text_field.dart';
import 'package:vnest_app/widgets/common/vs_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthProvider().signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // Navigate based on role.
      switch (user.role) {
        case UserRole.admin:
          context.go('/admin-dashboard');
          break;
        case UserRole.host:
          context.go('/host/dashboard');
          break;
        case UserRole.user:
        default:
          context.go('/home');
          break;
      }
    } catch (e) {
      setState(() {
        _errorMessage = FirebaseAuthException.friendlyMessage(e);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                    const SizedBox(height: 48),
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
                    const SizedBox(height: 40),
                    Text(
                      'Log in to your account',
                      style: GoogleFonts.manrope(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 24),

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
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email input
                    VsTextField(
                      controller: _emailController,
                      hint: 'Email address',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                    const SizedBox(height: 12),

                    // Password input
                    VsTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffix: IconButton(
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                      ),
                    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
                    const SizedBox(height: 12),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => context.push('/forgot-password'),
                        child: Text(
                          'Forgot password?',
                          style: GoogleFonts.manrope(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 800.ms),
                    const SizedBox(height: 24),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: VsButton(
                        label: 'Log In',
                        onPressed: _handleLogin,
                        isLoading: _isLoading,
                        width: double.infinity,
                      ),
                    ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.1),
                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: cs.outlineVariant, height: 1)),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: GoogleFonts.manrope(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        Expanded(
                            child: Divider(
                                color: cs.outlineVariant, height: 1)),
                      ],
                    ).animate().fadeIn(delay: 1000.ms),
                    const SizedBox(height: 24),

                    // Sign up link
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => context.push('/signup'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: cs.outlineVariant),
                        ),
                        child: Text(
                          'Create Account',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 1100.ms),
                    const SizedBox(height: 24),

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
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const TextSpan(text: ' • '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: GoogleFonts.manrope(
                              decoration: TextDecoration.underline,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 1200.ms),
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
