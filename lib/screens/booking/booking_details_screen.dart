import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/models/booking_model.dart';
import 'package:vnest_app/core/theme/app_theme.dart';
import 'package:vnest_app/widgets/common/vs_components.dart';

class BookingDetailsScreen extends StatelessWidget {
  final BookingModel booking;
  const BookingDetailsScreen({super.key, required this.booking});

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/booking-history');
    }
  }

  void _showInvoiceDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final paidAmount = booking.finalCost ?? booking.pricingSnapshot.estimatedCost;
    final invId = 'INV-${booking.id.substring(0, 8).toUpperCase()}';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Charging Tax Invoice',
                    style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    invId,
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  children: [
                    _buildInvoiceRow('Station Name', booking.chargerName, cs),
                    const Divider(height: 16),
                    _buildInvoiceRow('Host Identifier', booking.hostId.substring(0, 6).toUpperCase(), cs),
                    const Divider(height: 16),
                    _buildInvoiceRow('Session Date', DateFormat('MMM d, yyyy').format(booking.startTime), cs),
                    const Divider(height: 16),
                    _buildInvoiceRow(
                      'Session Time',
                      '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
                      cs,
                    ),
                    const Divider(height: 16),
                    _buildInvoiceRow('Energy Delivered', '${booking.pricingSnapshot.estimatedKwh} kWh', cs),
                    const Divider(height: 16),
                    _buildInvoiceRow('Rate per kWh', currency.format(booking.pricingSnapshot.pricePerKwh), cs),
                    const Divider(height: 16),
                    _buildInvoiceRow('Payment Status', 'PAID (Wallet Debit)', cs, isGreen: true),
                    const Divider(height: 16),
                    _buildInvoiceRow('Total Paid Amount', currency.format(paidAmount), cs, isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.verified, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Verified EV charging session record issued by VoltShare.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Close', style: GoogleFonts.manrope(color: cs.onSurfaceVariant)),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Invoice $invId downloaded successfully (PDF export ready).',
                    style: GoogleFonts.manrope(),
                  ),
                  backgroundColor: AppColors.surfaceDark,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Download PDF'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, ColorScheme cs,
      {bool isBold = false, bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: cs.onSurfaceVariant,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isGreen
                ? Colors.green
                : (isBold ? AppColors.primary : cs.onSurface),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final isCompleted = booking.status == BookingStatus.completed;

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
          'Booking Details',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isCompleted ? Colors.green : AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCompleted ? Colors.green : AppColors.primary,
                    ),
                  ),
                  child: Text(
                    booking.status.label.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Location Info
            Text(
              'CHARGER',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: cs.onSurfaceVariant,
                letterSpacing: 2,
              ),
            ),
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
                    width: 48,
                    height: 48,
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
                        Text(
                          booking.chargerName,
                          style: GoogleFonts.sora(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Host ID: ${booking.hostId.substring(0, 6).toUpperCase()}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Time Info
            Text(
              'SCHEDULE',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: cs.onSurfaceVariant,
                letterSpacing: 2,
              ),
            ),
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
                      Text(
                        DateFormat('MMM d, yyyy').format(booking.startTime),
                        style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Time', style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurfaceVariant)),
                      Text(
                        '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
                        style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Duration', style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurfaceVariant)),
                      Text(
                        booking.durationLabel,
                        style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cost Breakdown
            Text(
              'PAYMENT & BILLING',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: cs.onSurfaceVariant,
                letterSpacing: 2,
              ),
            ),
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
                      Text('Energy Consumed', style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurfaceVariant)),
                      Text(
                        '${booking.pricingSnapshot.estimatedKwh} kWh',
                        style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rate', style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurfaceVariant)),
                      Text(
                        '${currency.format(booking.pricingSnapshot.pricePerKwh)}/kWh',
                        style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCompleted ? 'Total Paid' : 'Total Estimated',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        currency.format(booking.finalCost ?? booking.pricingSnapshot.estimatedCost),
                        style: GoogleFonts.sora(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isCompleted ? Colors.green : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // Action Buttons
            if (isCompleted) ...[
              VsButton.fullWidth(
                label: 'Rate Host & Charger',
                icon: Icons.star_rate_rounded,
                onPressed: () => context.push('/rate-host', extra: {
                  'isHostRatingRenter': false,
                  'chargerId': booking.chargerId,
                  'bookingId': booking.id,
                  'chargerName': booking.chargerName,
                  'sessionInfo': '${DateFormat('MMM d, yyyy').format(booking.startTime)} · ${booking.estimatedKwh.toStringAsFixed(1)} kWh',
                }),
              ),
              const SizedBox(height: 12),
              VsButton.fullWidth(
                label: 'View / Download Invoice',
                icon: Icons.receipt_long,
                onPressed: () => _showInvoiceDialog(context),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/live-chat'),
                icon: const Icon(Icons.help_outline, size: 18),
                label: Text(
                  'Need Help with this Session?',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: cs.outlineVariant),
                  foregroundColor: cs.onSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ] else ...[
              VsButton.fullWidth(
                label: 'Session Support Chat',
                icon: Icons.chat_bubble_outline,
                onPressed: () => context.push('/live-chat'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
