import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/services/auth_service.dart';
import 'package:vnest_app/core/theme/app_theme.dart';
import 'package:vnest_app/widgets/common/vs_text_field.dart';
import 'package:vnest_app/widgets/common/vs_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address.');
      return;
    }

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthProvider().resetPassword(email);
      if (mounted) setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = FirebaseAuthException.friendlyMessage(e);
        });
      }
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
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.surface,
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon:
                          Icon(Icons.arrow_back, color: cs.onSurface, size: 20),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _emailSent ? _buildSuccessView() : _buildFormView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormView() {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.lock_reset, color: AppColors.primary, size: 32),
        ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 24),
        Text(
          'Reset Password',
          style: GoogleFonts.sora(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),
        Text(
          'Enter your email and we\'ll send you a link to reset your password.',
          style: GoogleFonts.manrope(
            fontSize: 15,
            color: cs.onSurfaceVariant,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 32),

        // Error message
        if (_errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.error.withValues(alpha: 0.3)),
            ),
            child: Text(
              _errorMessage!,
              style: GoogleFonts.manrope(color: cs.error, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
        ],

        VsTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email address',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 24),

        VsButton.fullWidth(
          label: 'Send Reset Link',
          onPressed: _handleResetPassword,
          isLoading: _isLoading,
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 16),

        Center(
          child: GestureDetector(
            onTap: () => context.go('/login'),
            child: Text(
              'Back to Login',
              style: GoogleFonts.manrope(
                color: cs.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _buildSuccessView() {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: 64),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read, color: AppColors.primary, size: 40),
        ).animate().fadeIn().scale(begin: const Offset(0.5, 0.5)),
        const SizedBox(height: 24),
        Text(
          'Check your email',
          style: GoogleFonts.sora(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a password reset link to\n${_emailController.text.trim()}',
          style: GoogleFonts.manrope(
            fontSize: 15,
            color: cs.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 32),
        VsButton.fullWidth(
          label: 'Back to Login',
          onPressed: () => context.go('/login'),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}
