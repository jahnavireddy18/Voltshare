import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/models/booking_model.dart';
import 'package:vnest_app/core/models/charger_model.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/services/booking_service.dart';
import 'package:vnest_app/core/services/charger_service.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({super.key});

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  final _bookingService = BookingService();
  final _chargerService = ChargerService();

  bool _isLoading = true;
  List<ChargerModel> _chargers = [];
  List<BookingModel> _todayBookings = [];
  List<BookingModel> _liveSessions = [];
  double _todayEarnings = 0.0;
  double _todayKwh = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final hostId = AuthProvider().currentUser?.id;
      if (hostId == null) return;

      final chargers = await _chargerService.getChargersByHost(hostId);
      final allBookings = await _bookingService.getBookingsByHost(hostId);

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      double earnings = 0.0;
      double kwh = 0.0;
      List<BookingModel> todayBookings = [];
      List<BookingModel> liveSessions = [];

      for (var b in allBookings) {
        // Today's bookings
        if (b.startTime.isAfter(startOfDay) && b.startTime.isBefore(endOfDay)) {
          todayBookings.add(b);
          
          if (b.status == BookingStatus.completed) {
            earnings += (b.finalCost ?? b.pricingSnapshot.estimatedCost) * 0.9; // 10% platform fee
            // We'll estimate kwh if it's not directly on booking, or we could fetch the session.
            // For now, reverse calculate from finalCost if available.
            if (b.finalCost != null && b.pricingSnapshot.pricePerKwh > 0) {
              kwh += b.finalCost! / b.pricingSnapshot.pricePerKwh;
            }
          }
        }
        // Active sessions
        if (b.status == BookingStatus.active) {
          liveSessions.add(b);
        }
      }

      if (mounted) {
        setState(() {
          _chargers = chargers;
          _todayBookings = todayBookings;
          _liveSessions = liveSessions;
          _todayEarnings = earnings;
          _todayKwh = kwh;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading host dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                
                if (_chargers.isNotEmpty) ...[
                  _buildChargerStatusCard(_chargers.first),
                  const SizedBox(height: 16),
                ] else ...[
                  _buildNoChargersCard(),
                  const SizedBox(height: 16),
                ],

                _buildTodaysEarningsCard(),
                const SizedBox(height: 16),
                
                if (_liveSessions.isNotEmpty) ...[
                  ..._liveSessions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildLiveSessionCard(s),
                  )),
                ],

                _buildRateRenterCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoChargersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.ev_station, color: AppColors.primary.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text(
            'No chargers added yet.',
            style: GoogleFonts.manrope(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => context.push('/host/charger-form'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add Charger'),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Charger avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.3),
                AppColors.primaryDark.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.dashboard,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'Dashboard',
          style: GoogleFonts.sora(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        // Notification bell
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        // Logout button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: IconButton(
            key: const Key('host_logout_button'),
            padding: EdgeInsets.zero,
            tooltip: 'Log Out',
            icon: const Icon(
              Icons.logout,
              color: AppColors.error,
              size: 20,
            ),
            onPressed: () => AuthProvider.showLogoutDialog(context),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05);
  }

  Widget _buildChargerStatusCard(ChargerModel topCharger) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topCharger.name,
                      style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${topCharger.powerOutput} kW AC • ${topCharger.connectorType.name.toUpperCase()}',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ONLINE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Heartbeat info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariantDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderDark,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wifi,
                  size: 16,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connected to VoltShare Cloud',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.04);
  }

  Widget _buildTodaysEarningsCard() {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final completedCount = _todayBookings.where((b) => b.status == BookingStatus.completed).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A3A1A),
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.surfaceDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S EARNINGS",
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            currency.format(_todayEarnings),
            style: GoogleFonts.sora(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completedCount sessions · ${_todayKwh.toStringAsFixed(1)} kWh',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.04);
  }

  Widget _buildLiveSessionCard(BookingModel session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live session header
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE SESSION',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Renter info
          Text(
            '${session.userName.isEmpty ? 'Guest' : session.userName} · ${DateFormat('jm').format(session.startTime)}–${DateFormat('jm').format(session.endTime)} slot',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          // kWh and earnings (Estimated)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Charging...',
                      style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${session.pricingSnapshot.estimatedKwh.toStringAsFixed(1)} kWh Est.',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+₹${(session.pricingSnapshot.estimatedCost * 0.9).toStringAsFixed(2)}',
                    style: GoogleFonts.sora(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Est. Earnings',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.04);
  }

  Widget _buildRateRenterCard() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.star,
                color: AppColors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate your last renter',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Share your feedback',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 24,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(begin: 0.04);
  }
}
