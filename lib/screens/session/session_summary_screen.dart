import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vnest_app/core/models/booking_model.dart';
import 'package:vnest_app/core/models/session_model.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class SessionSummaryScreen extends StatefulWidget {
  final SessionModel session;
  const SessionSummaryScreen({super.key, required this.session});

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  BookingModel? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBooking();
  }

  Future<void> _fetchBooking() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.session.bookingId)
          .get();
      if (doc.exists) {
        setState(() => _booking = BookingModel.fromFirestore(doc));
      }
    } catch (e) {
      debugPrint('Error fetching booking: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    final energy = widget.session.energyConsumed;
    final cost = _booking != null
        ? energy * _booking!.pricingSnapshot.pricePerKwh
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    // Checkmark icon
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      child: const Icon(Icons.check_circle,
                          color: AppColors.primary, size: 48),
                    ).animate().scale(
                        duration: 600.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 24),
                    Text('Charging Complete',
                        style: GoogleFonts.manrope(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDarkPrimary,
                        )).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 8),
                    Text(
                        'Session #${widget.session.id.substring(0, 8).toUpperCase()}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.textDarkSecondary,
                        )).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 48),

                    // Receipt Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Final Cost
                          Text('Total Cost',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDarkSecondary,
                              )),
                          const SizedBox(height: 8),
                          Text(currency.format(cost),
                              style: GoogleFonts.manrope(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDarkPrimary,
                                letterSpacing: -1,
                              )),
                          const SizedBox(height: 32),
                          const Divider(height: 1),
                          const SizedBox(height: 24),

                          // Details
                          _buildReceiptRow('Energy Delivered',
                              '${energy.toStringAsFixed(2)} kWh', cs),
                          const SizedBox(height: 16),
                          _buildReceiptRow(
                              'Duration', widget.session.durationLabel, cs),
                          const SizedBox(height: 16),
                          if (_booking != null) ...[
                            _buildReceiptRow(
                                'Rate',
                                '${currency.format(_booking!.pricingSnapshot.pricePerKwh)}/kWh',
                                cs),
                            const SizedBox(height: 16),
                            _buildReceiptRow('Location',
                                _booking!.chargerName, cs),
                          ],
                        ],
                      ),
                    ).animate().slideY(begin: 0.2).fadeIn(delay: 400.ms),
                    const SizedBox(height: 48),

                    // Rating
                    Text('How was your experience?',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDarkPrimary,
                        )).animate().fadeIn(delay: 600.ms),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.star_border,
                              color: AppColors.outlineVariant, size: 40),
                        );
                      }),
                    ).animate().fadeIn(delay: 700.ms),
                    const SizedBox(height: 48),

                    // Actions
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: () => context.go('/home'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Back to Home',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ).animate().fadeIn(delay: 800.ms),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReceiptRow(String label, String value, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textDarkSecondary,
            )),
        Text(value,
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDarkPrimary,
            )),
      ],
    );
  }
}
