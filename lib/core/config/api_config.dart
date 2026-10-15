/// API configuration for VoltNest Cloud Functions.
class ApiConfig {
  /// Firebase Cloud Function URL for demand prediction.
  ///
  /// Local emulator: `http://127.0.0.1:5001/[project-id]/asia-south1/predictDemand`
  /// Production: set via --dart-define=PREDICT_DEMAND_URL=...
  static const String predictDemandUrl = String.fromEnvironment(
    'PREDICT_DEMAND_URL',
    defaultValue: 'http://127.0.0.1:5001/volt-nest-demo/asia-south1/predictDemand',
  );

  /// Cache TTL for demand predictions (same scenario key).
  static const Duration predictionCacheTtl = Duration(minutes: 10);
}
