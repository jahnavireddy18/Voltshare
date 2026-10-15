enum AnomalyDetectionMethod { zScore, isolationForest }

enum AnomalyStatusLevel { normal, warning, critical }

enum SimulationAnomalyType {
  voltageSpike,
  overCurrent,
  overheating,
  combined,
}

class TelemetryReading {
  const TelemetryReading({
    required this.voltage,
    required this.current,
    required this.temperature,
    required this.timestamp,
    this.id,
    this.chargerId,
  });

  final double voltage;
  final double current;
  final double temperature;
  final DateTime timestamp;
  final String? id;
  final String? chargerId;

  List<double> get featureVector => [voltage, current, temperature];

  TelemetryReading copyWith({
    double? voltage,
    double? current,
    double? temperature,
    DateTime? timestamp,
    String? id,
    String? chargerId,
  }) {
    return TelemetryReading(
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      temperature: temperature ?? this.temperature,
      timestamp: timestamp ?? this.timestamp,
      id: id ?? this.id,
      chargerId: chargerId ?? this.chargerId,
    );
  }

  factory TelemetryReading.fromFirestore(
    Map<String, dynamic> data, {
    String? id,
  }) {
    return TelemetryReading(
      voltage: (data['voltage'] as num).toDouble(),
      current: (data['current'] as num).toDouble(),
      temperature: (data['temperature'] as num).toDouble(),
      timestamp: (data['timestamp'] as dynamic).toDate(),
      id: id,
      chargerId: data['chargerId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'voltage': voltage,
        'current': current,
        'temperature': temperature,
        'timestamp': timestamp,
        if (chargerId != null) 'chargerId': chargerId,
      };
}

class RollingAverages {
  const RollingAverages({
    required this.voltage,
    required this.current,
    required this.temperature,
    required this.sampleCount,
  });

  final double voltage;
  final double current;
  final double temperature;
  final int sampleCount;

  static const empty = RollingAverages(
    voltage: 0,
    current: 0,
    temperature: 0,
    sampleCount: 0,
  );
}

class AnomalyResult {
  const AnomalyResult({
    required this.anomalyScore,
    required this.statusLevel,
    required this.method,
    required this.zScores,
    required this.isolationScore,
  });

  final double anomalyScore;
  final AnomalyStatusLevel statusLevel;
  final AnomalyDetectionMethod method;
  final Map<String, double> zScores;
  final double isolationScore;

  String get statusLabel {
    switch (statusLevel) {
      case AnomalyStatusLevel.normal:
        return 'Charger Healthy';
      case AnomalyStatusLevel.warning:
        return 'Attention Needed';
      case AnomalyStatusLevel.critical:
        return 'Immediate Investigation';
    }
  }

  String get statusEmoji {
    switch (statusLevel) {
      case AnomalyStatusLevel.normal:
        return '🟢';
      case AnomalyStatusLevel.warning:
        return '🟡';
      case AnomalyStatusLevel.critical:
        return '🔴';
    }
  }

  static AnomalyStatusLevel levelFromScore(double score) {
    if (score >= 71) return AnomalyStatusLevel.critical;
    if (score >= 41) return AnomalyStatusLevel.warning;
    return AnomalyStatusLevel.normal;
  }
}

class AnomalyHistoryPoint {
  const AnomalyHistoryPoint({
    required this.timestamp,
    required this.anomalyScore,
    required this.statusLevel,
  });

  final DateTime timestamp;
  final double anomalyScore;
  final AnomalyStatusLevel statusLevel;
}

class TelemetrySnapshot {
  const TelemetrySnapshot({
    required this.reading,
    required this.rollingAverages,
    required this.anomaly,
    required this.history,
    required this.isSimulation,
    required this.source,
  });

  final TelemetryReading reading;
  final RollingAverages rollingAverages;
  final AnomalyResult anomaly;
  final List<AnomalyHistoryPoint> history;
  final bool isSimulation;
  final String source;
}
