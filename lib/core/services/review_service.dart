import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:vnest_app/core/models/review_model.dart';
import 'package:vnest_app/core/services/charger_service.dart';

/// Service for managing charger reviews.
///
/// Enforces one-review-per-booking constraint and recalculates
/// charger ratings on each submission.
class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _collection = 'reviews';
  static const _uuid = Uuid();

  /// Submit a review for a completed booking.
  Future<ReviewModel> submitReview({
    required String userId,
    required String userName,
    String? userImageUrl,
    required String chargerId,
    required String bookingId,
    required int rating,
    String comment = '',
  }) async {
    if (rating < 1 || rating > 5) {
      throw ReviewException('Rating must be between 1 and 5.');
    }

    // Verify booking is completed.
    final bookingDoc =
        await _firestore.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) {
      throw ReviewException('Booking not found.');
    }
    if (bookingDoc.data()?['status'] != 'completed') {
      throw ReviewException('You can only review completed bookings.');
    }

    // Check for duplicate review.
    final existing = await _firestore
        .collection(_collection)
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw ReviewException('You have already reviewed this booking.');
    }

    final reviewId = _uuid.v4();
    final review = ReviewModel(
      id: reviewId,
      userId: userId,
      userName: userName,
      userImageUrl: userImageUrl,
      chargerId: chargerId,
      bookingId: bookingId,
      rating: rating,
      comment: comment.trim(),
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(_collection)
        .doc(reviewId)
        .set(review.toJson());

    // Update charger average rating.
    await ChargerService().updateChargerRating(chargerId);

    return review;
  }

  /// Get reviews for a charger.
  Future<List<ReviewModel>> getReviewsForCharger(
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
        .map((doc) => ReviewModel.fromFirestore(doc))
        .toList();
  }

  /// Get reviews by a user.
  Future<List<ReviewModel>> getReviewsByUser(
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
        .map((doc) => ReviewModel.fromFirestore(doc))
        .toList();
  }

  /// Report a review.
  Future<void> reportReview(String reviewId) async {
    await _firestore.collection(_collection).doc(reviewId).update({
      'isReported': true,
    });
  }

  /// Delete a review (admin only).
  Future<void> deleteReview(String reviewId) async {
    final doc =
        await _firestore.collection(_collection).doc(reviewId).get();
    if (!doc.exists) return;

    final chargerId = doc.data()?['chargerId'] as String?;
    await _firestore.collection(_collection).doc(reviewId).delete();

    // Recalculate charger rating.
    if (chargerId != null) {
      await ChargerService().updateChargerRating(chargerId);
    }
  }

  /// Get reported reviews (admin view).
  Future<List<ReviewModel>> getReportedReviews({int limit = 50}) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('isReported', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ReviewModel.fromFirestore(doc))
        .toList();
  }

  /// Check if a user has already reviewed a booking.
  Future<bool> hasReviewedBooking(String bookingId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}

class ReviewException implements Exception {
  final String message;
  ReviewException(this.message);

  @override
  String toString() => message;
}
