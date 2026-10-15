import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/theme/app_theme.dart';
  
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    final options = [
      {'icon': Icons.chat_bubble_outline, 'title': 'Live Chat', 'desc': 'Chat with our support team'},
      {'icon': Icons.email_outlined, 'title': 'Email Support', 'desc': 'support@voltnest.com'},
      {'icon': Icons.help_outline, 'title': 'FAQ', 'desc': 'Find answers to common questions'},
      {'icon': Icons.report_problem_outlined, 'title': 'Report an Issue', 'desc': 'Report a bug or problem'},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('Help & Support', style: GoogleFonts.sora(
          fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface,
        )),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
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
                  Icon(Icons.support_agent, size: 64, color: cs.primary),
                  const SizedBox(height: 16),
                  Text('How can we help you?', style: GoogleFonts.sora(
                    fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface,
                  )),
                  const SizedBox(height: 8),
                  Text('We are here to assist you 24/7', style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: cs.onSurfaceVariant,
                  )),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),
            const SizedBox(height: 24),
            ...options.asMap().entries.map((e) {
              final option = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: cs.surface,
                          title: Text(option['title'] as String, style: TextStyle(color: cs.onSurface)),
                          content: Text('Opening ${option['title']}...', style: TextStyle(color: cs.onSurfaceVariant)),
                          actions: [
                            TextButton(
                              onPressed: () => context.pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: cs.outlineVariant),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(option['icon'] as IconData, color: cs.onSurface, size: 28),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(option['title'] as String, style: GoogleFonts.manrope(
                                  fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface,
                                )),
                                const SizedBox(height: 4),
                                Text(option['desc'] as String, style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, color: cs.onSurfaceVariant,
                                )),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: (200 + e.key * 100).ms).slideX(begin: 0.1);
            }),
          ],
        ),
      ),
    );
  }
}