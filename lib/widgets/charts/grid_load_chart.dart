import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/models/grid_load_models.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class GridLoadChart extends StatelessWidget {
  const GridLoadChart({
    super.key,
    required this.metrics,
    this.height = 220,
  });

  final GridLoadMetrics metrics;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (metrics.buckets.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No session data for this period',
            style: GoogleFonts.manrope(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegend(context),
        const SizedBox(height: 16),
        SizedBox(
          height: height,
          child: LineChart(_buildChartData(context)),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      children: [
        _legendDot(context, AppColors.primary, 'VoltNest Sessions'),
        const SizedBox(width: 20),
        _legendDot(context, AppColors.warning, 'Traditional Baseline'),
      ],
    );
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxY = metrics.maxBucketValue.toDouble() * 1.2;

    return LineChartData(
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (value) => FlLine(
          color: cs.outlineVariant,
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: maxY / 4,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: _bottomInterval(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= metrics.buckets.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  metrics.buckets[index].label,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        _series(
          color: AppColors.primary,
          spots: metrics.buckets
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.actualSessions.toDouble()))
              .toList(),
        ),
        _series(
          color: AppColors.warning,
          spots: metrics.buckets
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.baselineSessions.toDouble()))
              .toList(),
          dashed: true,
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => cs.surfaceContainerHighest,
          getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
            final isActual = spot.barIndex == 0;
            return LineTooltipItem(
              '${isActual ? "VoltNest" : "Baseline"}\n${spot.y.toInt()} sessions',
              GoogleFonts.manrope(
                color: isActual ? AppColors.primary : AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  double _bottomInterval() {
    final count = metrics.buckets.length;
    if (metrics.view == GridLoadView.daily) return 3;
    if (count <= 7) return 1;
    return (count / 5).ceilToDouble();
  }

  LineChartBarData _series({
    required Color color,
    required List<FlSpot> spots,
    bool dashed = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.25,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: metrics.view != GridLoadView.monthly,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 0,
        ),
      ),
      belowBarData: BarAreaData(
        show: !dashed,
        color: color.withValues(alpha: 0.08),
      ),
      dashArray: dashed ? [6, 4] : null,
    );
  }
}
