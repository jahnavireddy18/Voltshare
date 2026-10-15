import 'dart:async';

import 'package:vnest_app/core/models/telemetry_models.dart';
import 'package:vnest_app/core/services/anomaly_detection_engine.dart';
import 'package:vnest_app/core/services/telemetry_repository.dart';
import 'package:vnest_app/core/services/telemetry_simulator.dart';

/// Streams telemetry, computes rolling averages, and runs anomaly detection.
class TelemetryMonitorService {
  TelemetryMonitorService({
    required String chargerId,
    TelemetryRepository? repository,
    AnomalyDetectionEngine? engine,
    this.historyLimit = 60,
  })  : chargerId = chargerId,
        _repository = repository,
        _engine = engine ?? AnomalyDetectionEngine();

  final String chargerId;
  final TelemetryRepository? _repository;
  final AnomalyDetectionEngine _engine;
  final int historyLimit;

  final _snapshotController = StreamController<TelemetrySnapshot>.broadcast();
  StreamSubscription<TelemetryReading>? _subscription;
  TelemetrySimulator? _simulator;

  AnomalyDetectionMethod _method = AnomalyDetectionMethod.zScore;
  bool _simulationMode = false;
  final List<AnomalyHistoryPoint> _history = [];

  Stream<TelemetrySnapshot> get snapshots => _snapshotController.stream;

  AnomalyDetectionMethod get method => _method;
  bool get isSimulation => _simulationMode;

  void setDetectionMethod(AnomalyDetectionMethod method) => _method = method;

  Future<void> start({bool simulation = true}) async {
    await stop();
    _simulationMode = simulation;

    if (simulation || _repository == null) {
      _startSimulation();
      return;
    }

    try {
      _subscription = _repository!
          .streamReadings(chargerId: chargerId)
          .listen(_onReading, onError: (_) => _startSimulation());
      await _warmupFromFirestore();
    } catch (_) {
      _startSimulation();
    }
  }

  void _startSimulation() {
    _simulationMode = true;
    _simulator = TelemetrySimulator(chargerId: chargerId);
    _simulator!.start();
    _subscription = _simulator!.stream.listen(_onReading);
  }

  Future<void> _warmupFromFirestore() async {
    final repo = _repository;
    if (repo == null) return;
    try {
      final since = DateTime.now().subtract(const Duration(hours: 1));
      final history = await repo.fetchHistory(chargerId: chargerId, since: since);
      if (history.isNotEmpty) {
        _engine.seedHistory(history);
        for (final r in history) {
          _recordHistory(_engine.analyze(r, method: _method));
        }
      }
    } catch (_) {}
  }

  void _onReading(TelemetryReading reading) {
    final anomaly = _engine.analyze(reading, method: _method);
    _recordHistory(anomaly);

    _snapshotController.add(TelemetrySnapshot(
      reading: reading,
      rollingAverages: _engine.rollingAverages(),
      anomaly: anomaly,
      history: List.unmodifiable(_history),
      isSimulation: _simulationMode,
      source: _simulationMode ? 'simulation' : 'firestore',
    ));
  }

  void _recordHistory(AnomalyResult anomaly) {
    _history.add(AnomalyHistoryPoint(
      timestamp: DateTime.now(),
      anomalyScore: anomaly.anomalyScore,
      statusLevel: anomaly.statusLevel,
    ));
    if (_history.length > historyLimit) _history.removeAt(0);
  }

  void injectAnomaly(SimulationAnomalyType type) {
    _simulator?.injectAnomaly(type);
  }

  Future<void> pushToFirestore(TelemetryReading reading) async {
    final repo = _repository;
    if (repo == null) return;
    await repo.pushReading(reading.copyWith(chargerId: chargerId));
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _simulator?.dispose();
    _simulator = null;
  }

  void dispose() {
    stop();
    _snapshotController.close();
  }
}
