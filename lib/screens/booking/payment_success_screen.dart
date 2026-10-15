import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Grid background
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => context.go('/home'),
                        icon: Icon(Icons.close, color: AppColors.primaryDark),
                      ),
                      Text('VoltCharge', style: GoogleFonts.manrope(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      )),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.surfaceContainerLight,
                        child: const Icon(Icons.person, color: AppColors.textDarkSecondary),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        // Success animation
                        _buildSuccessIcon(),
                        const SizedBox(height: 24),
                        Text('Payment successful', style: GoogleFonts.manrope(
                          fontSize: 24, fontWeight: FontWeight.w700,
                          color: AppColors.textDarkPrimary,
                        )).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            text: 'Successfully paid ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, color: AppColors.textDarkSecondary,
                            ),
                            children: [
                              TextSpan(
                                text: '₹150.50',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 800.ms),
                        const SizedBox(height: 32),
                        // Receipt card
                        _buildReceiptCard(),
                        const SizedBox(height: 24),
                        // Action buttons
                        _buildActionButtons(context),
                        const SizedBox(height: 32),
                        // Promo card
                        _buildPromoCard(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryContainer.withValues(alpha: 0.2),
          ),
        ).animate().scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryContainer,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
                blurRadius: 40, spreadRadius: 10,
              ),
            ],
          ),
          child: const Icon(Icons.check_circle, size: 48, color: Color(0xFF004B1E)),
        ).animate().scale(begin: const Offset(0, 0), delay: 200.ms, duration: 500.ms, curve: Curves.elasticOut),
      ],
    );
  }

  Widget _buildReceiptCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PAYMENT DETAILS', style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textDarkPrimary, letterSpacing: 0.7,
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 14, color: AppColors.primaryDark),
                    const SizedBox(width: 4),
                    Text('COMPLETED', style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryDark,
                    )),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: AppColors.outlineVariant, height: 32),
          _receiptRow('Transaction ID', 'VN-4352-2748-3920'),
          _receiptRow('Date', '1 September 2026'),
          _receiptRow('Type', 'Volt Wallet'),
          _receiptRow('Nominal', '₹150.45'),
          _receiptRow('Admin Fee', '₹0.05'),
          // Dashed divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              children: List.generate(40, (i) => Expanded(
                child: Container(
                  height: 1,
                  color: i.isEven ? AppColors.outlineVariant : Colors.transparent,
                ),
              )),
            ),
          ),
          // Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inverseSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL', style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7), letterSpacing: 0.7,
                )),
                Text('₹150.50', style: GoogleFonts.manrope(
                  fontSize: 18, fontWeight: FontWeight.w600,
                  color: const Color(0xFF6BFF8F),
                )),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 14, color: AppColors.textDarkSecondary,
          )),
          Text(value, style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: AppColors.textDarkPrimary,
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Invoice downloaded to your device.'),
                    backgroundColor: AppColors.primaryDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.download, size: 20),
              label: const Text('Invoice'),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerLight,
                foregroundColor: AppColors.textDarkPrimary,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: () => context.push('/booking-success'),
              icon: const Icon(Icons.share, size: 20),
              label: const Text('Continue'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildPromoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.electric_bolt, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Earned 15 Volt Points', style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.warning,
                )),
                Text("You're halfway to your next free charging session!",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: AppColors.textDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1);
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += 30) {
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
