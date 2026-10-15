import 'dart:async';
import 'dart:math';

enum ChargeStatus { preparing, charging, suspended, finished, faulted }

class OcppTelemetry {
  final double kwhDelivered;
  final double cost;
  final double powerKw;
  final double voltage;
  final double progressPercentage;
  final int durationSeconds;
  final ChargeStatus status;

  OcppTelemetry({
    required this.kwhDelivered,
    required this.cost,
    required this.powerKw,
    required this.voltage,
    required this.progressPercentage,
    required this.durationSeconds,
    required this.status,
  });
}

class OcppService {
  // Singleton pattern for the service
  static final OcppService _instance = OcppService._internal();
  factory OcppService() => _instance;
  OcppService._internal();

  final _controller = StreamController<OcppTelemetry>.broadcast();
  Timer? _timer;
  
  // State variables
  double _kwh = 14.4;
  int _duration = 2535; // Start at 42:15
  double _progress = 0.675;
  ChargeStatus _status = ChargeStatus.preparing;

  Stream<OcppTelemetry> get telemetryStream => _controller.stream;

  void startSession() {
    _status = ChargeStatus.charging;
    _timer?.cancel();
    
    // Emit initial state
    _emitUpdate();

    // Simulate OCPP MeterValues received every 2 seconds
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_status != ChargeStatus.charging) return;

      _duration += 2;
      _kwh += 0.02;
      _progress = (_progress + 0.002).clamp(0.0, 1.0);
      
      if (_progress >= 1.0) {
        stopSession();
      } else {
        _emitUpdate();
      }
    });
  }

  void stopSession() {
    _status = ChargeStatus.finished;
    _timer?.cancel();
    _emitUpdate();
  }

  void _emitUpdate() {
    // Generate realistic fluctuating telemetry
    final power = _status == ChargeStatus.charging ? 7.0 + Random().nextDouble() * 0.4 : 0.0;
    final volts = _status == ChargeStatus.charging ? 230.5 + Random().nextDouble() * 1.5 : 228.0;

    _controller.add(OcppTelemetry(
      kwhDelivered: _kwh,
      cost: _kwh * 15.0, // ₹15 per kWh
      powerKw: power,
      voltage: volts,
      progressPercentage: _progress,
      durationSeconds: _duration,
      status: _status,
    ));
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
