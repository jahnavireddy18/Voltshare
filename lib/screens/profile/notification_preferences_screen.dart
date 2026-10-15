import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _bookingUpdates = true;
  bool _reminders = true;
  bool _promotions = false;
  bool _hostAlerts = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bookingUpdates = prefs.getBool('pref_notif_booking') ?? true;
      _reminders = prefs.getBool('pref_notif_reminders') ?? true;
      _promotions = prefs.getBool('pref_notif_promos') ?? false;
      _hostAlerts = prefs.getBool('pref_notif_host') ?? true;
      _loading = false;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    // In a real app, you would also sync this to Firestore so Cloud Functions
    // know whether to send the push notification.
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: cs.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
        ),
        title: Text(
          'Notification Preferences',
          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionTitle('Driver Notifications'),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Booking Updates',
            subtitle: 'Get notified when your booking is confirmed or canceled.',
            value: _bookingUpdates,
            onChanged: (val) {
              setState(() => _bookingUpdates = val);
              _savePref('pref_notif_booking', val);
            },
          ),
          _buildSwitchTile(
            title: 'Reminders',
            subtitle: 'Get a 15-minute heads up before your charging session.',
            value: _reminders,
            onChanged: (val) {
              setState(() => _reminders = val);
              _savePref('pref_notif_reminders', val);
            },
          ),
          _buildSwitchTile(
            title: 'Promotions & Offers',
            subtitle: 'Receive updates about new features and discounts.',
            value: _promotions,
            onChanged: (val) {
              setState(() => _promotions = val);
              _savePref('pref_notif_promos', val);
            },
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Host Notifications'),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Host Alerts',
            subtitle: 'Get notified when a driver books your charger or starts a session.',
            value: _hostAlerts,
            onChanged: (val) {
              setState(() => _hostAlerts = val);
              _savePref('pref_notif_host', val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        color: cs.primary,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: cs.onSurfaceVariant,
            inactiveTrackColor: bgColor,
          ),
        ],
      ),
    );
  }
}
