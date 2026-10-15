import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/models/booking_model.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/services/booking_service.dart';
import 'package:vnest_app/core/theme/app_theme.dart';
import 'package:vnest_app/widgets/common/vs_components.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _bookingService = BookingService();
  bool _isLoading = true;
  List<BookingModel> _upcomingBookings = [];
  List<BookingModel> _pastBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthProvider().currentUser;
      if (user != null) {
        final allBookings = await _bookingService.getBookingsByUser(user.id);
        
        final now = DateTime.now();
        setState(() {
          _upcomingBookings = allBookings.where((b) => 
            b.startTime.isAfter(now) && 
            (b.status == BookingStatus.confirmed || b.status == BookingStatus.pending)
          ).toList();
          
          _pastBookings = allBookings.where((b) => 
            !_upcomingBookings.contains(b)
          ).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('Booking History', style: GoogleFonts.sora(
          fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface,
        )),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsList(_upcomingBookings, 'No upcoming bookings'),
              _buildBookingsList(_pastBookings, 'No past bookings'),
            ],
          ),
    );
  }

  Widget _buildBookingsList(List<BookingModel> bookings, String emptyMessage) {
    if (bookings.isEmpty) {
      return VsEmptyState(
        icon: Icons.event_busy,
        title: emptyMessage,
        subtitle: 'When you book a charger, it will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking)
          .animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final cs = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    
    Color statusColor;
    switch (booking.status) {
      case BookingStatus.confirmed:
        statusColor = AppColors.primary;
        break;
      case BookingStatus.active:
        statusColor = Colors.blue;
        break;
      case BookingStatus.completed:
        statusColor = cs.onSurfaceVariant;
        break;
      case BookingStatus.cancelled:
        statusColor = cs.error;
        break;
      case BookingStatus.pending:
        statusColor = AppColors.warning;
        break;
      case BookingStatus.expired:
        statusColor = cs.onSurfaceVariant;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: cs.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/booking-details', extra: booking),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${DateFormat('MMM d, yyyy').format(booking.startTime)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      booking.status.label.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, fontWeight: FontWeight.bold, color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                booking.chargerName,
                style: GoogleFonts.sora(
                  fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
                    style: GoogleFonts.manrope(
                      fontSize: 14, color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.payments, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    '${currency.format(booking.pricingSnapshot.estimatedCost)} estimated',
                    style: GoogleFonts.manrope(
                      fontSize: 14, color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
