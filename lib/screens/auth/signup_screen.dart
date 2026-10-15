import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/config/auth_mode_config.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/services/auth_service.dart';
import 'package:vnest_app/core/services/demo_auth_service.dart';
import 'package:vnest_app/core/theme/app_theme.dart';
import 'package:vnest_app/widgets/common/vs_text_field.dart';
import 'package:vnest_app/widgets/common/vs_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  UserRole _selectedRole = UserRole.user;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final phone = DemoAuthService.normalizePhone(_phoneController.text);

    if (AuthModeConfig.isDemoMode) {
      if (name.isEmpty) {
        setState(() => _errorMessage = 'Please enter your full name.');
        return;
      }
      if (phone.isEmpty) {
        setState(() => _errorMessage = 'Please enter your phone number.');
        return;
      }
      if (!DemoAuthService.isValidIndianPhone(phone) &&
          !DemoAuthService.isValidPhone(phone)) {
        setState(() => _errorMessage =
            'Please enter a valid 10-digit Indian mobile number.');
        return;
      }

      final normalized = DemoAuthService.isValidIndianPhone(phone)
          ? DemoAuthService.normalizeIndianPhone(phone)
          : phone;

      setState(() => _errorMessage = null);
      context.push('/otp-verification', extra: {
        'phoneNumber': normalized,
        'name': name,
        'role': _selectedRole,
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthProvider().signUp(
        name: name,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: phone,
        role: _selectedRole,
      );

      if (!mounted) return;

      // Navigate based on role.
      if (_selectedRole == UserRole.host) {
        context.go('/host/dashboard');
      } else {
        context.go('/home');
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Account',
                        style: GoogleFonts.sora(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ).animate().fadeIn().slideX(begin: -0.1),
                      const SizedBox(height: 8),
                      Text(
                        'Join VoltShare and start your EV charging journey.',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          color: cs.onSurfaceVariant,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
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
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Name
                      VsTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 16),

                      // Email
                      VsTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Enter your email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          final emailRegex = RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 16),

                      // Phone
                      VsTextField(
                        controller: _phoneController,
                        label: 'Phone (optional)',
                        hint: 'Enter your phone number',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 16),

                      // Password
                      VsTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Create a password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffix: IconButton(
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: 16),

                      // Confirm password
                      VsTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscureConfirm,
                        suffix: IconButton(
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 24),

                      // Role selection
                      Text(
                        'I want to...',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ).animate().fadeIn(delay: 700.ms),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleChip(
                              role: UserRole.user,
                              icon: Icons.bolt,
                              label: 'Find Chargers',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRoleChip(
                              role: UserRole.host,
                              icon: Icons.ev_station,
                              label: 'Share Charger',
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 800.ms),
                      const SizedBox(height: 32),

                      // Signup button
                      VsButton.fullWidth(
                        label: 'Create Account',
                        onPressed: _handleSignup,
                        isLoading: _isLoading,
                        icon: Icons.arrow_forward,
                      ).animate().fadeIn(delay: 900.ms),
                      const SizedBox(height: 16),

                      // Login link
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text.rich(
                            TextSpan(
                              text: 'Already have an account? ',
                              style: GoogleFonts.manrope(
                                color: cs.onSurfaceVariant,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Log in',
                                  style: GoogleFonts.manrope(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 1000.ms),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip({
    required UserRole role,
    required IconData icon,
    required String label,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : cs.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
