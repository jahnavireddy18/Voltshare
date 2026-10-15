import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _dashController;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Find chargers\nnear you.',
      subtitle:
          'Locate available EV charging stations on the go. Smart filters help you find the perfect match.',
      icon: Icons.ev_station,
      secondaryIcon: Icons.search,
    ),
    OnboardingData(
      title: 'Your driveway,\ntheir lifeline.',
      subtitle:
          'Provide a reliable charging spot for fellow travelers. Your shared energy powers their journey forward.',
      icon: Icons.ev_station,
      secondaryIcon: Icons.home,
    ),
    OnboardingData(
      title: 'Charge smart,\nsave more.',
      subtitle:
          'Track your sessions, manage payments, and earn rewards — all from one premium app.',
      icon: Icons.bolt,
      secondaryIcon: Icons.savings,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _dashController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _dashController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemBuilder: (context, index) =>
                    _buildPage(_pages[index], index),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data, int index) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Illustration area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  children: [
                    // Abstract grid background
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GridPainter(isDark: isDark),
                      ),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              cs.surface.withValues(alpha: 0.9),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Animated path
                    Center(
                      child: AnimatedBuilder(
                        animation: _dashController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(280, 280),
                            painter: _DashPathPainter(
                              progress: _dashController.value,
                            ),
                          );
                        },
                      ),
                    ),
                    // Origin node
                    Positioned(
                      bottom: 50,
                      left: 40,
                      child: _buildNode(
                        data.secondaryIcon,
                        cs.onSurface,
                        false,
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
                    ),
                    // Destination node with pulsing
                    Positioned(
                      top: 50,
                      right: 40,
                      child: _buildNode(
                        data.icon,
                        AppColors.primary,
                        true,
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: -0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Text content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: GoogleFonts.sora(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  height: 1.2,
                ),
              )
                  .animate(key: ValueKey('title_$index'))
                  .fadeIn(duration: 500.ms)
                  .slideX(begin: -0.1),
              const SizedBox(height: 12),
              Text(
                data.subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              )
                  .animate(key: ValueKey('sub_$index'))
                  .fadeIn(duration: 500.ms, delay: 200.ms)
                  .slideX(begin: -0.1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNode(IconData icon, Color color, bool isPulsing) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isPulsing) ...[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                ),
              ).animate(onPlay: (c) => c.repeat()).custom(
                    duration: 2.seconds,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 1.0 + sin(value * pi * 2) * 0.15,
                        child: Opacity(
                          opacity: 0.3 + sin(value * pi * 2) * 0.2,
                          child: child,
                        ),
                      );
                    },
                  ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                ),
              ).animate(onPlay: (c) => c.repeat()).custom(
                    duration: 1500.ms,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 1.0 + sin(value * pi * 2) * 0.1,
                        child: child,
                      );
                    },
                  ),
            ],
            Container(
              width: isPulsing ? 56 : 48,
              height: isPulsing ? 56 : 48,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: isPulsing ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isPulsing ? null : BorderRadius.circular(16),
                border: Border.all(
                  color: isPulsing
                      ? color.withValues(alpha: 0.3)
                      : cs.onSurface.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: isPulsing ? 32 : 24),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentPage == index
                      ? AppColors.primary
                      : cs.outlineVariant,
                  boxShadow: _currentPage == index
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 8,
                          )
                        ]
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Skip',
                  style: GoogleFonts.manrope(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                    );
                  } else {
                    context.go('/login');
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentPage < _pages.length - 1
                          ? 'Next'
                          : 'Get Started',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;
  final IconData secondaryIcon;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.secondaryIcon,
  });
}

class _GridPainter extends CustomPainter {
  final bool isDark;
  _GridPainter({this.isDark = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashPathPainter extends CustomPainter {
  final double progress;

  _DashPathPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.85);
    path.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.3,
      size.width * 0.85,
      size.height * 0.15,
    );

    // Draw dashed path
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final length = metric.length;
      double distance = progress * 16; // Animate dash offset
      while (distance < length) {
        final start = distance;
        final end = (distance + 8).clamp(0.0, length);
        final extractPath = metric.extractPath(start, end);
        canvas.drawPath(extractPath, paint);
        distance += 16;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashPathPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
