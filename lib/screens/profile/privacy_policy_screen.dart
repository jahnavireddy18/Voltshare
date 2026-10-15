import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('Privacy Policy', style: GoogleFonts.sora(
          fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface,
        )),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last updated: June 2026', style: GoogleFonts.plusJakartaSans(
              fontSize: 14, color: cs.onSurfaceVariant,
            )).animate().fadeIn(),
            const SizedBox(height: 24),
            Text('1. Information We Collect', style: GoogleFonts.manrope(
              fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface,
            )).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
            const SizedBox(height: 8),
            Text('We collect your location, payment details, and charging history to provide you with the best experience and tailored charger recommendations.', style: GoogleFonts.plusJakartaSans(
              fontSize: 14, color: cs.onSurfaceVariant, height: 1.5,
            )).animate().fadeIn(delay: 150.ms).slideX(begin: 0.1),
            const SizedBox(height: 24),
            Text('2. How We Use Information', style: GoogleFonts.manrope(
              fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface,
            )).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
            const SizedBox(height: 8),
            Text('We use your data to facilitate EV charging sessions, process payments, and improve our network coverage and app performance.', style: GoogleFonts.plusJakartaSans(
              fontSize: 14, color: cs.onSurfaceVariant, height: 1.5,
            )).animate().fadeIn(delay: 250.ms).slideX(begin: 0.1),
            const SizedBox(height: 24),
            Text('3. Data Sharing', style: GoogleFonts.manrope(
              fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface,
            )).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
            const SizedBox(height: 8),
            Text('We do not sell your personal data. Data is shared with our charging partners only to the extent necessary to authenticate your sessions.', style: GoogleFonts.plusJakartaSans(
              fontSize: 14, color: cs.onSurfaceVariant, height: 1.5,
            )).animate().fadeIn(delay: 350.ms).slideX(begin: 0.1),
            const SizedBox(height: 24),
            Text('4. Your Rights', style: GoogleFonts.manrope(
              fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface,
            )).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
            const SizedBox(height: 8),
            Text('You can request deletion of your account and associated data at any time from the Privacy settings menu.', style: GoogleFonts.plusJakartaSans(
              fontSize: 14, color: cs.onSurfaceVariant, height: 1.5,
            )).animate().fadeIn(delay: 450.ms).slideX(begin: 0.1),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
