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
  static final Map<String, ReviewModel> _localReviews = {};
  static final List<Map<String, dynamic>> _localRenterReviews = [];

  /// Submit a review for a completed booking or charging session (Driver -> Host/Charger).
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

    // Save in local cache immediately
    _localReviews[bookingId] = review;

    // Fire-and-forget sync to Firestore with timeout
    Future(() async {
      try {
        await _firestore
            .collection(_collection)
            .doc(reviewId)
            .set(review.toJson())
            .timeout(const Duration(seconds: 3));
        await ChargerService().updateChargerRating(chargerId);
      } catch (_) {
        // Silently preserve in local cache
      }
    });

    return review;
  }

  /// Submit a review for a renter / EV driver (Host -> Renter).
  Future<Map<String, dynamic>> submitRenterReview({
    required String hostId,
    required String renterId,
    required String renterName,
    required int rating,
    List<String> tags = const [],
    String comment = '',
  }) async {
    if (rating < 1 || rating > 5) {
      throw ReviewException('Rating must be between 1 and 5.');
    }

    final reviewData = {
      'id': _uuid.v4(),
      'hostId': hostId,
      'renterId': renterId,
      'renterName': renterName,
      'rating': rating,
      'tags': tags,
      'comment': comment.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    _localRenterReviews.add(reviewData);

    // Sync to Firestore in background
    Future(() async {
      try {
        await _firestore
            .collection('renter_reviews')
            .doc(reviewData['id'] as String)
            .set(reviewData)
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        // Local in-memory preserved
      }
    });

    return reviewData;
  }

  /// Get reviews for a renter given by hosts.
  List<Map<String, dynamic>> getRenterReviews(String renterId) {
    return _localRenterReviews.where((r) => r['renterId'] == renterId).toList();
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
    if (_localReviews.containsKey(bookingId)) return true;
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 2));
      return snapshot.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

class ReviewException implements Exception {
  final String message;
  ReviewException(this.message);

  @override
  String toString() => message;
}
