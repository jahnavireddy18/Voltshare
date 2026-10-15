import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vnest_app/core/models/telemetry_models.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class AnomalyHistoryChart extends StatelessWidget {
  const AnomalyHistoryChart({
    super.key,
    required this.history,
    this.height = 180,
  });

  final List<AnomalyHistoryPoint> history;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (history.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Collecting anomaly history…',
            style: GoogleFonts.manrope(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThresholdLegend(),
        const SizedBox(height: 12),
        SizedBox(height: height, child: LineChart(_buildData())),
      ],
    );
  }

  Widget _buildThresholdLegend() {
    return Row(
      children: [
        _chip('Normal', AppColors.primary, '<41'),
        const SizedBox(width: 8),
        _chip('Warning', AppColors.warning, '41–70'),
        const SizedBox(width: 8),
        _chip('Critical', AppColors.error, '71+'),
      ],
    );
  }

  Widget _chip(String label, Color color, String range) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$label $range', style: GoogleFonts.jetBrainsMono(fontSize: 8, color: AppColors.textMuted)),
      ],
    );
  }

  LineChartData _buildData() {
    final spots = history.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.anomalyScore))
        .toList();

    return LineChartData(
      minY: 0,
      maxY: 100,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (v) => FlLine(
          color: AppColors.borderDark,
          strokeWidth: 1,
          dashArray: v == 41 || v == 71 ? [4, 4] : null,
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
            interval: 25,
            getTitlesWidget: (v, _) => Text(
              v.toInt().toString(),
              style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.textMuted),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: (history.length / 4).clamp(1, 15).toDouble(),
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= history.length) return const SizedBox.shrink();
              return Text(
                DateFormat('HH:mm').format(history[i].timestamp),
                style: GoogleFonts.jetBrainsMono(fontSize: 8, color: AppColors.textMuted),
              );
            },
          ),
        ),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(y: 41, color: AppColors.warning.withValues(alpha: 0.4), strokeWidth: 1, dashArray: [4, 4]),
          HorizontalLine(y: 71, color: AppColors.error.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [4, 4]),
        ],
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: AppColors.warning,
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, index) {
              final level = history[index].statusLevel;
              final color = switch (level) {
                AnomalyStatusLevel.normal => AppColors.primary,
                AnomalyStatusLevel.warning => AppColors.warning,
                AnomalyStatusLevel.critical => AppColors.error,
              };
              return FlDotCirclePainter(radius: 2.5, color: color, strokeWidth: 0);
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.warning.withValues(alpha: 0.2),
                AppColors.warning.withValues(alpha: 0.02),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.surfaceVariantDark,
          getTooltipItems: (spots) => spots.map((spot) {
            final point = history[spot.x.toInt()];
            return LineTooltipItem(
              'Score: ${spot.y.toStringAsFixed(0)}\n${point.statusLevel.name}',
              GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
