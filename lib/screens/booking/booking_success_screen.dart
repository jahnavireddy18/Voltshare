import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

import 'package:vnest_app/core/models/booking_model.dart';
import 'package:intl/intl.dart';

class BookingSuccessScreen extends StatelessWidget {
  final BookingModel booking;
  const BookingSuccessScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Grid background
          Positioned.fill(child: CustomPaint(painter: _GridBgPainter(isDark: isDark))),
          // Ambient glow
          Positioned(
            top: -200, left: 0, right: 0,
            child: Container(
              height: 400, width: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.surfaceContainer,
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: IconButton(
                          onPressed: () => context.go('/home'),
                          icon: Icon(Icons.close, color: cs.onSurface, size: 20),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                                boxShadow: [BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                )],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('VN-STATUS: ACTIVE', style: GoogleFonts.jetBrainsMono(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant, letterSpacing: 1.5,
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                    child: Column(
                      children: [
                        // Hero
                        _buildHero(context),
                        const SizedBox(height: 32),
                        // Bento grid
                        _buildInfoGrid(context),
                        const SizedBox(height: 12),
                        _buildSlotTile(context),
                        const SizedBox(height: 12),
                        _buildLocationTile(context),
                        const SizedBox(height: 12),
                        _buildQrTile(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom CTA
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomActions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Animated rings
        SizedBox(
          width: 128, height: 128,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ...[1.5, 1.25, 1.1].asMap().entries.map((e) {
                return Container(
                  width: 80 * e.value, height: 80 * e.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2 + e.key * 0.2),
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat()).custom(
                  duration: (3000 - e.key * 500).ms,
                  builder: (_, v, child) => Transform.scale(
                    scale: 1.0 + (v * 0.1),
                    child: child,
                  ),
                );
              }),
              // Core circle
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.primary),
                  boxShadow: [BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 30,
                  )],
                ),
                child: const Icon(Icons.check, color: AppColors.primary, size: 40),
              ).animate().scale(begin: const Offset(0, 0), duration: 600.ms, curve: Curves.elasticOut),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('RESERVED', style: GoogleFonts.sora(
          fontSize: 32, fontWeight: FontWeight.w800, color: cs.onSurface, letterSpacing: -0.5,
        )).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        const SizedBox(height: 12),
        Text('Your power slot at ${booking.chargerName} is secured and ready.',
          style: GoogleFonts.manrope(
            fontSize: 15, color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }

  Widget _buildInfoGrid(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        // Booking ID
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VN-REF', style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, color: cs.onSurfaceVariant, letterSpacing: 1,
                )),
                const SizedBox(height: 8),
                Text('#${booking.id.substring(0, 8).toUpperCase()}', style: GoogleFonts.jetBrainsMono(
                  fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface,
                )),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Schedule
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SCHEDULE', style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, color: cs.onSurfaceVariant, letterSpacing: 1,
                )),
                const SizedBox(height: 8),
                Text('Today, ${DateFormat('HH:mm').format(booking.startTime)}', style: GoogleFonts.sora(
                  fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface,
                )),
                Text(booking.durationLabel + ' Duration', style: GoogleFonts.manrope(
                  fontSize: 12, color: cs.onSurfaceVariant,
                )),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildSlotTile(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SLOT ASSIGNMENT', style: GoogleFonts.jetBrainsMono(
                fontSize: 10, color: cs.onSurfaceVariant, letterSpacing: 1,
              )),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('A-15', style: GoogleFonts.sora(
                    fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary,
                  )),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('150kW Ultra Fast', style: GoogleFonts.manrope(
                      fontSize: 12, color: cs.onSurfaceVariant,
                    )),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.surfaceContainerHighest,
              border: Border.all(color: cs.outlineVariant),
            ),
            child: const Icon(Icons.bolt, color: AppColors.primary),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 900.ms);
  }

  Widget _buildLocationTile(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LOCATION', style: GoogleFonts.jetBrainsMono(
            fontSize: 10, color: cs.onSurfaceVariant, letterSpacing: 1,
          )),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: cs.surfaceContainerHighest,
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Icon(Icons.ev_station, color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.chargerName, style: GoogleFonts.sora(
                      fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface,
                    )),
                    Text('Host: ${booking.hostId.substring(0, 5).toUpperCase()}', style: GoogleFonts.manrope(
                      fontSize: 12, color: cs.onSurfaceVariant,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1000.ms);
  }

  Widget _buildQrTile(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.05),
          blurRadius: 20,
        )],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('SCAN AT TERMINAL', style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, color: AppColors.primary, letterSpacing: 1,
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Present this code at the A-15 terminal scanner to unlock the charging cable.',
                  style: GoogleFonts.manrope(fontSize: 13, color: cs.onSurfaceVariant, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // QR placeholder
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(Icons.qr_code, size: 80, color: Colors.black.withValues(alpha: 0.8)),
                ),
                // Corner markers
                Positioned(top: 0, left: 0, child: Container(width: 12, height: 12,
                  decoration: const BoxDecoration(border: Border(
                    top: BorderSide(color: AppColors.primary, width: 2),
                    left: BorderSide(color: AppColors.primary, width: 2),
                  )),
                )),
                Positioned(top: 0, right: 0, child: Container(width: 12, height: 12,
                  decoration: const BoxDecoration(border: Border(
                    top: BorderSide(color: AppColors.primary, width: 2),
                    right: BorderSide(color: AppColors.primary, width: 2),
                  )),
                )),
                Positioned(bottom: 0, left: 0, child: Container(width: 12, height: 12,
                  decoration: const BoxDecoration(border: Border(
                    bottom: BorderSide(color: AppColors.primary, width: 2),
                    left: BorderSide(color: AppColors.primary, width: 2),
                  )),
                )),
                Positioned(bottom: 0, right: 0, child: Container(width: 12, height: 12,
                  decoration: const BoxDecoration(border: Border(
                    bottom: BorderSide(color: AppColors.primary, width: 2),
                    right: BorderSide(color: AppColors.primary, width: 2),
                  )),
                )),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1100.ms);
  }

  Widget _buildBottomActions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.8),
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity, height: 56,
            child: FilledButton(
              onPressed: () => context.push('/booking-details', extra: booking),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('View Booking', style: GoogleFonts.sora(
                fontSize: 15, fontWeight: FontWeight.w700,
              )),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Added to Apple/Google Wallet!'),
                          backgroundColor: cs.inverseSurface,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.account_balance_wallet, size: 18),
                    label: const Text('Add to Wallet'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.onSurface,
                      side: BorderSide(color: cs.outlineVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Opening Maps...'),
                          backgroundColor: cs.inverseSurface,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Directions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.onSurface,
                      side: BorderSide(color: cs.outlineVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridBgPainter extends CustomPainter {
  final bool isDark;

  _GridBgPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridBgPainter oldDelegate) => isDark != oldDelegate.isDark;
}
