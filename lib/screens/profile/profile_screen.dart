import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/theme/app_theme.dart';
import 'package:vnest_app/core/theme/theme_notifier.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _walletBalance = 2480.0;

  void _showWalletDialog(String title) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final amountController = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.sora(
                fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface,
              )),
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: cs.onSurface, fontSize: 24),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(color: cs.onSurface, fontSize: 24),
                  hintText: '0.00',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 24),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.outlineVariant)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    if (amount > 0) {
                      setState(() {
                        if (title == 'Top up Wallet') {
                          _walletBalance += amount;
                        } else if (title == 'Withdraw') {
                          if (_walletBalance >= amount) {
                            _walletBalance -= amount;
                          }
                        }
                      });
                    }
                    context.pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: Icon(Icons.arrow_back, color: cs.onSurface),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.push('/privacy'),
                        icon: Icon(Icons.settings, color: cs.onSurface),
                      ),
                      IconButton(
                        key: const Key('profile_logout_icon_button'),
                        tooltip: 'Log Out',
                        onPressed: () => AuthProvider.showLogoutDialog(context),
                        icon: Icon(Icons.logout, color: cs.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  children: [
                    // Avatar
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    // Wallet
                    _buildWalletCard(),
                    const SizedBox(height: 24),
                    // Impact stats
                    _buildImpactRow(),
                    const SizedBox(height: 24),
                    // Theme toggle
                    _buildThemeToggle(),
                    const SizedBox(height: 16),
                    // Settings list
                    _buildSettingsList(context),
                    const SizedBox(height: 24),
                    // Footer
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final cs = Theme.of(context).colorScheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Column(
      children: [
        // Avatar with glow ring
        Container(
          width: 100, height: 100,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
            )],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: Border.all(color: bgColor, width: 3),
            ),
            child: CircleAvatar(
              backgroundColor: cs.surface,
              child: Icon(Icons.person, color: cs.onSurfaceVariant, size: 40),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AuthProvider().currentUser?.name ?? 'Guest User', style: GoogleFonts.sora(
              fontSize: 26, fontWeight: FontWeight.w800,
              color: cs.onSurface, letterSpacing: -0.5,
            )),
            const SizedBox(width: 8),
            const Icon(Icons.verified, color: AppColors.primary, size: 20),
          ],
        ),
        if (AuthProvider().currentUser?.phone.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(
            AuthProvider().currentUser!.phone,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                AuthProvider().currentUser?.role.name.toUpperCase() ?? 'DRIVER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant, letterSpacing: 2,
                ),
              ),
            ),
            if (AuthProvider().isDemoMode ||
                AuthProvider().currentUser?.id.startsWith('demo_') == true) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'DEMO',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1CB864), Color(0xFF0A6634)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.2),
          blurRadius: 10,
        )],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('WALLET BALANCE', style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.8), letterSpacing: 1,
                  )),
                  Icon(Icons.account_balance_wallet, color: Colors.black.withValues(alpha: 0.8)),
                ],
              ),
              const SizedBox(height: 8),
              Text('₹${_walletBalance.toStringAsFixed(0)}', style: GoogleFonts.sora(
                fontSize: 56, fontWeight: FontWeight.w800,
                color: Colors.black, letterSpacing: -2,
              )),
              const SizedBox(height: 16),
              // Buttons
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _showWalletDialog('Top up Wallet'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Top up'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _showWalletDialog('Withdraw'),
                        icon: const Icon(Icons.arrow_downward, size: 18),
                        label: const Text('Withdraw'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildImpactRow() {
    final cs = Theme.of(context).colorScheme;

    final stats = [
      {'icon': Icons.bolt, 'value': '142', 'label': 'kWh Charged'},
      {'icon': Icons.eco, 'value': '41', 'label': 'kg CO₂ Saved'},
      {'icon': Icons.star, 'value': '4.9', 'label': 'Rating'},
    ];

    return Row(
      children: stats.asMap().entries.map((e) {
        final stat = e.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: e.key < 2 ? 12 : 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                Icon(stat['icon'] as IconData, color: AppColors.primary, size: 28),
                const SizedBox(height: 8),
                Text(stat['value'] as String, style: GoogleFonts.sora(
                  fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface,
                )),
                const SizedBox(height: 4),
                Text(stat['label'] as String, style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant, letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildThemeToggle() {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.surfaceContainerHighest,
                ),
                child: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: isDark ? AppColors.primary : AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text('Dark Mode', style: GoogleFonts.manrope(
                  fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface,
                )),
              ),
              Switch(
                value: isDark,
                onChanged: (_) => ThemeNotifier().toggle(),
                activeColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 450.ms).slideX(begin: 0.05);
  }

  Widget _buildSettingsList(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final settings = [
      {'icon': Icons.directions_car, 'label': 'My Vehicles', 'route': '/vehicles'},
      {'icon': Icons.favorite_border, 'label': 'Favorites', 'route': '/favorites'},
      {'icon': Icons.monitor_heart, 'label': 'Host Telemetry Dashboard', 'route': '/host-telemetry'},
      {'icon': Icons.history, 'label': 'Booking History', 'route': '/booking-history'},
      {'icon': Icons.credit_card, 'label': 'Payment Methods', 'route': '/payment-methods'},
      {'icon': Icons.notifications, 'label': 'Notifications', 'route': '/notifications'},
      {'icon': Icons.help, 'label': 'Help & Support', 'route': '/help-support'},
      {'icon': Icons.lock, 'label': 'Privacy', 'route': '/privacy'},
      {'icon': Icons.logout, 'label': 'Log Out', 'route': 'logout'},
    ];

    return Column(
      children: settings.asMap().entries.map((e) {
        final setting = e.value;
        final route = setting['route'] as String;
        final isLogout = route == 'logout';
        final isHighlighted = route == '/carplay' || route == '/host-telemetry';
        final highlightColor = route == '/host-telemetry' ? AppColors.warning : AppColors.primary;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isLogout
                ? cs.error.withValues(alpha: 0.08)
                : (isHighlighted ? highlightColor.withValues(alpha: 0.1) : cs.surfaceContainer),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                if (isLogout) {
                  AuthProvider.showLogoutDialog(context);
                } else if (route.isNotEmpty) {
                  context.push(route);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLogout
                        ? cs.error.withValues(alpha: 0.3)
                        : (isHighlighted ? highlightColor.withValues(alpha: 0.3) : cs.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLogout
                            ? cs.error.withValues(alpha: 0.15)
                            : (isHighlighted ? highlightColor : cs.surfaceContainerHighest),
                      ),
                      child: Icon(
                        setting['icon'] as IconData,
                        color: isLogout ? cs.error : (isHighlighted ? Colors.black : cs.onSurface),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        setting['label'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isLogout ? cs.error : cs.onSurface,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: isLogout ? cs.error : cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: (500 + e.key * 80).ms).slideX(begin: 0.05);
      }).toList(),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        TextButton(
          key: const Key('profile_footer_logout_button'),
          onPressed: () => AuthProvider.showLogoutDialog(context),
          child: Text('Sign out', style: GoogleFonts.manrope(
            color: cs.onSurfaceVariant, fontWeight: FontWeight.w500,
          )),
        ),
        const SizedBox(height: 8),
        Text('v0.9.2 · VOLTNEST', style: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant.withValues(alpha: 0.5), letterSpacing: 2,
        )),
      ],
    ).animate().fadeIn(delay: 1000.ms);
  }
}
