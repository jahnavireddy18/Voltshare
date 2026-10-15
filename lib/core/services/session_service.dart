import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/models/session_model.dart';

/// Service for managing charging session lifecycle.
///
/// In this version, energy consumption is simulated. The architecture
/// is designed so a real charger/IoT integration can replace the
/// simulation layer without changing the session data model or API.
class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _collection = 'sessions';
  static const _uuid = Uuid();

  /// Start a new charging session for a confirmed booking.
  Future<SessionModel> startSession({
    required String bookingId,
    required String userId,
    required String chargerId,
  }) async {
    // Verify booking status.
    final bookingDoc =
        await _firestore.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) {
      throw SessionException('Booking not found.');
    }

    final bookingStatus = bookingDoc.data()?['status'] as String?;
    if (bookingStatus != BookingStatus.confirmed.name &&
        bookingStatus != BookingStatus.active.name) {
      throw SessionException(
        'Cannot start session — booking is not confirmed.',
      );
    }

    // Check for existing active session for this booking.
    final existingSession = await _firestore
        .collection(_collection)
        .where('bookingId', isEqualTo: bookingId)
        .where('status', isEqualTo: SessionStatus.active.name)
        .limit(1)
        .get();

    if (existingSession.docs.isNotEmpty) {
      throw SessionException('A session is already active for this booking.');
    }

    final sessionId = _uuid.v4();
    final now = DateTime.now();

    final session = SessionModel(
      id: sessionId,
      bookingId: bookingId,
      userId: userId,
      chargerId: chargerId,
      startedAt: now,
      status: SessionStatus.active,
      createdAt: now,
    );

    // Create session and update booking status atomically.
    final batch = _firestore.batch();
    batch.set(_firestore.collection(_collection).doc(sessionId),
        session.toJson());
    batch.update(_firestore.collection('bookings').doc(bookingId), {
      'status': BookingStatus.active.name,
    });
    await batch.commit();

    return session;
  }

  /// End an active charging session.
  Future<SessionModel> endSession(
    String sessionId, {
    double energyConsumed = 0.0,
  }) async {
    final doc =
        await _firestore.collection(_collection).doc(sessionId).get();
    if (!doc.exists) throw SessionException('Session not found.');

    final session = SessionModel.fromFirestore(doc);
    if (session.status != SessionStatus.active) {
      throw SessionException('Session is not active.');
    }

    final now = DateTime.now();
    final durationSeconds =
        now.difference(session.startedAt ?? now).inSeconds;

    // If no energy value provided, simulate based on duration.
    // Approximate: 7.2 kW charger at ~90% efficiency.
    final energy = energyConsumed > 0
        ? energyConsumed
        : (7.2 * 0.9 * durationSeconds / 3600);

    final updates = {
      'endedAt': Timestamp.fromDate(now),
      'energyConsumed': double.parse(energy.toStringAsFixed(2)),
      'durationSeconds': durationSeconds,
      'status': SessionStatus.completed.name,
    };

    // Update session and booking status atomically.
    final batch = _firestore.batch();
    batch.update(
        _firestore.collection(_collection).doc(sessionId), updates);

    // Calculate final cost and save it to the booking
    final bookingDocRef = _firestore.collection('bookings').doc(session.bookingId);
    final bookingDoc = await bookingDocRef.get();
    if (bookingDoc.exists) {
      final bookingData = bookingDoc.data()!;
      final pricingSnapshot = bookingData['pricingSnapshot'] as Map<String, dynamic>?;
      if (pricingSnapshot != null) {
        final pricePerKwh = (pricingSnapshot['pricePerKwh'] as num).toDouble();
        final finalCost = energy * pricePerKwh;
        batch.update(bookingDocRef, {
          'status': BookingStatus.completed.name,
          'finalCost': finalCost,
        });
      } else {
        batch.update(bookingDocRef, {
          'status': BookingStatus.completed.name,
        });
      }
    } else {
      batch.update(bookingDocRef, {
        'status': BookingStatus.completed.name,
      });
    }

    await batch.commit();

    return session.copyWith(
      endedAt: now,
      energyConsumed: energy,
      durationSeconds: durationSeconds,
      status: SessionStatus.completed,
    );
  }

  /// Get active session for a user (if any).
  Future<SessionModel?> getActiveSession(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: SessionStatus.active.name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return SessionModel.fromFirestore(snapshot.docs.first);
  }

  /// Get session history for a user.
  Future<List<SessionModel>> getSessionHistory(
    String userId, {
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => SessionModel.fromFirestore(doc))
        .toList();
  }

  /// Get session by booking ID.
  Future<SessionModel?> getSessionByBooking(String bookingId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return SessionModel.fromFirestore(snapshot.docs.first);
  }

  /// Get sessions for a charger (host view).
  Future<List<SessionModel>> getSessionsByCharger(
    String chargerId, {
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('chargerId', isEqualTo: chargerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => SessionModel.fromFirestore(doc))
        .toList();
  }

  /// Get all sessions (admin view).
  Future<List<SessionModel>> getAllSessions({
    SessionStatus? status,
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
        .map((doc) => SessionModel.fromFirestore(doc))
        .toList();
  }

  /// Get a single session by ID.
  Future<SessionModel?> getSession(String sessionId) async {
    final doc =
        await _firestore.collection(_collection).doc(sessionId).get();
    if (!doc.exists) return null;
    return SessionModel.fromFirestore(doc);
  }
}

/// Exception for session-related errors.
class SessionException implements Exception {
  final String message;
  SessionException(this.message);

  @override
  String toString() => message;
}
