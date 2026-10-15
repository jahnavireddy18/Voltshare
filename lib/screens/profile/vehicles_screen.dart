import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Vehicles', style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.directions_car, color: cs.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tata Nexon EV', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      Text('KA 01 AB 1234', style: GoogleFonts.manrope(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.battery_charging_full, size: 14, color: cs.primary),
                          const SizedBox(width: 4),
                          Text('CCS2 • 30 kWh', style: GoogleFonts.manrope(fontSize: 12, color: cs.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add a Vehicle'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }
}
