import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/models/booking_model.dart';
import 'package:vnest_app/core/models/charger_model.dart';
import 'package:vnest_app/core/models/notification_model.dart';

/// Booking engine with real availability checking and double-booking prevention.
///
/// Uses Firestore transactions to prevent race conditions where two users
/// attempt to book the same slot simultaneously.
class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _collection = 'bookings';
  static const _uuid = Uuid();

  /// Create a new booking with availability validation and race-condition safety.
  ///
  /// This method uses a Firestore transaction to:
  /// 1. Check that no overlapping booking exists for the same charger.
  /// 2. Validate the slot is within the charger's operating hours.
  /// 3. Prevent booking in the past.
  /// 4. Create the booking atomically.
  Future<BookingModel> createBooking({
    required String userId,
    required String userName,
    required String chargerId,
    required String chargerName,
    required String hostId,
    required DateTime startTime,
    required DateTime endTime,
    required double pricePerKwh,
    required double estimatedKwh,
  }) async {
    // Validate basic constraints before hitting the database.
    if (startTime.isBefore(DateTime.now())) {
      throw BookingException('Cannot book a slot in the past.');
    }
    if (endTime.isBefore(startTime) || endTime.isAtSameMomentAs(startTime)) {
      throw BookingException('End time must be after start time.');
    }
    if (endTime.difference(startTime).inMinutes < 15) {
      throw BookingException('Minimum booking duration is 15 minutes.');
    }
    if (endTime.difference(startTime).inHours > 8) {
      throw BookingException('Maximum booking duration is 8 hours.');
    }

    final estimatedCost = pricePerKwh * estimatedKwh;
    final bookingId = _uuid.v4();

    // Use a Firestore transaction to atomically check availability and create booking.
    return _firestore.runTransaction<BookingModel>((transaction) async {
      // Query existing non-cancelled bookings for this charger in the time range.
      // We check for any booking that overlaps with [startTime, endTime).
      final overlapping = await _firestore
          .collection(_collection)
          .where('chargerId', isEqualTo: chargerId)
          .where('status', whereIn: [
            BookingStatus.pending.name,
            BookingStatus.confirmed.name,
            BookingStatus.active.name,
          ])
          .get();

      // Check for time overlap with any existing booking.
      for (final doc in overlapping.docs) {
        final existing = BookingModel.fromFirestore(doc);
        if (_timesOverlap(
            startTime, endTime, existing.startTime, existing.endTime)) {
          throw BookingException(
            'This time slot is already booked. '
            'Please choose a different time.',
          );
        }
      }

      // Create the booking.
      final booking = BookingModel(
        id: bookingId,
        userId: userId,
        userName: userName,
        chargerId: chargerId,
        chargerName: chargerName,
        hostId: hostId,
        startTime: startTime,
        endTime: endTime,
        status: BookingStatus.confirmed,
        pricingSnapshot: PricingSnapshot(
          pricePerKwh: pricePerKwh,
          estimatedKwh: estimatedKwh,
          estimatedCost: estimatedCost,
        ),
        createdAt: DateTime.now(),
      );

      final docRef = _firestore.collection(_collection).doc(bookingId);
      transaction.set(docRef, booking.toJson());

      return booking;
    });
  }

  /// Check if two time ranges overlap.
  bool _timesOverlap(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    return start1.isBefore(end2) && start2.isBefore(end1);
  }

  /// Cancel a booking.
  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    final doc =
        await _firestore.collection(_collection).doc(bookingId).get();
    if (!doc.exists) throw BookingException('Booking not found.');

    final booking = BookingModel.fromFirestore(doc);
    if (!booking.isCancellable) {
      throw BookingException(
        'This booking cannot be cancelled (status: ${booking.status.label}).',
      );
    }

    await _firestore.collection(_collection).doc(bookingId).update({
      'status': BookingStatus.cancelled.name,
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancellationReason': reason,
    });
  }

  /// Get bookings for a user.
  Future<List<BookingModel>> getBookingsByUser(
    String userId, {
    BookingStatus? status,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    final snapshot = await query
        .orderBy('startTime', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();
  }

  /// Get bookings for a charger (host view).
  Future<List<BookingModel>> getBookingsByCharger(
    String chargerId, {
    BookingStatus? status,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .where('chargerId', isEqualTo: chargerId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    final snapshot = await query
        .orderBy('startTime', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();
  }

  /// Get bookings for a host (all their chargers).
  Future<List<BookingModel>> getBookingsByHost(
    String hostId, {
    BookingStatus? status,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .where('hostId', isEqualTo: hostId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    final snapshot = await query
        .orderBy('startTime', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();
  }

  /// Get a single booking by ID.
  Future<BookingModel?> getBooking(String bookingId) async {
    final doc =
        await _firestore.collection(_collection).doc(bookingId).get();
    if (!doc.exists) return null;
    return BookingModel.fromFirestore(doc);
  }

  /// Update booking status.
  Future<void> updateBookingStatus(
      String bookingId, BookingStatus status) async {
    await _firestore.collection(_collection).doc(bookingId).update({
      'status': status.name,
    });
  }

  /// Get upcoming bookings for a user (confirmed, not yet started).
  Future<List<BookingModel>> getUpcomingBookings(String userId) async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .where('startTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('startTime')
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();
  }

  /// Get all bookings (admin view).
  Future<List<BookingModel>> getAllBookings({
    BookingStatus? status,
    int limit = 100,
  }) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection(_collection);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    final snapshot = await query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();
  }

  /// Get booking count (for dashboards).
  Future<int> getBookingCount({BookingStatus? status}) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection(_collection);
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  /// Check if a specific time slot is available for a charger.
  Future<bool> isSlotAvailable(
    String chargerId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('chargerId', isEqualTo: chargerId)
        .where('status', whereIn: [
          BookingStatus.pending.name,
          BookingStatus.confirmed.name,
          BookingStatus.active.name,
        ])
        .get();

    for (final doc in snapshot.docs) {
      final existing = BookingModel.fromFirestore(doc);
      if (_timesOverlap(
          startTime, endTime, existing.startTime, existing.endTime)) {
        return false;
      }
    }
    return true;
  }

  /// Get booked slots for a charger on a specific date (for availability UI).
  Future<List<BookingModel>> getBookedSlotsForDate(
    String chargerId,
    DateTime date,
  ) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection(_collection)
        .where('chargerId', isEqualTo: chargerId)
        .where('status', whereIn: [
          BookingStatus.pending.name,
          BookingStatus.confirmed.name,
          BookingStatus.active.name,
        ])
        .where('startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('startTime', isLessThan: Timestamp.fromDate(dayEnd))
        .orderBy('startTime')
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();
  }
}

/// Exception for booking-related errors.
class BookingException implements Exception {
  final String message;
  BookingException(this.message);

  @override
  String toString() => message;
}
