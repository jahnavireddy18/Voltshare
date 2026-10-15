import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class TripStop {
  final String name;
  final String power;
  final String chargeTime;
  final String cost;
  final String distance;
  final int availableBays;
  final int totalBays;
  final List<String> plugs;
  final List<String> amenities;

  const TripStop({
    required this.name,
    required this.power,
    required this.chargeTime,
    required this.cost,
    required this.distance,
    required this.availableBays,
    required this.totalBays,
    required this.plugs,
    required this.amenities,
  });
}

class NavigationStep {
  final IconData icon;
  final String distance;
  final String instruction;
  final String subtitle;

  const NavigationStep({
    required this.icon,
    required this.distance,
    required this.instruction,
    required this.subtitle,
  });
}

class TripRouteData {
  final String destination;
  final String duration;
  final String distance;
  final int arrivalBattery;
  final List<TripStop> stops;
  final List<NavigationStep> steps;

  const TripRouteData({
    required this.destination,
    required this.duration,
    required this.distance,
    required this.arrivalBattery,
    required this.stops,
    required this.steps,
  });
}

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  final TextEditingController _startController =
      TextEditingController(text: 'Current Location');
  final TextEditingController _destController =
      TextEditingController(text: 'tirupati');
  final TextEditingController _batteryController =
      TextEditingController(text: '41');

  bool _isCalculating = false;
  bool _routePlanned = true; // Pre-plan for tirupati to match user state
  bool _isNavigating = false;
  int _currentStepIndex = 0;
  bool _isVoiceMuted = false;
  Timer? _navSimulationTimer;
  int _simulatedSpeed = 68;

  final List<String> _popularDestinations = [
    'Tirupati',
    'Bengaluru',
    'Mumbai',
    'Pune',
    'Hyderabad',
    'Goa',
  ];

  late TripRouteData _currentRoute;

  @override
  void initState() {
    super.initState();
    _currentRoute = _getRouteForDestination('tirupati');
  }

  @override
  void dispose() {
    _startController.dispose();
    _destController.dispose();
    _batteryController.dispose();
    _navSimulationTimer?.cancel();
    super.dispose();
  }

  TripRouteData _getRouteForDestination(String dest) {
    final lower = dest.toLowerCase().trim();
    if (lower.contains('tirupati')) {
      return const TripRouteData(
        destination: 'Tirupati',
        duration: '6h 45m',
        distance: '340 km',
        arrivalBattery: 15,
        stops: [
          TripStop(
            name: 'VoltCharge Fast Hub',
            power: '60 kW DC Fast',
            chargeTime: '25m',
            cost: '₹320 est.',
            distance: '140 km from start',
            availableBays: 3,
            totalBays: 4,
            plugs: ['CCS2 (60 kW)', 'Type 2 (22 kW)'],
            amenities: ['Coffee Lounge', 'Restrooms', '24/7 Security', 'Free Wi-Fi'],
          ),
          TripStop(
            name: 'GreenTech Station',
            power: '50 kW DC Fast',
            chargeTime: '15m',
            cost: '₹180 est.',
            distance: '260 km from start',
            availableBays: 2,
            totalBays: 2,
            plugs: ['CCS2 (50 kW)', 'GB/T Fast'],
            amenities: ['Diner / Cafe', 'EV Rest Stop', 'Convenience Store'],
          ),
        ],
        steps: [
          NavigationStep(
            icon: Icons.turn_right,
            distance: 'In 450 m',
            instruction: 'Turn right onto NH71 toward Tirupati',
            subtitle: 'Continue on NH71 for 38 km',
          ),
          NavigationStep(
            icon: Icons.straight,
            distance: 'In 38 km',
            instruction: 'Continue straight through Toll Plaza',
            subtitle: 'Keep left for fast EV lane',
          ),
          NavigationStep(
            icon: Icons.ev_station,
            distance: 'In 140 km',
            instruction: 'Approaching Stop 1: VoltCharge Fast Hub',
            subtitle: 'Reserved Bay #2 • 25 min charge',
          ),
          NavigationStep(
            icon: Icons.fork_right,
            distance: 'In 210 km',
            instruction: 'Keep right at the junction toward Renigunta Bypass',
            subtitle: 'Stay on State Highway 61',
          ),
          NavigationStep(
            icon: Icons.ev_station,
            distance: 'In 260 km',
            instruction: 'Approaching Stop 2: GreenTech Station',
            subtitle: 'Top-up charge 15 min',
          ),
          NavigationStep(
            icon: Icons.location_on,
            distance: 'In 340 km',
            instruction: 'Arrive at destination: Tirupati',
            subtitle: 'Estimated battery on arrival: 15%',
          ),
        ],
      );
    } else if (lower.contains('bangalore') || lower.contains('bengaluru')) {
      return const TripRouteData(
        destination: 'Bengaluru',
        duration: '5h 15m',
        distance: '280 km',
        arrivalBattery: 18,
        stops: [
          TripStop(
            name: 'Zeon Fast Charger',
            power: '120 kW Superfast',
            chargeTime: '20m',
            cost: '₹280 est.',
            distance: '120 km from start',
            availableBays: 4,
            totalBays: 6,
            plugs: ['Dual CCS2 (120 kW)', 'Type 2'],
            amenities: ['Highway Plaza', 'Food Court', 'Washrooms'],
          ),
          TripStop(
            name: 'Tata Power EZ Charge',
            power: '60 kW DC',
            chargeTime: '15m',
            cost: '₹210 est.',
            distance: '210 km from start',
            availableBays: 2,
            totalBays: 4,
            plugs: ['CCS2 (60 kW)'],
            amenities: ['Restaurant', 'Coffee Bar'],
          ),
        ],
        steps: [
          NavigationStep(
            icon: Icons.merge,
            distance: 'In 1.2 km',
            instruction: 'Merge onto National Highway 44 toward Bengaluru',
            subtitle: 'Speed limit 90 km/h',
          ),
          NavigationStep(
            icon: Icons.ev_station,
            distance: 'In 120 km',
            instruction: 'Stop 1: Zeon Fast Charger Oasis',
            subtitle: 'Charge 20 mins to 80%',
          ),
          NavigationStep(
            icon: Icons.straight,
            distance: 'In 280 km',
            instruction: 'Arrive in Electronic City, Bengaluru',
            subtitle: 'Battery remaining: 18%',
          ),
        ],
      );
    } else if (lower.contains('mumbai')) {
      return const TripRouteData(
        destination: 'Mumbai',
        duration: '3h 10m',
        distance: '150 km',
        arrivalBattery: 28,
        stops: [
          TripStop(
            name: 'Expressway Supercharge Oasis',
            power: '150 kW Ultra-Fast',
            chargeTime: '20m',
            cost: '₹260 est.',
            distance: '75 km from start',
            availableBays: 6,
            totalBays: 8,
            plugs: ['CCS2 150 kW', 'Type 2 22 kW'],
            amenities: ['Food Mall', 'Starbucks', '24/7 Restrooms'],
          ),
        ],
        steps: [
          NavigationStep(
            icon: Icons.turn_right,
            distance: 'In 800 m',
            instruction: 'Take ramp onto Mumbai-Pune Expressway',
            subtitle: 'Fast corridor toll lane',
          ),
          NavigationStep(
            icon: Icons.ev_station,
            distance: 'In 75 km',
            instruction: 'Stop 1: Expressway Supercharge Oasis',
            subtitle: 'Quick 20 min top-up',
          ),
          NavigationStep(
            icon: Icons.location_on,
            distance: 'In 150 km',
            instruction: 'Arrive at Mumbai Destination',
            subtitle: 'Estimated battery on arrival: 28%',
          ),
        ],
      );
    } else {
      // Default customized route
      return TripRouteData(
        destination: dest.isEmpty ? 'Destination' : dest,
        duration: '4h 30m',
        distance: '240 km',
        arrivalBattery: 20,
        stops: const [
          TripStop(
            name: 'VoltShare Highway Corridor Hub',
            power: '60 kW Fast DC',
            chargeTime: '25m',
            cost: '₹290 est.',
            distance: '110 km from start',
            availableBays: 3,
            totalBays: 4,
            plugs: ['CCS2', 'Type 2'],
            amenities: ['Restrooms', 'Cafe', '24/7 Security'],
          ),
        ],
        steps: [
          const NavigationStep(
            icon: Icons.turn_right,
            distance: 'In 600 m',
            instruction: 'Head toward Highway connector',
            subtitle: 'Follow signs for National Highway',
          ),
          const NavigationStep(
            icon: Icons.ev_station,
            distance: 'In 110 km',
            instruction: 'Charging Stop: VoltShare Highway Hub',
            subtitle: 'Recommended charge: 25 mins',
          ),
          NavigationStep(
            icon: Icons.location_on,
            distance: 'In 240 km',
            instruction: 'Arrive at $dest',
            subtitle: 'Estimated battery: 20%',
          ),
        ],
      );
    }
  }

  void _calculateRoute() {
    final dest = _destController.text.trim();
    if (dest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a destination city or station.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
      _routePlanned = false;
      _isNavigating = false;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _currentRoute = _getRouteForDestination(dest);
          _isCalculating = false;
          _routePlanned = true;
        });
      }
    });
  }

  void _startNavigation() {
    setState(() {
      _isNavigating = true;
      _currentStepIndex = 0;
    });

    // Start a gentle speed simulation for alive feedback
    _navSimulationTimer?.cancel();
    _navSimulationTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _isNavigating) {
        setState(() {
          _simulatedSpeed = 65 + (_simulatedSpeed % 7);
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.navigation, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Live navigation started toward ${_currentRoute.destination}!',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _stopNavigation() {
    _navSimulationTimer?.cancel();
    setState(() {
      _isNavigating = false;
    });
  }

  void _showStopDetails(TripStop stop) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.name,
                          style: GoogleFonts.sora(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${stop.distance} • ${stop.power}',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Estimated Charge',
                            style: GoogleFonts.manrope(fontSize: 11, color: cs.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(stop.chargeTime,
                            style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(width: 1, height: 30, color: cs.outlineVariant),
                    Column(
                      children: [
                        Text('Cost Estimate',
                            style: GoogleFonts.manrope(fontSize: 11, color: cs.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(stop.cost,
                            style: GoogleFonts.sora(
                                fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    Container(width: 1, height: 30, color: cs.outlineVariant),
                    Column(
                      children: [
                        Text('Bay Availability',
                            style: GoogleFonts.manrope(fontSize: 11, color: cs.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('${stop.availableBays}/${stop.totalBays} Open',
                            style: GoogleFonts.sora(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Available Connectors',
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: stop.plugs.map((p) {
                  return Chip(
                    label: Text(p, style: GoogleFonts.jetBrainsMono(fontSize: 11)),
                    backgroundColor: cs.surfaceContainerHighest,
                    side: BorderSide(color: cs.outlineVariant),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text('Station Amenities',
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: stop.amenities.map((a) {
                  return Chip(
                    avatar: const Icon(Icons.check, size: 14, color: AppColors.primary),
                    label: Text(a, style: GoogleFonts.manrope(fontSize: 11)),
                    backgroundColor: cs.surfaceContainerHighest,
                    side: BorderSide(color: cs.outlineVariant),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Charging Bay Pre-Reserved at ${stop.name}!'),
                        backgroundColor: AppColors.surfaceDark,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.bolt),
                  label: const Text('Pre-Reserve Charging Bay'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllTurnsSheet() {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Turn-by-Turn Route Itinerary',
                    style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _currentRoute.steps.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final step = _currentRoute.steps[index];
                    final isCurrent = index == _currentStepIndex;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primary
                              : cs.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          step.icon,
                          color: isCurrent ? Colors.black : cs.onSurface,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        step.instruction,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          color: isCurrent ? AppColors.primary : cs.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '${step.distance} • ${step.subtitle}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      onTap: () {
                        setState(() => _currentStepIndex = index);
                        Navigator.of(sheetCtx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Simulated Map Background with active road line
          Positioned.fill(
            child: CustomPaint(
              painter: _TripMapPainter(
                showRoute: _routePlanned || _isNavigating,
                isDark: isDark,
                isNavigating: _isNavigating,
                stepProgress: _currentStepIndex /
                    (_currentRoute.steps.isEmpty ? 1 : _currentRoute.steps.length),
              ),
            ),
          ),

          // If NOT navigating: Show Planner Card
          if (!_isNavigating)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildPlannerCard(),
                ),
              ),
            ),

          // If NOT navigating AND route planned: Show Results Card
          if (!_isNavigating && _routePlanned)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), // Above bottom nav
                child: _buildRouteResults(),
              ),
            ),

          // If NAVIGATING: Show Live Navigation HUD
          if (_isNavigating) ...[
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildActiveNavigationTopBanner(),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                child: _buildActiveNavigationBottomHUD(),
              ),
            ),
          ],

          // Loading Overlay
          if (_isCalculating)
            Container(
              color: cs.surface.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'VoltShare Smart Routing Engine\nCalculating optimal charging corridor...',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ).animate().fadeIn().shimmer(duration: 1500.ms),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.warning, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _destController,
                    style: GoogleFonts.manrope(
                        color: cs.onSurface, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Where to? (e.g. Tirupati)',
                      hintStyle: GoogleFonts.manrope(color: cs.onSurfaceVariant),
                    ),
                    onSubmitted: (_) => _calculateRoute(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Quick Destination Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _popularDestinations.map((city) {
                final isSelected =
                    _destController.text.trim().toLowerCase() == city.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ActionChip(
                    label: Text(city,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.black : cs.onSurface,
                        )),
                    backgroundColor: isSelected
                        ? AppColors.primary
                        : cs.surfaceContainerHighest,
                    side: BorderSide(
                        color: isSelected ? AppColors.primary : cs.outlineVariant),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () {
                      _destController.text = city;
                      _calculateRoute();
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // Current Battery & Plan Button
          Row(
            children: [
              Text('Current Battery: ',
                  style: GoogleFonts.manrope(color: cs.onSurfaceVariant)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 65,
                child: TextField(
                  controller: _batteryController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                ),
                child: Text('Plan Trip',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: -0.2).fadeIn();
  }

  Widget _buildRouteResults() {
    final cs = Theme.of(context).colorScheme;

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
                  Text(
                    'Optimal Route Found',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    'Arrival with ${_currentRoute.arrivalBattery}% battery',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
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
                    Text(
                      _currentRoute.duration,
                      style: GoogleFonts.sora(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      _currentRoute.distance,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Charging stops timeline (Interactive: taps open stop details!)
          ..._currentRoute.stops.asMap().entries.map((entry) {
            final index = entry.key;
            final stop = entry.value;
            final isLast = index == _currentRoute.stops.length - 1;

            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showStopDetails(stop),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Icon(
                              index == 0 ? Icons.bolt : Icons.ev_station,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stop.name,
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Charge for ${stop.chargeTime} • ${stop.cost}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.info_outline,
                              size: 16, color: cs.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                          width: 2, height: 16, color: cs.outlineVariant),
                    ),
                  ),
              ],
            );
          }),

          const SizedBox(height: 20),

          // Start Navigation Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _startNavigation,
              icon: const Icon(Icons.navigation_rounded, size: 20),
              label: Text(
                'Start Navigation',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2).fadeIn();
  }

  Widget _buildActiveNavigationTopBanner() {
    final cs = Theme.of(context).colorScheme;
    final currentStep = _currentRoute.steps.isNotEmpty
        ? _currentRoute.steps[_currentStepIndex]
        : const NavigationStep(
            icon: Icons.navigation,
            distance: 'Ahead',
            instruction: 'Follow route guidance',
            subtitle: 'En route',
          );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131A15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
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
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  currentStep.icon,
                  color: Colors.black,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStep.distance,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      currentStep.instruction,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentStep.subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'All Turns',
                icon: const Icon(Icons.list_alt, color: Colors.white70),
                onPressed: _showAllTurnsSheet,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Step navigation progress pills
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: (_currentStepIndex + 1) /
                        (_currentRoute.steps.isEmpty ? 1 : _currentRoute.steps.length),
                    backgroundColor: Colors.white12,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  if (_currentStepIndex < _currentRoute.steps.length - 1) {
                    setState(() => _currentStepIndex++);
                  }
                },
                child: Text(
                  'Next Turn >',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildActiveNavigationBottomHUD() {
    final cs = Theme.of(context).colorScheme;
    final firstStop = _currentRoute.stops.isNotEmpty ? _currentRoute.stops.first : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainer.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live Driving Telemetry Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('SPEED',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(
                    '$_simulatedSpeed',
                    style: GoogleFonts.sora(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  Text('km/h',
                      style: GoogleFonts.manrope(
                          fontSize: 10, color: cs.onSurfaceVariant)),
                ],
              ),
              Container(width: 1, height: 36, color: cs.outlineVariant),
              Column(
                children: [
                  Text('REMAINING',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(
                    _currentRoute.distance,
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(_currentRoute.duration,
                      style: GoogleFonts.manrope(
                          fontSize: 10, color: cs.onSurfaceVariant)),
                ],
              ),
              Container(width: 1, height: 36, color: cs.outlineVariant),
              Column(
                children: [
                  Text('ARRIVAL BATT',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.battery_charging_full,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 2),
                      Text(
                        '${_currentRoute.arrivalBattery}%',
                        style: GoogleFonts.sora(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Text('Safe margin',
                      style: GoogleFonts.manrope(
                          fontSize: 10, color: Colors.green)),
                ],
              ),
            ],
          ),

          if (firstStop != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  const Icon(Icons.ev_station, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Stop: ${firstStop.name}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          '${firstStop.distance} • ${firstStop.availableBays} bays open',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showStopDetails(firstStop),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      'Pre-Book',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Control row: Audio Toggle + Exit Navigation
          Row(
            children: [
              IconButton.filledTonal(
                icon: Icon(
                  _isVoiceMuted ? Icons.volume_off : Icons.volume_up,
                  size: 20,
                ),
                tooltip: _isVoiceMuted ? 'Unmute Guidance' : 'Mute Guidance',
                onPressed: () {
                  setState(() => _isVoiceMuted = !_isVoiceMuted);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isVoiceMuted
                          ? 'Navigation audio voice muted.'
                          : 'Navigation audio voice guidance enabled.'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _stopNavigation,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Exit Navigation'),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }
}

class _TripMapPainter extends CustomPainter {
  final bool showRoute;
  final bool isDark;
  final bool isNavigating;
  final double stepProgress;

  _TripMapPainter({
    required this.showRoute,
    required this.isDark,
    this.isNavigating = false,
    this.stepProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 36) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 36) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    if (showRoute) {
      // Draw simulated route line
      final routePaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = isNavigating ? 6 : 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final glowPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: isNavigating ? 0.45 : 0.25)
        ..strokeWidth = isNavigating ? 16 : 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      final path = Path();
      final start = Offset(size.width * 0.25, size.height * 0.28);
      final c1 = Offset(size.width * 0.12, size.height * 0.48);
      final p1 = Offset(size.width * 0.42, size.height * 0.54);
      final c2 = Offset(size.width * 0.85, size.height * 0.62);
      final end = Offset(size.width * 0.72, size.height * 0.82);

      path.moveTo(start.dx, start.dy);
      path.quadraticBezierTo(c1.dx, c1.dy, p1.dx, p1.dy);
      path.quadraticBezierTo(c2.dx, c2.dy, end.dx, end.dy);

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, routePaint);

      // Draw stops
      final stopPaint = Paint()..color = (isDark ? Colors.white : Colors.black);
      final borderPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final stops = [
        start,
        Offset(size.width * 0.32, size.height * 0.51), // Charge 1
        Offset(size.width * 0.60, size.height * 0.59), // Charge 2
        end,
      ];

      for (int i = 0; i < stops.length; i++) {
        final stop = stops[i];
        final isEnd = i == stops.length - 1;
        final isStation = i == 1 || i == 2;

        canvas.drawCircle(stop, isEnd ? 10 : 8, isStation ? Paint()..color = AppColors.primary : stopPaint);
        canvas.drawCircle(stop, isEnd ? 10 : 8, borderPaint);
      }

      // If actively navigating, draw pulsing vehicle puck along the route
      if (isNavigating) {
        final puckPos = Offset(
          start.dx + (end.dx - start.dx) * (0.2 + stepProgress * 0.6),
          start.dy + (end.dy - start.dy) * (0.2 + stepProgress * 0.6),
        );

        final puckHalo = Paint()
          ..color = AppColors.primary.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(puckPos, 18, puckHalo);

        final puckPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(puckPos, 9, puckPaint);

        final puckRing = Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(puckPos, 9, puckRing);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TripMapPainter oldDelegate) =>
      showRoute != oldDelegate.showRoute ||
      isDark != oldDelegate.isDark ||
      isNavigating != oldDelegate.isNavigating ||
      stepProgress != oldDelegate.stepProgress;
}
