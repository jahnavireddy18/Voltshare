import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vnest_app/core/models/pricing_models.dart';
import 'package:vnest_app/core/services/pricing_engine.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

import 'package:vnest_app/core/models/charger_model.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/services/booking_service.dart';

class BookConfirmScreen extends StatefulWidget {
  final ChargerModel charger;
  const BookConfirmScreen({super.key, required this.charger});

  @override
  State<BookConfirmScreen> createState() => _BookConfirmScreenState();
}

class _BookConfirmScreenState extends State<BookConfirmScreen> {
  String _selectedPayment = 'upi';
  final _pricingEngine = PricingEngine();
  final _bookingService = BookingService();
  PricingQuote? _quote;
  bool _loading = true;
  bool _isBooking = false;
  
  int _durationHours = 1;
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    _updateTimes();
    _loadPricing();
  }

  void _updateTimes() {
    _startTime = DateTime.now();
    _endTime = _startTime.add(Duration(hours: _durationHours));
  }

  Future<void> _loadPricing() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final contextObj = ChargerPricingContext(
        baseRatePerKwh: widget.charger.pricePerKwh,
        estimatedKwh: widget.charger.powerOutput * _durationHours,
        locationCluster: 1,
        powerTier: 1,
        rollingBookings: 0,
      );
      final quote = await _pricingEngine.getQuote(contextObj);
      if (mounted) setState(() { _quote = quote; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pricingEngine.clearCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface.withValues(alpha: 0.8),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.surfaceContainer,
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Icon(Icons.arrow_back, color: cs.onSurface, size: 20),
          ),
        ),
        title: Text(
          'REVIEW BOOKING',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            child: Column(
              children: [
                // Summary card
                _buildSummaryCard(context),
                const SizedBox(height: 24),
                // Duration picker
                _buildDurationPicker(context),
                const SizedBox(height: 24),
                // Cost breakdown
                _buildCostBreakdown(context),
                const SizedBox(height: 24),
                // Payment methods
                _buildPaymentMethods(context),
              ],
            ),
          ),
          // Bottom CTA
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomCta(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.charger.name, style: GoogleFonts.sora(
                      fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface,
                    )),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                          child: const Icon(Icons.person, size: 12, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Text('HOST ID: ${widget.charger.hostId.length >= 5 ? widget.charger.hostId.substring(0, 5).toUpperCase() : widget.charger.hostId.toUpperCase()}', style: GoogleFonts.jetBrainsMono(
                          fontSize: 11, color: cs.onSurfaceVariant, letterSpacing: 1,
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.ev_station, color: AppColors.primary, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bento grid
          Row(
            children: [
              // Time slot
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RESERVED SLOT', style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, color: cs.onSurfaceVariant,
                      )),
                      const SizedBox(height: 8),
                      Text('Today, ${DateFormat('HH:mm').format(_startTime)} - ${DateFormat('HH:mm').format(_endTime)}', style: GoogleFonts.sora(
                        fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface,
                      )),
                      const SizedBox(height: 4),
                      Text('$_durationHours hour(s) duration', style: GoogleFonts.manrope(
                        fontSize: 12, color: cs.onSurfaceVariant,
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Location
              Expanded(
                child: Container(
                  height: 100,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('LOCATION', style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, color: cs.onSurfaceVariant,
                      )),
                      Text(widget.charger.address, style: GoogleFonts.sora(
                        fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurface,
                      ),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildDurationPicker(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECT DURATION', style: GoogleFonts.jetBrainsMono(
          fontSize: 10, color: cs.onSurfaceVariant, letterSpacing: 2,
        )),
        const SizedBox(height: 12),
        Row(
          children: [1, 2, 3, 4].map((hours) {
            final isSelected = _durationHours == hours;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _durationHours = hours;
                    _updateTimes();
                    _loadPricing();
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: hours != 4 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : cs.outlineVariant,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${hours}h',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppColors.primary : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildCostBreakdown(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final quote = _quote;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PRICING SUMMARY', style: GoogleFonts.jetBrainsMono(
            fontSize: 10, color: cs.onSurfaceVariant, letterSpacing: 2,
          )),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              ),
            )
          else if (quote != null) ...[
            _costRow(
              context,
              'Base rate (₹${quote.baseRatePerKwh.toStringAsFixed(0)}/kWh)',
              currency.format(quote.baseCost),
              null,
            ),
            const SizedBox(height: 16),
            if (quote.hasSurge)
              _costRow(
                context,
                'Demand surcharge',
                '+${currency.format(quote.surcharge)}',
                AppColors.warning,
                badge: 'x${quote.surgeMultiplier}',
              ),
            if (quote.hasSurge) const SizedBox(height: 16),
            _buildDemandRow(context, quote),
            const SizedBox(height: 16),
            _costRow(
              context,
              'Estimated Energy',
              '${quote.estimatedKwh} kWh',
              cs.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: cs.outlineVariant),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('TOTAL TO PAY', style: GoogleFonts.jetBrainsMono(
                  fontSize: 12, color: cs.onSurfaceVariant,
                )),
                Text(currency.format(quote.totalCost), style: GoogleFonts.sora(
                  fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary,
                  letterSpacing: -1,
                )),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildDemandRow(BuildContext context, PricingQuote quote) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (quote.demandLevel) {
      DemandLevel.high => AppColors.warning,
      DemandLevel.medium => AppColors.primary,
      DemandLevel.low => cs.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_graph, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ML Predicted Demand: ${quote.demandLabel}',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Text(
            quote.source == PricingSource.ml ? 'ML' : 'Fallback',
            style: GoogleFonts.jetBrainsMono(fontSize: 10, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _costRow(BuildContext context, String label, String value, Color? valueColor, {String? badge}) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(label, style: GoogleFonts.manrope(
              fontSize: 14, color: cs.onSurfaceVariant,
            )),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(badge, style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, color: AppColors.warning,
                )),
              ),
            ],
          ],
        ),
        Text(value, style: GoogleFonts.sora(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: valueColor ?? cs.onSurface,
        )),
      ],
    );
  }

  Widget _buildPaymentMethods(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECT PAYMENT METHOD', style: GoogleFonts.jetBrainsMono(
          fontSize: 10, color: cs.onSurfaceVariant, letterSpacing: 2,
        )),
        const SizedBox(height: 12),
        _paymentOption(context, 'upi', Icons.qr_code_scanner, 'UPI / QR', 'GPay, PhonePe, Paytm', true),
        const SizedBox(height: 12),
        _paymentOption(context, 'card', Icons.credit_card, 'Credit/Debit Card', 'Visa, Mastercard, RuPay', true),
        const SizedBox(height: 12),
        _paymentOption(context, 'wallet', Icons.account_balance_wallet, 'Volt Wallet', 'Balance: ₹12.00 (Insufficient)', false),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _paymentOption(BuildContext context, String value, IconData icon, String title, String subtitle, bool enabled) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedPayment == value;
    return GestureDetector(
      onTap: enabled ? () => setState(() => _selectedPayment = value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: enabled ? cs.surfaceContainer : cs.surfaceContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : cs.surfaceContainerHighest,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : cs.outlineVariant,
                ),
              ),
              child: Icon(icon,
                color: isSelected ? AppColors.primary : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.sora(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: enabled ? cs.onSurface : cs.onSurfaceVariant.withValues(alpha: 0.5),
                  )),
                  Text(subtitle, style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: !enabled && value == 'wallet'
                        ? AppColors.warning
                        : cs.onSurfaceVariant,
                  )),
                ],
              ),
            ),
            // Radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : cs.outlineVariant,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12, height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCta(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = _quote != null
        ? NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2)
            .format(_quote!.totalCost)
        : '—';

    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SizedBox(
        width: double.infinity, height: 56,
        child: FilledButton.icon(
          onPressed: _loading || _quote == null || _isBooking ? null : _handleBooking,
          icon: _isBooking 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
            : const Icon(Icons.lock, size: 20),
          label: Text(
            _isBooking ? 'PROCESSING...' : 'CONFIRM & PAY $total', 
            style: GoogleFonts.sora(
              fontSize: 16, fontWeight: FontWeight.w800,
            )
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Future<void> _handleBooking() async {
    setState(() => _isBooking = true);
    try {
      final user = AuthProvider().currentUser;
      final userId = (user?.id != null && user!.id.isNotEmpty) ? user.id : 'demo_user_1';
      final userName = (user?.name != null && user!.name.isNotEmpty) ? user.name : 'EV Driver';

      final quote = _quote!;
      
      // Calculate estimated kWh based on power output and duration
      final estimatedKwh = widget.charger.powerOutput * _durationHours;

      final booking = await _bookingService.createBooking(
        userId: userId,
        userName: userName,
        chargerId: widget.charger.id,
        chargerName: widget.charger.name,
        hostId: widget.charger.hostId,
        startTime: _startTime,
        endTime: _endTime,
        pricePerKwh: quote.baseRatePerKwh,
        estimatedKwh: estimatedKwh,
      );

      if (mounted) {
        context.go('/booking-success', extra: booking);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }
}
