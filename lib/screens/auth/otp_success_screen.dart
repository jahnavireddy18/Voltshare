import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class OtpSuccessScreen extends StatefulWidget {
  const OtpSuccessScreen({super.key});

  @override
  State<OtpSuccessScreen> createState() => _OtpSuccessScreenState();
}

class _OtpSuccessScreenState extends State<OtpSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late AnimationController _checkController;

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Sequence animations
    Future.delayed(const Duration(milliseconds: 300), () {
      _circleController.forward().then((_) {
        _checkController.forward();
      });
    });
  }

  @override
  void dispose() {
    _circleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      body: Stack(
        children: [
          // Blurred background
          Container(
            color: bgColor.withValues(alpha: 0.8),
          ),
          // Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated check circle
                    SizedBox(
                      width: 144,
                      height: 144,
                      child: CustomPaint(
                        painter: _SuccessPainter(
                          circleProgress: _circleController,
                          checkProgress: _checkController,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title
                    Text(
                      'Verified!',
                      style: GoogleFonts.sora(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 1300.ms, duration: 500.ms)
                        .slideY(begin: 0.3),
                    const SizedBox(height: 8),
                    Text(
                      'Successfully authenticated.',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 1500.ms, duration: 500.ms)
                        .slideY(begin: 0.3),
                    const SizedBox(height: 48),
                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => context.go('/role-selection'),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 1800.ms, duration: 500.ms)
                        .slideY(begin: 0.3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessPainter extends CustomPainter {
  final AnimationController circleProgress;
  final AnimationController checkProgress;

  _SuccessPainter({
    required this.circleProgress,
    required this.checkProgress,
  }) : super(
            repaint:
                Listenable.merge([circleProgress, checkProgress]));

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Glow effect
    if (circleProgress.value > 0) {
      final glowPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.3 * circleProgress.value)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(center, radius, glowPaint);
    }

    // Circle
    final circlePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * circleProgress.value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      circlePaint,
    );

    // Check mark
    if (checkProgress.value > 0) {
      final checkPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      final startX = size.width * 0.27;
      final startY = size.height * 0.52;
      final midX = size.width * 0.42;
      final midY = size.height * 0.65;
      final endX = size.width * 0.73;
      final endY = size.height * 0.35;

      if (checkProgress.value <= 0.5) {
        // First segment
        final t = checkProgress.value * 2;
        path.moveTo(startX, startY);
        path.lineTo(
          startX + (midX - startX) * t,
          startY + (midY - startY) * t,
        );
      } else {
        // Both segments
        path.moveTo(startX, startY);
        path.lineTo(midX, midY);
        final t = (checkProgress.value - 0.5) * 2;
        path.lineTo(
          midX + (endX - midX) * t,
          midY + (endY - midY) * t,
        );
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SuccessPainter oldDelegate) => true;
}
