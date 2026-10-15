enum GridLoadView { daily, weekly, monthly }

/// Peak grid hours: 6 PM – 10 PM (18:00–21:59).
bool isPeakHour(int hour) => hour >= 18 && hour < 22;

class GridLoadBucket {
  const GridLoadBucket({
    required this.label,
    required this.actualSessions,
    required this.baselineSessions,
    this.hour,
    this.date,
  });

  final String label;
  final int actualSessions;
  final int baselineSessions;
  final int? hour;
  final DateTime? date;
}

class GridLoadMetrics {
  const GridLoadMetrics({
    required this.totalSessions,
    required this.peakHourSessions,
    required this.offPeakSessions,
    required this.percentageShifted,
    required this.buckets,
    required this.view,
    required this.rangeStart,
    required this.rangeEnd,
    required this.source,
  });

  final int totalSessions;
  final int peakHourSessions;
  final int offPeakSessions;
  final double percentageShifted;
  final List<GridLoadBucket> buckets;
  final GridLoadView view;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final String source;

  String get insightMessage {
    final pct = percentageShifted.round();
    if (pct >= 60) {
      return '$pct% of charging sessions occurred outside peak hours — '
          'significant grid load shifting via peer-to-peer charging.';
    }
    if (pct >= 40) {
      return '$pct% of charging sessions occurred outside peak hours, '
          'helping flatten evening grid demand.';
    }
    if (pct >= 20) {
      return '$pct% of sessions are off-peak. VoltNest is beginning to shift '
          'demand away from 6–10 PM peak windows.';
    }
    return 'Only $pct% of sessions are off-peak. More P2P availability '
        'could further reduce peak-hour grid strain.';
  }

  int get maxBucketValue {
    if (buckets.isEmpty) return 1;
    return buckets
        .map((b) => b.actualSessions > b.baselineSessions
            ? b.actualSessions
            : b.baselineSessions)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, 999999);
  }
}

class BookingSlot {
  const BookingSlot({required this.slotStart, this.id});

  final DateTime slotStart;
  final String? id;
}
