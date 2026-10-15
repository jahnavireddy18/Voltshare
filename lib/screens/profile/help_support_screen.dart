import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedFaqIndex;

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

  void _showEmailSheet(BuildContext context, String email, String roleLabel) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Email Support',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Direct correspondence channel for $roleLabel.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mail_outline, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SelectableText(
                        email,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy Email',
                      icon: const Icon(Icons.copy, size: 20, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: email));
                        Navigator.of(sheetCtx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Email address copied to clipboard: $email',
                              style: GoogleFonts.manrope(),
                            ),
                            backgroundColor: AppColors.surfaceDark,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Operating hours: Monday – Sunday, 8:00 AM – 10:00 PM IST.\nTypical response turnaround: within 4 business hours.',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportIssueDialog(BuildContext context, UserRole role) {
    final cs = Theme.of(context).colorScheme;
    final textController = TextEditingController();
    String selectedCategory = role == UserRole.host
        ? 'Charger Hardware / Offline'
        : (role == UserRole.admin ? 'Society Load Discrepancy' : 'Station / Connector Issue');

    final categories = role == UserRole.host
        ? [
            'Charger Hardware / Offline',
            'Payout / Statement Discrepancy',
            'Driver Conduct / Overstay',
            'App Bug / Sync Issue',
          ]
        : (role == UserRole.admin
            ? [
                'Society Load Discrepancy',
                'Unregistered Vehicle in Bay',
                'Meter / Telemetry Delay',
                'Admin Permission Request',
              ]
            : [
                'Station / Connector Issue',
                'Billing & Payment Question',
                'Access Gate / Parking Bay Blocked',
                'App Bug / Session Not Starting',
              ]);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogStateCtx, setDialogState) => Dialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Report an Issue',
                          style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: cs.onSurfaceVariant, size: 20),
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Issue Category',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: cs.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat, style: GoogleFonts.manrope(fontSize: 13, color: cs.onSurface)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController,
                      maxLines: 4,
                      style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Please describe the issue in detail...',
                        hintStyle: GoogleFonts.manrope(fontSize: 13, color: cs.onSurfaceVariant),
                        filled: true,
                        fillColor: cs.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          child: Text('Cancel', style: GoogleFonts.manrope(color: cs.onSurfaceVariant)),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final text = textController.text.trim();
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.of(dialogCtx).pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  text.isEmpty
                                      ? 'Issue logged for review under $selectedCategory.'
                                      : 'Issue ticket recorded under $selectedCategory. Support will review shortly.',
                                  style: GoogleFonts.manrope(),
                                ),
                                backgroundColor: AppColors.surfaceDark,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Submit Report'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> _getFaqsForRole(UserRole role) {
    switch (role) {
      case UserRole.host:
        return [
          {
            'q': 'How do I set and update my charging rate?',
            'a':
                'Navigate to Host Dashboard > My Chargers > Edit Charger to adjust your base rate per kWh and peak hour pricing rules. Changes apply immediately to new bookings.',
          },
          {
            'q': 'When and how are host payouts transferred?',
            'a':
                'Host earnings are accumulated and recorded in Host Earnings. VoltShare calculates net earnings after deducting a 10% platform fee for connectivity and payment processing.',
          },
          {
            'q': 'What should I do if a driver leaves their car parked?',
            'a':
                'You can message the driver directly via Host Chat or contact community gate security to request vehicle relocation once charging completes.',
          },
          {
            'q': 'What electrical hardware is supported?',
            'a':
                'VoltShare supports standard Type 2 AC chargers (3.3 kW to 22 kW) and CCS2 DC fast chargers compatible with OCPP 1.6J+ protocols.',
          },
        ];
      case UserRole.admin:
        return [
          {
            'q': 'How does Society Admin access work?',
            'a':
                'Society Admins have read-only visibility into community chargers installed across apartment wings, shared visitor parking, and residential basements.',
          },
          {
            'q': 'How is power load managed across towers?',
            'a':
                'The Society Admin Dashboard aggregates real-time grid demand, ensuring total concurrent EV draw does not exceed sanctioned transformer thresholds.',
          },
          {
            'q': 'How are resident vs guest sessions distinguished?',
            'a':
                'Chargers designated in private resident bays are restricted to approved resident profiles, while visitor bays accept public bookings.',
          },
          {
            'q': 'Where do I find society energy reports?',
            'a':
                'The Overview and Sessions tabs in the Society Admin Dashboard provide daily energy utilization, total kWh delivered, and peak charging intervals.',
          },
        ];
      case UserRole.user:
      default:
        return [
          {
            'q': 'How do I unlock and start a charging session?',
            'a':
                'Navigate to your reserved charger, ensure your vehicle is plugged in securely, and tap "Start Session" in the app. The charger relay will engage automatically.',
          },
          {
            'q': 'What happens if I stay parked after charging completes?',
            'a':
                'To ensure equitable access for all EV owners, idle fees may apply after a 15-minute grace period once charging reaches 100%.',
          },
          {
            'q': 'How are charging costs and receipts calculated?',
            'a':
                'Sessions are priced per kWh based on the host\'s published rate. You can view itemized receipts and session summaries directly from Booking Details or Booking History.',
          },
          {
            'q': 'Can I cancel a scheduled reservation?',
            'a':
                'Yes, reservations can be cancelled from the Booking Details screen prior to the session start window without cancellation penalty.',
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;
    final role = AuthProvider().userRole;

    final roleLabel = role == UserRole.admin
        ? 'Society Admin'
        : (role == UserRole.host ? 'Charger Host' : 'EV Driver');

    final emailAddress = role == UserRole.admin
        ? 'society@voltshare.app'
        : (role == UserRole.host ? 'hosts@voltshare.app' : 'support@voltshare.app');

    final faqs = _getFaqsForRole(role);

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
          'Help & Support',
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
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF131313), const Color(0xFF1A1A1A)]
                      : [cs.surfaceContainerHighest, cs.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  Icon(Icons.support_agent, size: 54, color: AppColors.primary),
                  const SizedBox(height: 14),
                  Text(
                    'How can we assist you?',
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '$roleLabel Support Desk',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.05),
            const SizedBox(height: 24),

            // Support Action Tiles
            Text(
              'Contact Support',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Live Chat Option
            _buildActionCard(
              context: context,
              icon: Icons.chat_bubble_outline,
              title: 'Live Support Chat',
              desc: 'Direct text queue for session, station, or billing inquiries',
              badge: 'AVAILABLE',
              onTap: () => context.push('/live-chat'),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 12),

            // Email Support Option
            _buildActionCard(
              context: context,
              icon: Icons.email_outlined,
              title: 'Email Support Desk',
              desc: emailAddress,
              onTap: () => _showEmailSheet(context, emailAddress, roleLabel),
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 12),

            // Report an Issue Option
            _buildActionCard(
              context: context,
              icon: Icons.report_problem_outlined,
              title: 'Report an Issue',
              desc: 'Submit technical, hardware, or billing tickets',
              onTap: () => _showReportIssueDialog(context, role),
            ).animate().fadeIn(delay: 350.ms),

            const SizedBox(height: 32),

            // Role-Specific FAQ Section
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            ...faqs.asMap().entries.map((entry) {
              final index = entry.key;
              final faq = entry.value;
              final isExpanded = _expandedFaqIndex == index;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isExpanded ? AppColors.primary.withValues(alpha: 0.4) : cs.outlineVariant,
                  ),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: Key('faq_tile_$index'),
                    initiallyExpanded: isExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _expandedFaqIndex = expanded ? index : null;
                      });
                    },
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.help_outline,
                        size: 18,
                        color: isExpanded ? AppColors.primary : cs.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      faq['q']!,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faq['a']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
    String? badge,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}