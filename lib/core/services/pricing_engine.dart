import 'package:vnest_app/core/models/pricing_models.dart';
import 'package:vnest_app/core/services/demand_prediction_service.dart';

/// Charger context used to build demand prediction inputs.
class ChargerPricingContext {
  const ChargerPricingContext({
    required this.baseRatePerKwh,
    required this.estimatedKwh,
    required this.locationCluster,
    required this.powerTier,
    required this.rollingBookings,
    this.scheduledHour,
    this.scheduledDay,
  });

  final double baseRatePerKwh;
  final double estimatedKwh;
  final int locationCluster;
  final int powerTier;
  final int rollingBookings;
  final int? scheduledHour;
  final int? scheduledDay;
}

/// ML-powered pricing engine with rule-based fallback.
class PricingEngine {
  PricingEngine({DemandPredictionService? predictionService})
      : _predictionService = predictionService ?? DemandPredictionService();

  final DemandPredictionService _predictionService;

  Future<PricingQuote> getQuote(ChargerPricingContext context) async {
    final now = DateTime.now();
    final request = DemandPredictionRequest(
      hour: context.scheduledHour ?? now.hour,
      day: context.scheduledDay ?? now.weekday - 1,
      locationCluster: context.locationCluster,
      powerTier: context.powerTier,
      rollingBookings: context.rollingBookings,
    );

    final prediction = await _predictionService.predictDemand(request);
    return _buildQuote(context, prediction);
  }

  PricingQuote _buildQuote(
    ChargerPricingContext context,
    DemandPredictionResponse prediction,
  ) {
    final baseCost = context.baseRatePerKwh * context.estimatedKwh;
    final totalCost = baseCost * prediction.surgeMultiplier;
    final surcharge = totalCost - baseCost;
    final effectiveRate = context.baseRatePerKwh * prediction.surgeMultiplier;

    return PricingQuote(
      baseRatePerKwh: context.baseRatePerKwh,
      estimatedKwh: context.estimatedKwh,
      surgeMultiplier: prediction.surgeMultiplier,
      demandScore: prediction.demandScore,
      demandLabel: prediction.demandLabel,
      source: prediction.source,
      baseCost: baseCost,
      surcharge: surcharge,
      totalCost: totalCost,
      effectiveRatePerKwh: effectiveRate,
    );
  }

  void clearCache() => _predictionService.clearCache();
}

/// Demo charger presets for VoltNest screens.
class DemoChargers {
  static const teslaWallbox = ChargerPricingContext(
    baseRatePerKwh: 10.0,
    estimatedKwh: 7.2,
    locationCluster: 0,
    powerTier: 0,
    rollingBookings: 6,
  );

  static const voltChargeHub = ChargerPricingContext(
    baseRatePerKwh: 10.0,
    estimatedKwh: 7.2,
    locationCluster: 1,
    powerTier: 1,
    rollingBookings: 9,
    scheduledHour: 14,
  );
}
