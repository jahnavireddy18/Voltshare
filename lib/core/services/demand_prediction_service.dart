import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vnest_app/core/config/api_config.dart';
import 'package:vnest_app/core/models/pricing_models.dart';

class _CacheEntry {
  _CacheEntry(this.response, this.expiresAt);

  final DemandPredictionResponse response;
  final DateTime expiresAt;

  bool get isValid => DateTime.now().isBefore(expiresAt);
}

/// Calls the Firebase `/predict-demand` endpoint with in-memory caching
/// and rule-based fallback when the API is unavailable.
class DemandPredictionService {
  DemandPredictionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, _CacheEntry> _cache = {};

  Future<DemandPredictionResponse> predictDemand(
    DemandPredictionRequest request,
  ) async {
    final cached = _cache[request.cacheKey];
    if (cached != null && cached.isValid) {
      return cached.response;
    }

    try {
      final response = await _client
          .post(
            Uri.parse(ApiConfig.predictDemandUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final prediction = DemandPredictionResponse.fromJson(body);
        _cache[request.cacheKey] = _CacheEntry(
          prediction,
          DateTime.now().add(ApiConfig.predictionCacheTtl),
        );
        return prediction;
      }

      throw DemandPredictionException(
        'API returned status ${response.statusCode}',
      );
    } catch (_) {
      return _ruleBasedFallback(request);
    }
  }

  DemandPredictionResponse _ruleBasedFallback(DemandPredictionRequest request) {
    final demandScore = _computeRuleBasedDemandScore(request);
    final surgeMultiplier = _demandScoreToSurge(demandScore);
    final demandLabel = _demandScoreToLabel(demandScore);

    final fallback = DemandPredictionResponse(
      demandScore: demandScore,
      surgeMultiplier: surgeMultiplier,
      demandLabel: demandLabel,
      source: PricingSource.ruleBased,
    );

    _cache[request.cacheKey] = _CacheEntry(
      fallback,
      DateTime.now().add(ApiConfig.predictionCacheTtl),
    );

    return fallback;
  }

  /// Legacy static occupancy + time-of-day surge rules.
  double _computeRuleBasedDemandScore(DemandPredictionRequest request) {
    var score = 0.18;

    if (request.hour >= 7 && request.hour <= 9) {
      score += 0.22;
    } else if (request.hour >= 17 && request.hour <= 20) {
      score += 0.28;
    } else if (request.hour >= 12 && request.hour <= 14) {
      score += 0.10;
    }

    if (request.day >= 5) {
      score += 0.08;
      if (request.hour >= 10 && request.hour <= 16) score += 0.12;
    }

    const clusterBoost = [0.05, 0.20, 0.15, 0.18, 0.08];
    if (request.locationCluster < clusterBoost.length) {
      score += clusterBoost[request.locationCluster];
    }

    const tierBoost = [0.0, 0.10, 0.18];
    if (request.powerTier < tierBoost.length) {
      score += tierBoost[request.powerTier];
    }

    score += (request.rollingBookings / 20).clamp(0.0, 1.0) * 0.35;

    if (request.hour <= 5 || request.hour >= 23) score -= 0.12;

    return score.clamp(0.0, 1.0);
  }

  double _demandScoreToSurge(double demandScore) {
    return double.parse((1.0 + demandScore.clamp(0.0, 1.0) * 0.8).toStringAsFixed(2));
  }

  String _demandScoreToLabel(double demandScore) {
    if (demandScore >= 0.66) return 'High';
    if (demandScore >= 0.33) return 'Medium';
    return 'Low';
  }

  void clearCache() => _cache.clear();

  void dispose() => _client.close();
}

class DemandPredictionException implements Exception {
  DemandPredictionException(this.message);
  final String message;

  @override
  String toString() => 'DemandPredictionException: $message';
}
