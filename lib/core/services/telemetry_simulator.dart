import 'dart:async';
import 'dart:math';

import 'package:vnest_app/core/models/telemetry_models.dart';

/// Generates realistic charger telemetry and supports anomaly injection.
class TelemetrySimulator {
  TelemetrySimulator({
    required this.chargerId,
    Random? random,
    this.interval = const Duration(seconds: 2),
  }) : _random = random ?? Random(42);

  final String chargerId;
  final Duration interval;
  final Random _random;

  final _controller = StreamController<TelemetryReading>.broadcast();
  Timer? _timer;
  SimulationAnomalyType? _pendingAnomaly;
  int _tick = 0;

  Stream<TelemetryReading> get stream => _controller.stream;

  bool get isRunning => _timer?.isActive ?? false;

  void start() {
    _timer?.cancel();
    _seedWarmup();
    _timer = Timer.periodic(interval, (_) => _emit());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void injectAnomaly(SimulationAnomalyType type) {
    _pendingAnomaly = type;
    _emit();
  }

  void clearAnomaly() => _pendingAnomaly = null;

  void _seedWarmup() {
    for (var i = 0; i < 15; i++) {
      _controller.add(_normalReading(DateTime.now().subtract(Duration(seconds: (15 - i) * 2))));
    }
  }

  void _emit() {
    _tick++;
    final reading = _pendingAnomaly != null
        ? _anomalousReading(_pendingAnomaly!)
        : _normalReading(DateTime.now());
    _pendingAnomaly = null;
    _controller.add(reading);
  }

  TelemetryReading _normalReading(DateTime ts) {
    return TelemetryReading(
      voltage: 228 + _random.nextDouble() * 6,
      current: 14 + _random.nextDouble() * 4,
      temperature: 32 + _random.nextDouble() * 6,
      timestamp: ts,
      chargerId: chargerId,
    );
  }

  TelemetryReading _anomalousReading(SimulationAnomalyType type) {
    final base = _normalReading(DateTime.now());
    return switch (type) {
      SimulationAnomalyType.voltageSpike => base.copyWith(voltage: 275 + _random.nextDouble() * 10),
      SimulationAnomalyType.overCurrent => base.copyWith(current: 42 + _random.nextDouble() * 8),
      SimulationAnomalyType.overheating => base.copyWith(temperature: 78 + _random.nextDouble() * 12),
      SimulationAnomalyType.combined => base.copyWith(
          voltage: 268 + _random.nextDouble() * 5,
          current: 40 + _random.nextDouble() * 5,
          temperature: 82 + _random.nextDouble() * 5,
        ),
    };
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
