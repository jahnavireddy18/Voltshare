import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool locationShared = true;
  bool personalAds = false;
  bool analytics = true;

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      final role = AuthProvider().userRole;
      if (role == UserRole.admin) {
        context.go('/admin-dashboard');
      } else if (role == UserRole.host) {
        context.go('/host/dashboard');
      } else {
        context.go('/home');
      }
    }
  }

  void _showDataDeletionDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: cs.error, size: 24),
            const SizedBox(width: 10),
            Text(
              'Data Deletion',
              style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'To request permanent deletion of your profile, vehicle data, and charging history, please contact privacy@voltshare.app from your registered contact number. In demo mode, signing out resets active local sessions.',
          style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurfaceVariant, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Close', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: _handleBack,
        ),
        title: Text(
          'Privacy & Legal',
          style: GoogleFonts.sora(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Preferences',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 16),
            _buildToggleItem(
              title: 'Location Services',
              desc: 'Allow VoltShare to access your location for nearby charger discovery and routing.',
              value: locationShared,
              onChanged: (val) => setState(() => locationShared = val),
              index: 0,
            ),
            _buildToggleItem(
              title: 'Personalized Suggestions',
              desc: 'Receive station recommendations tailored to your vehicle connector type.',
              value: personalAds,
              onChanged: (val) => setState(() => personalAds = val),
              index: 1,
            ),
            _buildToggleItem(
              title: 'App Telemetry',
              desc: 'Share anonymous performance logs to help us improve station availability metrics.',
              value: analytics,
              onChanged: (val) => setState(() => analytics = val),
              index: 2,
            ),
            const SizedBox(height: 32),
            Text(
              'Legal & Policies',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ).animate().fadeIn(delay: 350.ms),
            const SizedBox(height: 16),
            _buildLinkItem(context, 'Privacy Policy', 3, '/privacy-policy'),
            _buildLinkItem(context, 'Terms of Service', 4, '/terms-of-service'),
            _buildLinkItem(
              context,
              'Data Deletion Request',
              5,
              null,
              isDestructive: true,
              onTapOverride: _showDataDeletionDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
    required int index,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: cs.onSurfaceVariant,
            inactiveTrackColor: cs.surfaceContainerHighest,
          ),
        ],
      ),
    ).animate().fadeIn(delay: (100 + index * 100).ms).slideX(begin: 0.1);
  }

  Widget _buildLinkItem(
    BuildContext context,
    String title,
    int index,
    String? route, {
    bool isDestructive = false,
    VoidCallback? onTapOverride,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (onTapOverride != null) {
              onTapOverride();
            } else if (route != null) {
              context.push(route);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDestructive ? cs.error.withValues(alpha: 0.3) : cs.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDestructive ? cs.error : cs.onSurface,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDestructive ? cs.error : cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 + index * 100).ms).slideX(begin: 0.1);
  }
}
