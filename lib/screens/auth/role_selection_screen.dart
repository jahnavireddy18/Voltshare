import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole = 'driver';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surface,
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.arrow_back,
                        color: cs.onSurface, size: 20),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ).animate().fadeIn(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.sora(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          height: 1.2,
                        ),
                        children: [
                          const TextSpan(text: 'How will you\n'),
                          TextSpan(
                            text: 'VoltNest?',
                            style: GoogleFonts.sora(
                              color: cs.primary,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),
                    const SizedBox(height: 12),
                    Text(
                      'Select your primary goal to personalize your experience. You can always change this later.',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        color: cs.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 32),
                    // Role cards
                    _buildRoleCard(
                      role: 'driver',
                      icon: Icons.bolt,
                      title: 'Driver',
                      description:
                          'Find chargers near you, book slots, and power up your journey seamlessly.',
                      chipIcon: Icons.payments,
                      chipIconColor: AppColors.warning,
                      chipText: '₹8/kWh from',
                      delay: 300,
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      role: 'host',
                      icon: Icons.ev_station,
                      title: 'Host',
                      description:
                          'List your idle home charger, set your rates, and earn passive income.',
                      chipIcon: Icons.trending_up,
                      chipIconColor: AppColors.primary,
                      chipText: 'Avg ₹4,800/mo',
                      delay: 500,
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      role: 'admin',
                      icon: Icons.business,
                      title: 'Society Admin',
                      description:
                          'Monitor shared EV chargers, track energy usage, and audit billing across your apartment complex.',
                      chipIcon: Icons.admin_panel_settings,
                      chipIconColor: AppColors.secondary,
                      chipText: 'Full Visibility',
                      delay: 700,
                    ),
                  ],
                ),
              ),
            ),
          ),
            // Bottom action
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    bgColor,
                    bgColor.withValues(alpha: 0.95),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _selectedRole != null
                      ? () {
                          if (_selectedRole == 'admin') {
                            context.go('/admin-dashboard');
                          } else {
                            context.go('/home');
                          }
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    disabledBackgroundColor: cs.surface,
                    disabledForegroundColor: cs.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required IconData icon,
    required String title,
    required String description,
    required IconData chipIcon,
    required Color chipIconColor,
    required String chipText,
    required int delay,
  }) {
    final isSelected = _selectedRole == role;
    final cs = Theme.of(context).colorScheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Ambient glow
            if (isSelected)
              Positioned(
                top: -96,
                right: -96,
                child: Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: GoogleFonts.sora(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    // Radio indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : cs.outlineVariant,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: cs.onPrimary,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  description,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(chipIcon, size: 16, color: chipIconColor),
                      const SizedBox(width: 6),
                      Text(
                        chipText,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1);
  }
}
