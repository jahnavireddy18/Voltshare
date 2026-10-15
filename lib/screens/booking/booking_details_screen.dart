import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vnest_app/core/models/booking_model.dart';
import 'package:vnest_app/core/theme/app_theme.dart';
import 'package:vnest_app/widgets/common/vs_components.dart';

class BookingDetailsScreen extends StatelessWidget {
  final BookingModel booking;
  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('Booking Details', style: GoogleFonts.sora(
          fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface,
        )),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: #${booking.id.substring(0, 8).toUpperCase()}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Text(
                    booking.status.label.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Location Info
            Text('CHARGER', style: GoogleFonts.jetBrainsMono(
              fontSize: 10, color: cs.onSurfaceVariant, letterSpacing: 2,
            )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.ev_station, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.chargerName, style: GoogleFonts.sora(
                          fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface,
                        )),
                        const SizedBox(height: 4),
                        Text('Host ID: ${booking.hostId.substring(0, 5).toUpperCase()}', style: GoogleFonts.manrope(
                          fontSize: 12, color: cs.onSurfaceVariant,
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Time Info
            Text('SCHEDULE', style: GoogleFonts.jetBrainsMono(
              fontSize: 10, color: cs.onSurfaceVariant, letterSpacing: 2,
            )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Date', style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurfaceVariant)),
                      Text(DateFormat('MMM d, yyyy').format(booking.startTime), style: GoogleFonts.sora(
                        fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface,
                      )),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Time', style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurfaceVariant)),
                      Text('${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}', style: GoogleFonts.sora(
                        fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface,
                      )),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Duration', style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurfaceVariant)),
                      Text(booking.durationLabel, style: GoogleFonts.sora(
                        fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface,
                      )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cost Breakdown
            Text('PAYMENT', style: GoogleFonts.jetBrainsMono(
              fontSize: 10, color: cs.onSurfaceVariant, letterSpacing: 2,
            )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Estimated Energy', style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurfaceVariant)),
                      Text('${booking.pricingSnapshot.estimatedKwh} kWh', style: GoogleFonts.sora(
                        fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface,
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rate', style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurfaceVariant)),
                      Text('${currency.format(booking.pricingSnapshot.pricePerKwh)}/kWh', style: GoogleFonts.sora(
                        fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface,
                      )),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Estimated', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      Text(currency.format(booking.pricingSnapshot.estimatedCost), style: GoogleFonts.sora(
                        fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary,
                      )),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            VsButton.fullWidth(
              label: 'Navigate to Charger',
              icon: Icons.navigation,
              onPressed: () {
                 // Placeholder for navigation
              },
            ),
          ],
        ),
      ),
    );
  }
}
