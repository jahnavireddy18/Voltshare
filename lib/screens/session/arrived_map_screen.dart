import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

import 'package:vnest_app/core/models/booking_model.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/services/session_service.dart';

class ArrivedMapScreen extends StatefulWidget {
  final BookingModel booking;
  const ArrivedMapScreen({super.key, required this.booking});

  @override
  State<ArrivedMapScreen> createState() => _ArrivedMapScreenState();
}

class _ArrivedMapScreenState extends State<ArrivedMapScreen> {
  int _seconds = 320; // 5:20
  bool _isUnlocked = false;
  bool _isLoading = false;
  late final BookingModel _booking;
  final _sessionService = SessionService();
  Timer? _timer;
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() => _currentPosition = LatLng(pos.latitude, pos.longitude));
      }
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position p) {
        if (mounted) {
          setState(() => _currentPosition = LatLng(p.latitude, p.longitude));
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '00:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Map area
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // Real map background with live location
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _currentPosition ?? const LatLng(18.5204, 73.8567),
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.voltshare.app',
                    ),
                    MarkerLayer(
                      markers: [
                        if (_currentPosition != null)
                          Marker(
                            point: _currentPosition!,
                            width: 24,
                            height: 24,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(color: Colors.blue.withValues(alpha: 0.5), blurRadius: 8),
                                ],
                              ),
                            ),
                          ),
                        // Charger destination marker
                        Marker(
                          point: const LatLng(18.5204, 73.8567), // Will use charger coords when available
                          width: 32,
                          height: 32,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryDark,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.ev_station, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Navigation header
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                      )],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.location_on, color: Color(0xFF004B1E)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Destination', style: GoogleFonts.plusJakartaSans(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: AppColors.textDarkSecondary,
                              )),
                              Text(_booking.chargerName, style: GoogleFonts.manrope(
                                fontSize: 18, fontWeight: FontWeight.w600,
                                color: AppColors.textDarkPrimary,
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.3),
                ),
              ],
            ),
          ),
          // Bottom sheet
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 40, offset: const Offset(0, -8),
              )],
              border: Border(top: BorderSide(color: AppColors.outlineVariant)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pull bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      // Arrived header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Arrived in', style: GoogleFonts.manrope(
                                fontSize: 24, fontWeight: FontWeight.w700,
                                color: AppColors.textDarkPrimary,
                              )),
                              Text('Your journey is complete', style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, color: AppColors.textDarkSecondary,
                              )),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_formattedTime, style: GoogleFonts.manrope(
                                fontSize: 22, fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              )),
                              Text('ELAPSED TIME', style: GoogleFonts.plusJakartaSans(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: AppColors.outline,
                              )),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Host profile
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.surfaceContainerLight,
                                  child: const Icon(Icons.person, color: AppColors.textDarkSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Host', style: GoogleFonts.manrope(
                                    fontSize: 18, fontWeight: FontWeight.w600,
                                    color: AppColors.textDarkPrimary,
                                  )),
                                  Text('Host ID: ${_booking.hostId.substring(0, 5).toUpperCase()}', style: GoogleFonts.manrope(
                                    fontSize: 13, color: cs.onSurfaceVariant,
                                  )),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.call),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.surfaceContainerLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.chat),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.surfaceContainerLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Payment summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.inverseSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.credit_card, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('•••• 7493', style: GoogleFonts.manrope(
                                      fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white,
                                    )),
                                    Text('Credit card', style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12, color: Colors.white.withValues(alpha: 0.7),
                                    )),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_booking.chargerName, style: GoogleFonts.sora(
                                  fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface,
                                )),
                                Text('Total Charge', style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.5),
                                )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Start session button
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: FilledButton(
                          onPressed: _isLoading ? null : () async {
                            if (!_isUnlocked) {
                              setState(() => _isUnlocked = true);
                              return;
                            }
                            
                            setState(() => _isLoading = true);
                            try {
                              final user = AuthProvider().currentUser;
                              if (user == null) throw Exception('User not logged in');

                              final session = await _sessionService.startSession(
                                bookingId: _booking.id,
                                userId: user.id,
                                chargerId: _booking.chargerId,
                              );

                              if (mounted) {
                                context.push('/active-session', extra: session);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString()), backgroundColor: cs.error),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_isUnlocked ? 'Plug In to Start' : 'Unlock Charger', style: GoogleFonts.manrope(
                            fontSize: 16, fontWeight: FontWeight.w700,
                          )),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
