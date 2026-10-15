import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class CarDashboardScreen extends StatefulWidget {
  const CarDashboardScreen({super.key});

  @override
  State<CarDashboardScreen> createState() => _CarDashboardScreenState();
}

class _CarDashboardScreenState extends State<CarDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Force Landscape for CarPlay Simulator
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Revert to Portrait when leaving simulator
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // True black for car displays
      body: OrientationBuilder(
        builder: (context, orientation) {
          Widget content = Row(
            children: [
              // Left Sidebar (Apps/Status)
              _buildSidebar(),
              // Main Content Area
              Expanded(
                child: Row(
                  children: [
                    // Navigation/Map Panel (60%)
                    Expanded(
                      flex: 6,
                      child: _buildMapPanel(),
                    ),
                    // Split border
                    Container(width: 2, color: AppColors.surfaceVariantDark),
                    // Widgets Panel (40%)
                    Expanded(
                      flex: 4,
                      child: _buildWidgetsPanel(),
                    ),
                  ],
                ),
              ),
            ],
          );

          // If system rotation didn't work (e.g. orientation locked), manually rotate UI
          if (orientation == Orientation.portrait) {
            return RotatedBox(
              quarterTurns: 1,
              child: content,
            );
          }
          
          return content;
        },
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 80,
      color: const Color(0xFF131313),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Time
          Text(
            '10:42',
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          // App Icons
          _buildSidebarIcon(Icons.bolt, AppColors.primary, isActive: true),
          const SizedBox(height: 24),
          _buildSidebarIcon(Icons.map, Colors.white),
          const SizedBox(height: 24),
          _buildSidebarIcon(Icons.music_note, Colors.white),
          const Spacer(),
          // Home/Exit Button
          IconButton(
            icon: const Icon(Icons.grid_view, color: Colors.white, size: 32),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarIcon(IconData icon, Color color, {bool isActive = false}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: color.withValues(alpha: 0.5)) : null,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildMapPanel() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
      ),
      child: Stack(
        children: [
          // Simulated Map
          CustomPaint(
            size: Size.infinite,
            painter: _CarMapPainter(),
          ),
          
          // Navigation Overlay (Top Left)
          Positioned(
            top: 24, left: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131313).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.turn_right, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('250 m', style: GoogleFonts.manrope(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white,
                      )),
                      Text('Turn right on Main St', style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, color: AppColors.textSecondary,
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

          // Chargers Nearby Overlay (Bottom Center)
          Positioned(
            bottom: 24, left: 24, right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChargerPill('Station A', '0.8km', '2 Available'),
                const SizedBox(width: 16),
                _buildChargerPill('Volt Hub', '1.2km', '1 Available'),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildChargerPill(String name, String dist, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131313).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$name • $dist', style: GoogleFonts.manrope(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white,
              )),
              Text(status, style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: AppColors.primary,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetsPanel() {
    return Container(
      color: const Color(0xFF131313),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Active Session Widget
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Active Session', style: GoogleFonts.manrope(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
                      )),
                      const Icon(Icons.ev_station, color: AppColors.primary),
                    ],
                  ),
                  const Spacer(),
                  Center(
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(text: '45', style: GoogleFonts.sora(
                          fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white,
                        )),
                        TextSpan(text: '%', style: GoogleFonts.manrope(
                          fontSize: 24, color: AppColors.primary,
                        )),
                      ]),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat('12.4 kWh', 'Delivered'),
                      _buildMiniStat('42m', 'Remaining'),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).scaleXY(begin: 0.9, end: 1.0),
          const SizedBox(height: 16),
          // Media Widget
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Midnight City', style: GoogleFonts.manrope(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white,
                        ), maxLines: 1),
                        Text('M83', style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, color: AppColors.textSecondary,
                        )),
                      ],
                    ),
                  ),
                  const Icon(Icons.skip_previous, color: Colors.white, size: 32),
                  const SizedBox(width: 8),
                  const Icon(Icons.pause_circle_filled, color: Colors.white, size: 40),
                  const SizedBox(width: 8),
                  const Icon(Icons.skip_next, color: Colors.white, size: 32),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String val, String lbl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: GoogleFonts.manrope(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
        )),
        Text(lbl, style: GoogleFonts.plusJakartaSans(
          fontSize: 12, color: AppColors.textSecondary,
        )),
      ],
    );
  }
}

class _CarMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF1E1E1E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final roadPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final routePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(size.width * 0.5, size.height);
    path.lineTo(size.width * 0.5, size.height * 0.6);
    path.lineTo(size.width * 0.8, size.height * 0.4);

    canvas.drawPath(path, roadPaint);
    canvas.drawPath(path, routePaint);

    // Car icon
    final carPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.8), 12, carPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
