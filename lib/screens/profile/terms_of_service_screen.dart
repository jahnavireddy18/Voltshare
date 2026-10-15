import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
            // Draft status notice banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'VoltShare Platform Terms · Draft Structure (Version 1.0)',
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
              title: 'Acceptance & Scope',
              body:
                  'By creating an account or accessing the VoltShare platform as an EV Driver, Charger Host, or Society Admin, you agree to comply with and be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.',
              cs: cs,
            ),
            _buildSection(
              number: '2',
              title: 'User Roles & Accounts',
              body:
                  'VoltShare supports three distinct user roles:\n'
                  '• EV Drivers: Reserve, initiate, and pay for charging sessions at registered community and private chargers.\n'
                  '• Charger Hosts: List private or residential charging equipment, define availability schedules, and receive earnings.\n'
                  '• Society Admins: Monitor residential society EV infrastructure, oversee load distribution, and view anonymized session metrics.\n\n'
                  'You are responsible for safeguarding your login credentials and maintaining accurate profile information.',
              cs: cs,
            ),
            _buildSection(
              number: '3',
              title: 'Charging Sessions & Station Conduct',
              body:
                  'Drivers agree to use charging equipment according to manufacturer safety guidelines and host instructions. Vehicles must be vacated from charging bays upon session completion to avoid idle fees. Misuse, physical damage, or tampering with charging points is strictly prohibited.',
              cs: cs,
            ),
            _buildSection(
              number: '4',
              title: 'Host Commitments & Hardware Compatibility',
              body:
                  'Charger Hosts agree to provide reliable electrical equipment that complies with local safety standards. Hosts must ensure access permissions (e.g. visitor gate clearance) are communicated accurately to verified drivers through the platform.',
              cs: cs,
            ),
            _buildSection(
              number: '5',
              title: 'Payments, Pricing & Fees',
              body:
                  'All charging rates, energy consumption rates (per kWh), and platform fees are clearly presented prior to booking confirmation. Hosts receive payouts minus the standard platform administration fee. Completed sessions generate digital statements reflecting actual energy utilized.',
              cs: cs,
            ),
            _buildSection(
              number: '6',
              title: 'Limitation of Liability',
              body:
                  'VoltShare connects drivers with independent host chargers and residential societies. While we facilitate connectivity and payment processing, VoltShare does not guarantee continuous power availability from local municipal grids and is not liable for vehicle mechanical conditions.',
              cs: cs,
            ),
            _buildSection(
              number: '7',
              title: 'Modifications & Contact',
              body:
                  'VoltShare reserves the right to update these terms to reflect feature additions or regulatory requirements. Questions regarding these Terms should be directed to support@voltshare.app.',
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
