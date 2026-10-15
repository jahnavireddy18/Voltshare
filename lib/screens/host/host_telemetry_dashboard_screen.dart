import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/models/telemetry_models.dart';
import 'package:vnest_app/core/services/telemetry_monitor_service.dart';
import 'package:vnest_app/core/services/telemetry_repository.dart';
import 'package:vnest_app/core/theme/app_theme.dart';
import 'package:vnest_app/widgets/charts/anomaly_history_chart.dart';

class HostTelemetryDashboardScreen extends StatefulWidget {
  const HostTelemetryDashboardScreen({
    super.key,
    required this.monitor,
  });

  final TelemetryMonitorService monitor;

  @override
  State<HostTelemetryDashboardScreen> createState() =>
      _HostTelemetryDashboardScreenState();
}

class _HostTelemetryDashboardScreenState extends State<HostTelemetryDashboardScreen> {
  TelemetrySnapshot? _snapshot;
  AnomalyDetectionMethod _method = AnomalyDetectionMethod.zScore;
  StreamSubscription<TelemetrySnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    _method = widget.monitor.method;
    _sub = widget.monitor.snapshots.listen((s) {
      if (mounted) setState(() => _snapshot = s);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _setMethod(AnomalyDetectionMethod method) {
    setState(() => _method = method);
    widget.monitor.setDetectionMethod(method);
  }

  @override
  Widget build(BuildContext context) {
    final snap = _snapshot;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'HOST TELEMETRY',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          if (snap?.isSimulation ?? true)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Text(
                'SIM',
                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.warning),
              ),
            ),
        ],
      ),
      body: snap == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await widget.monitor.stop();
                await widget.monitor.start(simulation: widget.monitor.isSimulation);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(snap),
                    const SizedBox(height: 20),
                    _buildMethodSelector(),
                    const SizedBox(height: 20),
                    _buildTelemetryGrid(snap),
                    const SizedBox(height: 20),
                    _buildRollingAverages(snap),
                    const SizedBox(height: 24),
                    Text('ANOMALY HISTORY', style: _sectionTitle),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration,
                      child: AnomalyHistoryChart(history: snap.history),
                    ),
                    const SizedBox(height: 24),
                    Text('SIMULATION CONTROLS', style: _sectionTitle),
                    const SizedBox(height: 12),
                    _buildSimulatorPanel(),
                  ],
                ),
              ),
            ),
    );
  }

  TextStyle get _sectionTitle => GoogleFonts.jetBrainsMono(
        fontSize: 10,
        color: AppColors.textSecondary,
        letterSpacing: 2,
      );

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      );

  Widget _buildStatusCard(TelemetrySnapshot snap) {
    final anomaly = snap.anomaly;
    final statusColor = switch (anomaly.statusLevel) {
      AnomalyStatusLevel.normal => AppColors.primary,
      AnomalyStatusLevel.warning => AppColors.warning,
      AnomalyStatusLevel.critical => AppColors.error,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.15),
            AppColors.surfaceDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(color: statusColor.withValues(alpha: 0.1), blurRadius: 24),
        ],
      ),
      child: Column(
        children: [
          Text(
            anomaly.statusEmoji,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 8),
          Text(
            anomaly.statusLabel,
            style: GoogleFonts.sora(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Anomaly Score: ${anomaly.anomalyScore.toStringAsFixed(0)} / 100',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: anomaly.anomalyScore / 100,
              minHeight: 6,
              backgroundColor: AppColors.borderDark,
              color: statusColor,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  Widget _buildMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: AnomalyDetectionMethod.values.map((m) {
          final selected = _method == m;
          final label = m == AnomalyDetectionMethod.zScore ? 'Z-Score' : 'Isolation Forest';
          return Expanded(
            child: GestureDetector(
              onTap: () => _setMethod(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTelemetryGrid(TelemetrySnapshot snap) {
    final r = snap.reading;
    final z = snap.anomaly.zScores;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metricTile('Voltage', '${r.voltage.toStringAsFixed(1)} V', z['voltage'] ?? 0, Icons.bolt)),
            const SizedBox(width: 12),
            Expanded(child: _metricTile('Current', '${r.current.toStringAsFixed(1)} A', z['current'] ?? 0, Icons.electric_bolt)),
          ],
        ),
        const SizedBox(height: 12),
        _metricTile('Temperature', '${r.temperature.toStringAsFixed(1)} °C', z['temperature'] ?? 0, Icons.thermostat, fullWidth: true),
      ],
    );
  }

  Widget _metricTile(String label, String value, double zScore, IconData icon, {bool fullWidth = false}) {
    final isElevated = zScore > 2;
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isElevated ? AppColors.warning.withValues(alpha: 0.4) : AppColors.borderDark,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isElevated ? AppColors.warning : AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.textSecondary, letterSpacing: 1)),
                Text(value, style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
          if (_method == AnomalyDetectionMethod.zScore)
            Text('z=${zScore.toStringAsFixed(1)}', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildRollingAverages(TelemetrySnapshot snap) {
    final avg = snap.rollingAverages;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ROLLING AVERAGES (${avg.sampleCount} samples)', style: _sectionTitle),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _avgItem('V', avg.voltage, 'V'),
              _avgItem('I', avg.current, 'A'),
              _avgItem('T', avg.temperature, '°C'),
            ],
          ),
          if (_method == AnomalyDetectionMethod.isolationForest) ...[
            const SizedBox(height: 12),
            Text(
              'Isolation score: ${snap.anomaly.isolationScore.toStringAsFixed(1)}',
              style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avgItem(String label, double value, String unit) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted)),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSimulatorPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inject abnormal readings to test detection',
            style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _simButton('Voltage Spike', SimulationAnomalyType.voltageSpike, Icons.bolt, AppColors.warning),
              _simButton('Overcurrent', SimulationAnomalyType.overCurrent, Icons.electric_bolt, AppColors.error),
              _simButton('Overheating', SimulationAnomalyType.overheating, Icons.thermostat, AppColors.error),
              _simButton('Combined Fault', SimulationAnomalyType.combined, Icons.warning_amber, AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _simButton(String label, SimulationAnomalyType type, IconData icon, Color color) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      onPressed: () => widget.monitor.injectAnomaly(type),
    );
  }
}

/// Entry screen that bootstraps the telemetry monitor.
class HostTelemetryScreen extends StatefulWidget {
  const HostTelemetryScreen({super.key});

  @override
  State<HostTelemetryScreen> createState() => _HostTelemetryScreenState();
}

class _HostTelemetryScreenState extends State<HostTelemetryScreen> {
  TelemetryMonitorService? _monitor;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final monitor = await TelemetryBootstrap.createMonitor();
    await monitor.start(simulation: true);
    if (mounted) setState(() => _monitor = monitor);
  }

  @override
  void dispose() {
    _monitor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_monitor == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return HostTelemetryDashboardScreen(monitor: _monitor!);
  }
}

/// Wires Firestore repository when available, otherwise simulation-only.
class TelemetryBootstrap {
  static const defaultChargerId = 'charger_demo_01';

  static Future<TelemetryMonitorService> createMonitor() async {
    final monitor = TelemetryMonitorService(chargerId: defaultChargerId);

    try {
      final repo = FirestoreTelemetryRepository();
      return TelemetryMonitorService(
        chargerId: defaultChargerId,
        repository: repo,
      );
    } catch (_) {
      return monitor;
    }
  }
}
