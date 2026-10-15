import 'dart:math';

import 'package:vnest_app/core/models/telemetry_models.dart';

/// Computes rolling statistics and detects anomalies via Z-score or Isolation Forest.
class AnomalyDetectionEngine {
  AnomalyDetectionEngine({
    this.windowSize = 30,
    this.zScoreThreshold = 3.0,
    this.isolationTrees = 64,
    this.isolationSubsample = 64,
    Random? random,
  }) : _random = random ?? Random(42);

  final int windowSize;
  final double zScoreThreshold;
  final int isolationTrees;
  final int isolationSubsample;
  final Random _random;

  final List<TelemetryReading> _buffer = [];
  List<_IsolationTree> _forest = [];

  AnomalyResult analyze(
    TelemetryReading reading, {
    AnomalyDetectionMethod method = AnomalyDetectionMethod.zScore,
  }) {
    _buffer.add(reading);
    if (_buffer.length > windowSize) _buffer.removeAt(0);

    final stats = _computeStats();
    final zScores = _zScores(reading, stats);
    final zScoreResult = _zScoreToAnomaly(zScores);
    final isolationRaw = _isolationForestScore(reading);
    final isolationScore = (isolationRaw * 100).clamp(0.0, 100.0);

    final score = switch (method) {
      AnomalyDetectionMethod.zScore => zScoreResult,
      AnomalyDetectionMethod.isolationForest => isolationScore,
    };

    return AnomalyResult(
      anomalyScore: double.parse(score.toStringAsFixed(1)),
      statusLevel: AnomalyResult.levelFromScore(score),
      method: method,
      zScores: zScores,
      isolationScore: isolationScore,
    );
  }

  RollingAverages rollingAverages() {
    if (_buffer.isEmpty) return RollingAverages.empty;
    final n = _buffer.length;
    var v = 0.0, c = 0.0, t = 0.0;
    for (final r in _buffer) {
      v += r.voltage;
      c += r.current;
      t += r.temperature;
    }
    return RollingAverages(
      voltage: v / n,
      current: c / n,
      temperature: t / n,
      sampleCount: n,
    );
  }

  void reset() {
    _buffer.clear();
    _forest = [];
  }

  void seedHistory(List<TelemetryReading> readings) {
    _buffer
      ..clear()
      ..addAll(readings.take(windowSize));
    _rebuildForest();
  }

  _FeatureStats _computeStats() {
    if (_buffer.length < 3) {
      return const _FeatureStats(
        voltageMean: 230, voltageStd: 5,
        currentMean: 16, currentStd: 3,
        temperatureMean: 35, temperatureStd: 5,
      );
    }

    return _FeatureStats(
      voltageMean: _mean(_buffer.map((r) => r.voltage)),
      voltageStd: _std(_buffer.map((r) => r.voltage)),
      currentMean: _mean(_buffer.map((r) => r.current)),
      currentStd: _std(_buffer.map((r) => r.current)),
      temperatureMean: _mean(_buffer.map((r) => r.temperature)),
      temperatureStd: _std(_buffer.map((r) => r.temperature)),
    );
  }

  Map<String, double> _zScores(TelemetryReading reading, _FeatureStats stats) {
    return {
      'voltage': _z(reading.voltage, stats.voltageMean, stats.voltageStd),
      'current': _z(reading.current, stats.currentMean, stats.currentStd),
      'temperature': _z(reading.temperature, stats.temperatureMean, stats.temperatureStd),
    };
  }

  double _zScoreToAnomaly(Map<String, double> zScores) {
    final maxZ = zScores.values.reduce(max);
    return ((maxZ / zScoreThreshold) * 100).clamp(0.0, 100.0);
  }

  double _isolationForestScore(TelemetryReading reading) {
    if (_buffer.length < 8) return 0;
    _rebuildForest();
    if (_forest.isEmpty) return 0;

    final point = reading.featureVector;
    final avgPath = _forest.map((t) => t.pathLength(point, 0)).reduce((a, b) => a + b) / _forest.length;
    final c = _averagePathLength(isolationSubsample);
    return pow(2, -avgPath / c).toDouble().clamp(0.0, 1.0);
  }

  void _rebuildForest() {
    if (_buffer.length < 8) return;
    final sample = _buffer.map((r) => r.featureVector).toList();
    _forest = List.generate(isolationTrees, (_) {
      final subset = _subsample(sample, isolationSubsample);
      return _IsolationTree.build(subset, _random, maxDepth: 8);
    });
  }

  List<List<double>> _subsample(List<List<double>> data, int size) {
    final copy = List<List<double>>.from(data);
    copy.shuffle(_random);
    return copy.take(min(size, copy.length)).toList();
  }

  static double _mean(Iterable<double> values) =>
      values.reduce((a, b) => a + b) / values.length;

  static double _std(Iterable<double> values) {
    final m = _mean(values);
    final variance = values.map((v) => pow(v - m, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance).clamp(0.001, double.infinity);
  }

  static double _z(double value, double mean, double std) =>
      (value - mean).abs() / std;

  static double _averagePathLength(int n) {
    if (n <= 1) return 0;
    return 2 * (log(n - 1) + 0.5772156649) - 2 * (n - 1) / n;
  }
}

class _FeatureStats {
  const _FeatureStats({
    required this.voltageMean,
    required this.voltageStd,
    required this.currentMean,
    required this.currentStd,
    required this.temperatureMean,
    required this.temperatureStd,
  });

  final double voltageMean;
  final double voltageStd;
  final double currentMean;
  final double currentStd;
  final double temperatureMean;
  final double temperatureStd;
}

class _IsolationTree {
  _IsolationTree({this.splitFeature, this.splitValue, this.left, this.right, this.size = 0});

  final int? splitFeature;
  final double? splitValue;
  final _IsolationTree? left;
  final _IsolationTree? right;
  final int size;

  static _IsolationTree build(List<List<double>> data, Random random, {required int maxDepth, int depth = 0}) {
    if (depth >= maxDepth || data.length <= 1) {
      return _IsolationTree(size: data.length);
    }

    final featureCount = data.first.length;
    final feature = random.nextInt(featureCount);
    final values = data.map((p) => p[feature]).toList();
    final minV = values.reduce(min);
    final maxV = values.reduce(max);
    if (minV == maxV) return _IsolationTree(size: data.length);

    final split = minV + random.nextDouble() * (maxV - minV);
    final leftData = data.where((p) => p[feature] < split).toList();
    final rightData = data.where((p) => p[feature] >= split).toList();

    if (leftData.isEmpty || rightData.isEmpty) {
      return _IsolationTree(size: data.length);
    }

    return _IsolationTree(
      splitFeature: feature,
      splitValue: split,
      left: build(leftData, random, maxDepth: maxDepth, depth: depth + 1),
      right: build(rightData, random, maxDepth: maxDepth, depth: depth + 1),
      size: data.length,
    );
  }

  double pathLength(List<double> point, int depth) {
    if (splitFeature == null) {
      return depth + _averagePathLength(size);
    }
    if (point[splitFeature!] < splitValue!) {
      return left?.pathLength(point, depth + 1) ?? depth.toDouble();
    }
    return right?.pathLength(point, depth + 1) ?? depth.toDouble();
  }

  static double _averagePathLength(int n) {
    if (n <= 1) return 0;
    return 2 * (log(n - 1) + 0.5772156649) - 2 * (n - 1) / n;
  }
}
