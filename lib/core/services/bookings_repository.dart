import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vnest_app/core/models/grid_load_models.dart';

/// Reads `bookings` collection and returns only `slotStart` timestamps.
///
/// Query optimization:
/// - Date-bounded range filter on `slotStart` (single indexed query)
/// - No full-document fan-out beyond required field
/// - Batched reads capped at Firestore limits
abstract class BookingsRepository {
  Future<List<BookingSlot>> fetchSlotsInRange({
    required DateTime start,
    required DateTime end,
  });
}

class FirestoreBookingsRepository implements BookingsRepository {
  FirestoreBookingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _collection = 'bookings';
  static const _pageSize = 500;

  @override
  Future<List<BookingSlot>> fetchSlotsInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final slots = <BookingSlot>[];
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .where('slotStart', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('slotStart', isLessThan: Timestamp.fromDate(end))
        .orderBy('slotStart')
        .limit(_pageSize);

    QuerySnapshot<Map<String, dynamic>> snapshot;
    do {
      snapshot = await query.get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ts = data['slotStart'];
        if (ts is Timestamp) {
          slots.add(BookingSlot(slotStart: ts.toDate(), id: doc.id));
        }
      }
      if (snapshot.docs.length < _pageSize) break;
      query = _firestore
          .collection(_collection)
          .where('slotStart', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('slotStart', isLessThan: Timestamp.fromDate(end))
          .orderBy('slotStart')
          .startAfterDocument(snapshot.docs.last)
          .limit(_pageSize);
    } while (snapshot.docs.length == _pageSize);

    return slots;
  }
}

/// Deterministic demo data when Firestore is unavailable or empty.
class DemoBookingsRepository implements BookingsRepository {
  DemoBookingsRepository({Random? random}) : _random = random ?? Random(42);

  final Random _random;

  @override
  Future<List<BookingSlot>> fetchSlotsInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final slots = <BookingSlot>[];
    final days = end.difference(start).inDays.clamp(1, 90);
    final sessionsPerDay = (12 + _random.nextInt(8)).clamp(8, 20);

    for (var d = 0; d < days; d++) {
      final day = start.add(Duration(days: d));
      for (var i = 0; i < sessionsPerDay; i++) {
        // P2P bias: spread across morning, midday, late night — away from peak
        final hour = _sampleOffPeakBiasedHour();
        final minute = _random.nextInt(60);
        slots.add(BookingSlot(
          slotStart: DateTime(day.year, day.month, day.day, hour, minute),
        ));
      }
    }

    return slots.where((s) => !s.slotStart.isBefore(start) && s.slotStart.isBefore(end)).toList();
  }

  int _sampleOffPeakBiasedHour() {
    final roll = _random.nextDouble();
    if (roll < 0.30) return _random.nextInt(6); // midnight–6 AM
    if (roll < 0.55) return 7 + _random.nextInt(4); // 7–10 AM
    if (roll < 0.75) return 11 + _random.nextInt(4); // 11 AM–2 PM
    if (roll < 0.88) return 14 + _random.nextInt(3); // 2–4 PM
    if (roll < 0.95) return 22 + _random.nextInt(2); // 10–11 PM
    return 18 + _random.nextInt(4); // some peak for contrast
  }
}
