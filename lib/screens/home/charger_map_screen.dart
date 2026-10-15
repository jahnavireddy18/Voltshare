import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/models/charger_model.dart';
import 'package:vnest_app/core/services/charger_service.dart';
import 'package:vnest_app/widgets/common/vs_components.dart';

class ChargerMapScreen extends StatefulWidget {
  const ChargerMapScreen({super.key});

  @override
  State<ChargerMapScreen> createState() => _ChargerMapScreenState();
}

class _ChargerMapScreenState extends State<ChargerMapScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController(text: 'Current Location');
  int _selectedFilter = 0;
  final List<String> _filters = ['7kW+', 'Type-2', 'Available', 'Free Parking'];

  LatLng? _currentPosition;
  List<ChargerModel> _chargers = [];
  ChargerModel? _selectedCharger;
  bool _isLoading = true;
  bool _isListView = false;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _fetchChargers();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchChargers() async {
    setState(() => _isLoading = true);
    try {
      double? minPower;
      ConnectorType? cType;
      if (_selectedFilter == 0) minPower = 7.0;
      if (_selectedFilter == 1) cType = ConnectorType.type2;

      final chargers = await ChargerService().searchChargers(
        minPowerOutput: minPower,
        connectorType: cType,
      );
      setState(() {
        _chargers = chargers;
        _isLoading = false;
        if (_chargers.isNotEmpty) {
          _selectedCharger = _chargers.first;
        } else {
          _selectedCharger = null;
        }
      });
    } catch (e) {
      debugPrint('Error fetching chargers: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return;
    } 

    try {
      // Get initial position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Start live location stream for real-time updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position pos) {
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(pos.latitude, pos.longitude);
          });
        }
      });
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Map or List view
          Positioned.fill(
            child: _isListView ? _buildListView() : _buildFlutterMap(),
          ),
          // Top app bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),
          // Search and filters
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 16,
            right: 16,
            child: _buildSearchAndFilters(),
          ),
          // Filter FAB
          Positioned(
            bottom: (_selectedCharger != null && !_isListView) ? 210 : 24,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildListViewToggleFab(),
                const SizedBox(width: 16),
                _buildFilterFab(),
              ],
            ),
          ),
          // Bottom charger card
          if (_selectedCharger != null && !_isListView)
            Positioned(
              bottom: 8,
              left: 16,
              right: 16,
              child: _buildChargerCard(_selectedCharger!),
            ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 140,
        bottom: 100,
        left: 16,
        right: 16,
      ),
      itemCount: _chargers.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildChargerCard(_chargers[index], isListMode: true),
        );
      },
    );
  }

  Widget _buildFlutterMap() {
    final center = _currentPosition ?? const LatLng(18.5204, 73.8567);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.voltshare.app',
        ),
        // Dark overlay for dark theme
        if (context.isDark)
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              -1, 0, 0, 0, 255,
              0, -1, 0, 0, 255,
              0, 0, -1, 0, 255,
              0, 0, 0, 1, 0,
            ]),
            child: TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.voltshare.app',
            ),
          ),
        MarkerLayer(
          markers: [
            if (_currentPosition != null)
              Marker(
                point: _currentPosition!,
                width: 24,
                height: 24,
                child: _buildPulsingPin(false, isCurrentLocation: true),
              ),
            ..._chargers.map((charger) {
              final isSelected = _selectedCharger?.id == charger.id;
              return Marker(
                point: LatLng(charger.latitude, charger.longitude),
                width: isSelected ? 32 : 24,
                height: isSelected ? 32 : 24,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCharger = charger),
                  child: _buildPulsingPin(isSelected),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildPulsingPin(bool isActive, {bool isCurrentLocation = false}) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    if (isCurrentLocation) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.blue.withValues(alpha: 0.5), blurRadius: 8),
          ],
        ),
      );
    }

    if (!isActive) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.surfaceContainerHighest,
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.2)),
        ),
      );
    }
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 0.8, end: 1.3, duration: 1500.ms)
              .fadeOut(begin: 0.6, duration: 1500.ms),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              border: Border.all(
                  color: isDark ? const Color(0xFF131313) : Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.8),
        border: Border(
          bottom:
              BorderSide(color: cs.onSurface.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.near_me, color: cs.onSurface, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '70/549',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  Icon(Icons.expand_more,
                      color: cs.onSurfaceVariant, size: 20),
                ],
              ),
              Text(
                'Maharshi Nagar, Pune, Maharashtra, India',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: cs.onSurface),
                tooltip: 'Help & Legal',
                color: cs.surfaceContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (value) {
                  if (value == 'help') context.push('/help-support');
                  if (value == 'terms') context.push('/terms-of-service');
                  if (value == 'privacy') context.push('/privacy-policy');
                  if (value == 'chat') context.push('/live-chat');
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'help',
                    child: Row(
                      children: [
                        const Icon(Icons.help_outline, size: 20),
                        const SizedBox(width: 12),
                        Text('Help & Support', style: GoogleFonts.manrope(fontSize: 14)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'chat',
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 20),
                        const SizedBox(width: 12),
                        Text('Live Chat', style: GoogleFonts.manrope(fontSize: 14)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'terms',
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text('Terms of Service', style: GoogleFonts.manrope(fontSize: 14)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'privacy',
                    child: Row(
                      children: [
                        const Icon(Icons.privacy_tip_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text('Privacy Policy', style: GoogleFonts.manrope(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.onSurface,
                  ),
                  child: Icon(Icons.person, color: cs.surface),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.3);
  }

  Widget _buildSearchAndFilters() {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Search bar
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: cs.surfaceContainer.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.search,
                  color: cs.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style:
                      GoogleFonts.plusJakartaSans(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search destination or charger ID',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        color: cs.onSurface.withValues(alpha: 0.5)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.onSurface.withValues(alpha: 0.1),
                ),
                child: GestureDetector(
                  onTap: () {
                    if (_currentPosition != null) {
                      _mapController.move(_currentPosition!, 15.0);
                    }
                  },
                  child: const Icon(Icons.my_location,
                      color: AppColors.primary, size: 16),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2),
        const SizedBox(height: 8),
        // Filter chips
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = _selectedFilter == index;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedFilter = index);
                  _fetchChargers();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : cs.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index == 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.bolt,
                              size: 16,
                              color: isSelected
                                  ? AppColors.primary
                                  : cs.onSurfaceVariant),
                        ),
                      if (index == 2)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.check_circle,
                              size: 16, color: AppColors.primary),
                        ),
                      Text(
                        _filters[index],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildFilterFab() {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.surfaceContainer,
        border:
            Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Icon(Icons.tune, color: cs.onSurface),
    ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.5, 0.5));
  }

  Widget _buildListViewToggleFab() {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    return GestureDetector(
      onTap: () => setState(() => _isListView = !_isListView),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(_isListView ? Icons.map : Icons.list, color: Colors.black),
      ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.5, 0.5)),
    );
  }

  Widget _buildChargerCard(ChargerModel charger, {bool isListMode = false}) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    // Calculate distance if location available
    String distanceStr = '';
    if (_currentPosition != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        charger.latitude,
        charger.longitude,
      );
      if (distanceInMeters < 1000) {
        distanceStr = '${distanceInMeters.toStringAsFixed(0)}m away';
      } else {
        distanceStr = '${(distanceInMeters / 1000).toStringAsFixed(1)}km away';
      }
    }

    return GestureDetector(
      onTap: () => context.push('/charger-details', extra: charger.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Available badge
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat())
                              .fadeIn()
                              .then()
                              .fadeOut()
                              .then()
                              .fadeIn(),
                          const SizedBox(width: 6),
                          Text(
                            charger.status == ChargerListingStatus.active 
                                ? 'AVAILABLE NOW' 
                                : charger.status.label.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: charger.status == ChargerListingStatus.active 
                                  ? AppColors.primary 
                                  : cs.error,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        charger.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.straighten,
                              size: 16,
                              color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            distanceStr.isNotEmpty ? distanceStr : charger.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: cs.onSurface.withValues(alpha: 0.05),
                    border: Border.all(
                        color:
                            cs.onSurface.withValues(alpha: 0.1)),
                  ),
                  child: Icon(Icons.ev_station,
                      color: cs.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: cs.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Charging Rate',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                        children: [
                          const TextSpan(text: '₹'),
                          TextSpan(text: charger.pricePerKwh.toStringAsFixed(1)),
                          TextSpan(
                            text: '/kWh',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => context.push('/charger-details', extra: charger.id),
                  icon: const Icon(Icons.bolt, size: 20),
                  label: Text(
                    'Start Nav',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3);
  }
}
