import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  final TextEditingController _startController = TextEditingController(text: 'Current Location');
  final TextEditingController _destController = TextEditingController();
  final TextEditingController _batteryController = TextEditingController(text: '45');
  
  bool _isCalculating = false;
  bool _routePlanned = false;

  void _calculateRoute() {
    if (_destController.text.isEmpty) return;
    
    setState(() {
      _isCalculating = true;
      _routePlanned = false;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCalculating = false;
          _routePlanned = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Simulated Map Background
          Positioned.fill(
            child: CustomPaint(
              painter: _TripMapPainter(showRoute: _routePlanned, isDark: isDark),
            ),
          ),
          
          // Top Search overlay
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildPlannerCard(),
              ),
            ),
          ),

          // Bottom Results (if planned)
          if (_routePlanned)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), // Above nav bar
                child: _buildRouteResults(),
              ),
            ),
            
          // Loading Overlay
          if (_isCalculating)
            Container(
              color: cs.surface.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'VoltNest AI analyzing topography\nand charger availability...',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(color: cs.onSurface, fontWeight: FontWeight.w600),
                    ).animate().fadeIn().shimmer(duration: 2000.ms),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlannerCard() {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'SMART ROUTING',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Start Location
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.my_location, color: cs.onSurfaceVariant, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _startController,
                    style: GoogleFonts.manrope(color: cs.onSurface),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Start location',
                      hintStyle: GoogleFonts.manrope(color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Destination
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.warning, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _destController,
                    style: GoogleFonts.manrope(color: cs.onSurface),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Where to?',
                      hintStyle: GoogleFonts.manrope(color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Current Battery
          Row(
            children: [
              Text('Current Battery: ', style: GoogleFonts.manrope(color: cs.onSurfaceVariant)),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _batteryController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.manrope(color: AppColors.primary, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    suffixText: '%',
                    suffixStyle: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _calculateRoute,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                child: Text('Plan Trip', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: -0.2).fadeIn();
  }

  Widget _buildRouteResults() {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Optimal Route Found', style: GoogleFonts.manrope(
                    fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface,
                  )),
                  Text('Arrival with 15% battery', style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: cs.onSurfaceVariant,
                  )),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('6h 45m', style: GoogleFonts.sora(
                      fontWeight: FontWeight.w700, color: AppColors.primary,
                    )),
                    Text('340 km', style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, color: cs.onSurfaceVariant,
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Stops timeline
          _buildTimelineStop(Icons.bolt, 'VoltCharge Fast Hub', 'Charge for 25m • ₹320 est.', AppColors.primary),
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Container(width: 2, height: 20, color: cs.outlineVariant),
          ),
          _buildTimelineStop(Icons.ev_station, 'GreenTech Station', 'Charge for 15m • ₹180 est.', AppColors.primary),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Starting Trip Navigation...'),
                    backgroundColor: cs.inverseSurface,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.navigation),
              label: Text('Start Navigation', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2).fadeIn();
  }

  Widget _buildTimelineStop(IconData icon, String title, String subtitle, Color iconColor) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600, color: cs.onSurface, fontSize: 14,
            )),
            Text(subtitle, style: GoogleFonts.plusJakartaSans(
              color: cs.onSurfaceVariant, fontSize: 12,
            )),
          ],
        ),
      ],
    );
  }
}

class _TripMapPainter extends CustomPainter {
  final bool showRoute;
  final bool isDark;
  _TripMapPainter({required this.showRoute, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03)
      ..strokeWidth = 1;
      
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    if (showRoute) {
      // Draw simulated route line
      final routePaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
        
      final glowPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.3)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final path = Path();
      path.moveTo(size.width * 0.2, size.height * 0.3); // Start
      path.quadraticBezierTo(size.width * 0.1, size.height * 0.5, size.width * 0.4, size.height * 0.55);
      path.quadraticBezierTo(size.width * 0.8, size.height * 0.6, size.width * 0.7, size.height * 0.8); // End

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, routePaint);
      
      // Draw stops
      final stopPaint = Paint()..color = (isDark ? Colors.white : Colors.black);
      final borderPaint = Paint()..color = AppColors.primary..style = PaintingStyle.stroke..strokeWidth = 3;
      
      final stops = [
        Offset(size.width * 0.2, size.height * 0.3), // Start
        Offset(size.width * 0.3, size.height * 0.52), // Charge 1
        Offset(size.width * 0.58, size.height * 0.57), // Charge 2
        Offset(size.width * 0.7, size.height * 0.8), // End
      ];
      
      for (var stop in stops) {
        canvas.drawCircle(stop, 8, stopPaint);
        canvas.drawCircle(stop, 8, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TripMapPainter oldDelegate) => 
      showRoute != oldDelegate.showRoute || isDark != oldDelegate.isDark;
}
