import 'package:vnest_app/core/models/grid_load_models.dart';
import 'package:vnest_app/core/services/bookings_repository.dart';

class _CacheEntry {
  _CacheEntry(this.metrics, this.expiresAt);
  final GridLoadMetrics metrics;
  final DateTime expiresAt;
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

/// Aggregates Firestore bookings by hour and computes grid-load metrics.
class GridAnalyticsService {
  GridAnalyticsService({
    BookingsRepository? repository,
    Duration cacheTtl = const Duration(minutes: 5),
  })  : _repository = repository,
        _cacheTtl = cacheTtl;

  BookingsRepository? _repository;
  final Duration _cacheTtl;
  final Map<String, _CacheEntry> _cache = {};
  bool _useDemo = false;

  void configureRepository(BookingsRepository repository) {
    _repository = repository;
    _cache.clear();
  }

  void useDemoData() {
    _useDemo = true;
    _repository = DemoBookingsRepository();
    _cache.clear();
  }

  Future<GridLoadMetrics> loadDashboard({
    required GridLoadView view,
    DateTime? referenceDate,
  }) async {
    final ref = referenceDate ?? DateTime.now();
    final cacheKey = '${view.name}|${ref.toIso8601String().substring(0, 10)}';
    final cached = _cache[cacheKey];
    if (cached != null && cached.isValid) return cached.metrics;

    final range = _dateRangeForView(view, ref);
    final slots = await _fetchSlots(range.start, range.end);

    final metrics = _aggregate(
      slots: slots,
      view: view,
      rangeStart: range.start,
      rangeEnd: range.end,
      source: _useDemo ? 'demo' : 'firestore',
    );

    _cache[cacheKey] = _CacheEntry(metrics, DateTime.now().add(_cacheTtl));
    return metrics;
  }

  void clearCache() => _cache.clear();

  Future<List<BookingSlot>> _fetchSlots(DateTime start, DateTime end) async {
    final repo = _repository ?? DemoBookingsRepository();
    try {
      final slots = await repo.fetchSlotsInRange(start: start, end: end);
      if (slots.isEmpty && !_useDemo && repo is FirestoreBookingsRepository) {
        _useDemo = true;
        return DemoBookingsRepository().fetchSlotsInRange(start: start, end: end);
      }
      return slots;
    } catch (_) {
      _useDemo = true;
      return DemoBookingsRepository().fetchSlotsInRange(start: start, end: end);
    }
  }

  ({DateTime start, DateTime end}) _dateRangeForView(GridLoadView view, DateTime ref) {
    final today = DateTime(ref.year, ref.month, ref.day);
    switch (view) {
      case GridLoadView.daily:
        return (start: today, end: today.add(const Duration(days: 1)));
      case GridLoadView.weekly:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return (start: weekStart, end: weekStart.add(const Duration(days: 7)));
      case GridLoadView.monthly:
        final monthStart = DateTime(ref.year, ref.month, 1);
        final monthEnd = DateTime(ref.year, ref.month + 1, 1);
        return (start: monthStart, end: monthEnd);
    }
  }

  GridLoadMetrics _aggregate({
    required List<BookingSlot> slots,
    required GridLoadView view,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required String source,
  }) {
    final total = slots.length;
    var peak = 0;
    var offPeak = 0;

    for (final slot in slots) {
      if (isPeakHour(slot.slotStart.hour)) {
        peak++;
      } else {
        offPeak++;
      }
    }

    final pctShifted = total == 0 ? 0.0 : (offPeak / total) * 100;
    final buckets = _buildBuckets(slots, view, rangeStart, rangeEnd);

    return GridLoadMetrics(
      totalSessions: total,
      peakHourSessions: peak,
      offPeakSessions: offPeak,
      percentageShifted: pctShifted,
      buckets: buckets,
      view: view,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      source: source,
    );
  }

  List<GridLoadBucket> _buildBuckets(
    List<BookingSlot> slots,
    GridLoadView view,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    switch (view) {
      case GridLoadView.daily:
        return _hourlyBuckets(slots);
      case GridLoadView.weekly:
        return _dailyBuckets(slots, rangeStart, 7);
      case GridLoadView.monthly:
        final days = rangeEnd.difference(rangeStart).inDays;
        return _dailyBuckets(slots, rangeStart, days);
    }
  }

  List<GridLoadBucket> _hourlyBuckets(List<BookingSlot> slots) {
    final counts = List<int>.filled(24, 0);
    for (final slot in slots) {
      counts[slot.slotStart.hour]++;
    }

    final total = slots.length;
    return List.generate(24, (hour) {
      final actual = counts[hour];
      final baseline = _baselineSessionsForBucket(total, hour, 24);
      return GridLoadBucket(
        label: _hourLabel(hour),
        actualSessions: actual,
        baselineSessions: baseline,
        hour: hour,
      );
    });
  }

  List<GridLoadBucket> _dailyBuckets(
    List<BookingSlot> slots,
    DateTime rangeStart,
    int dayCount,
  ) {
    final counts = List<int>.filled(dayCount, 0);
    for (final slot in slots) {
      final dayIndex = slot.slotStart.difference(rangeStart).inDays;
      if (dayIndex >= 0 && dayIndex < dayCount) counts[dayIndex]++;
    }

    final total = slots.length;
    return List.generate(dayCount, (i) {
      final day = rangeStart.add(Duration(days: i));
      final actual = counts[i];
      // Baseline: traditional charging concentrates same daily total into peak
      final baseline = total == 0
          ? 0
          : (total / dayCount * _peakConcentrationFactor()).round();
      return GridLoadBucket(
        label: _dayLabel(day),
        actualSessions: actual,
        baselineSessions: baseline,
        date: day,
      );
    });
  }

  /// Traditional baseline weight for a given hour (6–10 PM concentrated).
  static double baselineHourWeight(int hour) {
    if (hour >= 18 && hour < 22) return 0.22;
    return 0.006;
  }

  static double _peakConcentrationFactor() => 0.72;

  static int _baselineSessionsForBucket(int total, int hour, int bucketCount) {
    if (total == 0) return 0;
    final weights = List.generate(24, baselineHourWeight);
    final weightSum = weights.reduce((a, b) => a + b);
    return (total * (weights[hour] / weightSum)).round();
  }

  static String _hourLabel(int hour) {
    if (hour == 0) return '12a';
    if (hour < 12) return '${hour}a';
    if (hour == 12) return '12p';
    return '${hour - 12}p';
  }

  static String _dayLabel(DateTime day) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${names[day.weekday - 1]} ${day.day}';
  }
}
