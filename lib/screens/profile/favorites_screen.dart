import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites', style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 2,
        itemBuilder: (context, index) {
          final isFirst = index == 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.image_outlined, color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isFirst ? 'Prestige Tech Park' : 'Koramangala 4th Block', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(isFirst ? '4.9 (120+)' : '4.7 (89)', style: GoogleFonts.manrope(fontSize: 12, color: cs.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(isFirst ? '11 kW AC • ₹12/kWh' : '7.2 kW AC • ₹10/kWh', style: GoogleFonts.manrope(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite, color: Colors.red),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
