import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {'title': 'Charging Completed', 'desc': 'Your vehicle has reached 80% charge at Station A.', 'time': '10 min ago', 'icon': Icons.battery_charging_full, 'isUnread': true},
    {'title': 'Promotion', 'desc': 'Get 20% off on your next charge at Volt Hub!', 'time': '2 hours ago', 'icon': Icons.local_offer, 'isUnread': true},
    {'title': 'Receipt', 'desc': 'Your payment of ₹450 was successful.', 'time': '1 day ago', 'icon': Icons.receipt, 'isUnread': false},
  ];

  void _markAllRead() {
    setState(() {
      for (var notif in _notifications) {
        notif['isUnread'] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('Notifications', style: GoogleFonts.sora(
          fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface,
        )),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text('Mark all read', style: GoogleFonts.plusJakartaSans(
              color: cs.primary, fontWeight: FontWeight.bold,
            )),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notif['isUnread'] == true ? cs.primary.withValues(alpha: 0.1) : cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: notif['isUnread'] == true ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(notif['icon'] as IconData, color: cs.onSurface, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(notif['title'] as String, style: GoogleFonts.manrope(
                            fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface,
                          )),
                          if (notif['isUnread'] == true)
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(notif['desc'] as String, style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, color: cs.onSurfaceVariant,
                      )),
                      const SizedBox(height: 10),
                      Text(notif['time'] as String, style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (200 + index * 100).ms).slideY(begin: 0.1);
        },
      ),
    );
  }
}
