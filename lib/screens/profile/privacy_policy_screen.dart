import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  void _handleBack(BuildContext context) {
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
          onPressed: () => _handleBack(context),
        ),
        title: Text(
          'Privacy Policy',
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
            // Draft notice banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'VoltShare Privacy Policy · Draft Structure (Version 1.0)',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 16),
            Text(
              'Last Updated: October 2026',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              number: '1',
              title: 'Information We Collect',
              body:
                  'VoltShare collects only the information necessary to provide and manage EV charging services:\n\n'
                  '• Profile Data: Mobile phone number, optional display name, email address, and assigned role (Driver, Host, or Society Admin).\n'
                  '• Location Data: GPS location coordinates when searching for nearby chargers on the map or navigating to a station.\n'
                  '• Charging & Session Data: Station selection, reservation time slots, energy consumption (kWh), and session duration.\n'
                  '• Equipment & Vehicle Data: Charger hardware specifications, connector types, and user vehicle profiles (make, model, battery capacity).\n'
                  '• Transaction Data: Simulated session costs, platform fee calculations, and payout records.',
              cs: cs,
            ),
            _buildSection(
              number: '2',
              title: 'How We Use Your Information',
              body:
                  'We utilize the collected information to:\n'
                  '• Match EV drivers with available community and residential chargers.\n'
                  '• Allow Charger Hosts to manage schedules, track live charging sessions, and calculate earnings.\n'
                  '• Provide Society Admins with aggregate, anonymized energy consumption statistics for society infrastructure planning.\n'
                  '• Facilitate customer support inquiries and operational notifications.',
              cs: cs,
            ),
            _buildSection(
              number: '3',
              title: 'Data Sharing & Access Control',
              body:
                  'VoltShare strictly limits data sharing based on role-based access control:\n'
                  '• Hosts only receive driver arrival times and vehicle connector requirements necessary to facilitate physical access.\n'
                  '• Drivers only see host charger location and operating rules approved for public or community booking.\n'
                  '• Society Admins access aggregate telemetry and session logs within their own designated society boundary.\n'
                  '• We do not sell or monetize personal user records with third-party advertisers.',
              cs: cs,
            ),
            _buildSection(
              number: '4',
              title: 'Data Storage & User Control',
              body:
                  'Session tokens and preferences are maintained locally on your device and synchronized with our platform backend. Users can update their profile information or request account and data removal directly through the Privacy settings menu.',
              cs: cs,
            ),
            _buildSection(
              number: '5',
              title: 'Contact for Privacy Requests',
              body:
                  'For inquiries regarding privacy, data access requests, or policy clarification, please contact our privacy team at privacy@voltshare.app.',
              cs: cs,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String body,
    required ColorScheme cs,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 34.0),
            child: Text(
              body,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: cs.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
