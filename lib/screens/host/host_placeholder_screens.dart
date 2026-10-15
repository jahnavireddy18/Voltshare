import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

import 'package:go_router/go_router.dart';
import 'package:vnest_app/core/models/charger_model.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/services/charger_service.dart';
import 'package:intl/intl.dart';
import 'package:vnest_app/core/models/booking_model.dart';
import 'package:vnest_app/core/services/booking_service.dart';
import 'package:vnest_app/core/enums/app_enums.dart';

class HostChargersScreen extends StatefulWidget {
  const HostChargersScreen({super.key});

  @override
  State<HostChargersScreen> createState() => _HostChargersScreenState();
}

class _HostChargersScreenState extends State<HostChargersScreen> {
  final _chargerService = ChargerService();
  bool _isLoading = true;
  List<ChargerModel> _chargers = [];

  @override
  void initState() {
    super.initState();
    _loadChargers();
  }

  Future<void> _loadChargers() async {
    setState(() => _isLoading = true);
    final hostId = AuthProvider().currentUser?.id;
    if (hostId != null) {
      final chargers = await _chargerService.getChargersByHost(hostId);
      if (mounted) setState(() => _chargers = chargers);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Chargers', style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/host/charger-form');
          _loadChargers();
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chargers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.ev_station, size: 64, color: cs.primary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('No chargers yet', style: GoogleFonts.manrope(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Tap + to add your first charger', style: GoogleFonts.manrope(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chargers.length,
                  itemBuilder: (context, index) {
                    final charger = _chargers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.ev_station, color: cs.onPrimaryContainer),
                        ),
                        title: Text(charger.name, style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                        subtitle: Text(charger.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                await context.push('/host/charger-form', extra: charger.id);
                                _loadChargers();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class HostEarningsScreen extends StatefulWidget {
  const HostEarningsScreen({super.key});

  @override
  State<HostEarningsScreen> createState() => _HostEarningsScreenState();
}

class _HostEarningsScreenState extends State<HostEarningsScreen> {
  final _bookingService = BookingService();
  bool _isLoading = true;
  double _totalEarnings = 0.0;
  double _totalKwh = 0.0;
  int _completedSessions = 0;
  List<BookingModel> _recentCompletedBookings = [];

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);
    try {
      final hostId = AuthProvider().currentUser?.id;
      if (hostId != null) {
        final allBookings = await _bookingService.getBookingsByHost(hostId);
        
        double earnings = 0.0;
        double kwh = 0.0;
        int count = 0;
        List<BookingModel> completedBookings = [];

        for (var b in allBookings) {
          if (b.status == BookingStatus.completed) {
            completedBookings.add(b);
            count++;
            
            final revenue = b.finalCost ?? b.pricingSnapshot.estimatedCost;
            earnings += revenue * 0.9; // 10% platform fee
            
            if (b.finalCost != null && b.pricingSnapshot.pricePerKwh > 0) {
              kwh += b.finalCost! / b.pricingSnapshot.pricePerKwh;
            } else {
              kwh += b.pricingSnapshot.estimatedKwh;
            }
          }
        }

        if (mounted) {
          setState(() {
            _totalEarnings = earnings;
            _totalKwh = kwh;
            _completedSessions = count;
            _recentCompletedBookings = completedBookings;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading earnings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text('Earnings', style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarnings,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.primaryContainer],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text('Total Revenue (after 10% fee)',
                            style: GoogleFonts.manrope(
                              color: cs.onPrimary.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 8),
                        Text(currency.format(_totalEarnings),
                            style: GoogleFonts.sora(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimary,
                            )),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text('Sessions',
                                    style: GoogleFonts.manrope(color: cs.onPrimary)),
                                Text('$_completedSessions',
                                    style: GoogleFonts.sora(
                                        color: cs.onPrimary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Container(width: 1, height: 30, color: cs.onPrimary.withValues(alpha: 0.5)),
                            Column(
                              children: [
                                Text('Energy (kWh)',
                                    style: GoogleFonts.manrope(color: cs.onPrimary)),
                                Text(_totalKwh.toStringAsFixed(1),
                                    style: GoogleFonts.sora(
                                        color: cs.onPrimary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Recent Payouts', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_recentCompletedBookings.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text('No completed sessions yet.',
                            style: GoogleFonts.manrope(color: cs.onSurfaceVariant)),
                      ),
                    )
                  else
                    ..._recentCompletedBookings.take(10).map((b) {
                      final gross = b.finalCost ?? b.pricingSnapshot.estimatedCost;
                      final netAmount = gross * 0.9;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Icon(Icons.attach_money, color: cs.onPrimaryContainer),
                          ),
                          title: Text(currency.format(netAmount), style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
                          subtitle: Text('${b.chargerName} • ${DateFormat.yMMMd().format(b.startTime)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Settled', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, size: 18),
                            ],
                          ),
                          onTap: () => _showStatementDialog(context, b, gross, netAmount),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  void _showStatementDialog(BuildContext context, BookingModel b, double gross, double netAmount) {
    final cs = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final fee = gross * 0.1;

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
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.receipt_long, color: cs.onPrimaryContainer, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Host Payout Statement',
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  children: [
                    _buildRow('Payout Ref', '#${b.id.substring(0, 8).toUpperCase()}', cs),
                    const Divider(height: 16),
                    _buildRow('Station', b.chargerName, cs),
                    const Divider(height: 16),
                    _buildRow('Date', DateFormat.yMMMd().add_jm().format(b.startTime), cs),
                    const Divider(height: 16),
                    _buildRow('Session Energy', '${b.pricingSnapshot.estimatedKwh} kWh', cs),
                    const Divider(height: 16),
                    _buildRow('Gross Revenue', currency.format(gross), cs),
                    const Divider(height: 16),
                    _buildRow('Platform Fee (10%)', '-${currency.format(fee)}', cs, isNegative: true),
                    const Divider(height: 16),
                    _buildRow('Net Payout Settled', currency.format(netAmount), cs, isHighlight: true),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Status: Settled to host wallet',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
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
                    'Statement #${b.id.substring(0, 8).toUpperCase()} downloaded (Export ready).',
                    style: GoogleFonts.manrope(),
                  ),
                  backgroundColor: AppColors.surfaceDark,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Download Statement'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, ColorScheme cs, {bool isNegative = false, bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: cs.onSurfaceVariant,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isHighlight
                ? AppColors.primary
                : (isNegative ? cs.error : cs.onSurface),
          ),
        ),
      ],
    );
  }
}

class HostSettingsScreen extends StatelessWidget {
  const HostSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Account', cs),
          ListTile(
            leading: Icon(Icons.person_outline, color: cs.primary),
            title: Text('Profile Details', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile'),
          ),
          ListTile(
            leading: Icon(Icons.account_balance_wallet_outlined, color: cs.primary),
            title: Text('Payout Methods', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/payment-methods'),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Preferences', cs),
          ListTile(
            leading: Icon(Icons.notifications_outlined, color: cs.primary),
            title: Text('Notifications', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notifications'),
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: cs.primary),
            title: Text('Privacy & Security', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy'),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Support & Legal', cs),
          ListTile(
            leading: Icon(Icons.help_outline, color: cs.primary),
            title: Text('Help & Support Desk', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/help-support'),
          ),
          ListTile(
            leading: Icon(Icons.chat_bubble_outline, color: cs.primary),
            title: Text('Live Support Chat', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/live-chat'),
          ),
          ListTile(
            leading: Icon(Icons.description_outlined, color: cs.primary),
            title: Text('Terms of Service', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/terms-of-service'),
          ),
          ListTile(
            leading: Icon(Icons.policy_outlined, color: cs.primary),
            title: Text('Privacy Policy', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy-policy'),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('host_settings_logout_button'),
              onPressed: () => AuthProvider.showLogoutDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.error,
                side: BorderSide(color: cs.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Log Out', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: cs.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
