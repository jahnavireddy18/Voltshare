enum DemandLevel { low, medium, high }

enum PricingSource { ml, ruleBased }

class DemandPredictionRequest {
  const DemandPredictionRequest({
    required this.hour,
    required this.day,
    required this.locationCluster,
    required this.powerTier,
    required this.rollingBookings,
  });

  final int hour;
  final int day;
  final int locationCluster;
  final int powerTier;
  final int rollingBookings;

  String get cacheKey =>
      '$hour|$day|$locationCluster|$powerTier|$rollingBookings';

  Map<String, dynamic> toJson() => {
        'hour': hour,
        'day': day,
        'locationCluster': locationCluster,
        'powerTier': powerTier,
        'rollingBookings': rollingBookings,
      };
}

class DemandPredictionResponse {
  const DemandPredictionResponse({
    required this.demandScore,
    required this.surgeMultiplier,
    required this.demandLabel,
    required this.source,
  });

  final double demandScore;
  final double surgeMultiplier;
  final String demandLabel;
  final PricingSource source;

  DemandLevel get demandLevel {
    if (demandScore >= 0.66) return DemandLevel.high;
    if (demandScore >= 0.33) return DemandLevel.medium;
    return DemandLevel.low;
  }

  factory DemandPredictionResponse.fromJson(
    Map<String, dynamic> json, {
    PricingSource? source,
  }) {
    final resolvedSource = source ??
        (json['source'] == 'ml' ? PricingSource.ml : PricingSource.ruleBased);
    return DemandPredictionResponse(
      demandScore: (json['demandScore'] as num).toDouble(),
      surgeMultiplier: (json['surgeMultiplier'] as num).toDouble(),
      demandLabel: json['demandLabel'] as String? ?? 'Medium',
      source: resolvedSource,
    );
  }
}

class PricingQuote {
  const PricingQuote({
    required this.baseRatePerKwh,
    required this.estimatedKwh,
    required this.surgeMultiplier,
    required this.demandScore,
    required this.demandLabel,
    required this.source,
    required this.baseCost,
    required this.surcharge,
    required this.totalCost,
    required this.effectiveRatePerKwh,
  });

  final double baseRatePerKwh;
  final double estimatedKwh;
  final double surgeMultiplier;
  final double demandScore;
  final String demandLabel;
  final PricingSource source;
  final double baseCost;
  final double surcharge;
  final double totalCost;
  final double effectiveRatePerKwh;

  bool get hasSurge => surgeMultiplier > 1.0;

  DemandLevel get demandLevel {
    if (demandScore >= 0.66) return DemandLevel.high;
    if (demandScore >= 0.33) return DemandLevel.medium;
    return DemandLevel.low;
  }
}
