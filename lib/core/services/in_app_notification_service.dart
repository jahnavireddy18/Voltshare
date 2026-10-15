import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/models/notification_model.dart';

/// In-app notification service.
///
/// Stores notifications in Firestore for retrieval by the client.
/// Designed to be extended with email, SMS, and push notification
/// channels in the future.
class InAppNotificationService {
  static final InAppNotificationService _instance =
      InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _collection = 'notifications';
  static const _uuid = Uuid();

  /// Create an in-app notification.
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    final id = _uuid.v4();
    final notification = NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      data: data,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(_collection)
        .doc(id)
        .set(notification.toJson());
  }

  /// Get notifications for a user.
  Future<List<NotificationModel>> getNotifications(
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
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList();
  }

  /// Get unread notification count.
  Future<int> getUnreadCount(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Mark a notification as read.
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection(_collection)
        .doc(notificationId)
        .update({'read': true});
  }

  /// Mark all notifications as read for a user.
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Stream of unread count for real-time badge updates.
  Stream<int> watchUnreadCount(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // --- Convenience methods for common notification scenarios ---

  Future<void> notifyBookingConfirmed(
      String userId, String chargerName, String bookingId) async {
    await createNotification(
      userId: userId,
      type: NotificationType.bookingConfirmed,
      title: 'Booking Confirmed',
      message: 'Your booking at $chargerName has been confirmed.',
      data: {'bookingId': bookingId, 'action': 'view_booking'},
    );
  }

  Future<void> notifyBookingCancelled(
      String userId, String chargerName) async {
    await createNotification(
      userId: userId,
      type: NotificationType.bookingCancelled,
      title: 'Booking Cancelled',
      message: 'Your booking at $chargerName has been cancelled.',
    );
  }

  Future<void> notifySessionStarted(
      String userId, String chargerName) async {
    await createNotification(
      userId: userId,
      type: NotificationType.sessionStarted,
      title: 'Session Started',
      message: 'Your charging session at $chargerName has started.',
      data: {'action': 'open_session'},
    );
  }

  Future<void> notifySessionCompleted(
      String userId, String chargerName, double energyKwh) async {
    await createNotification(
      userId: userId,
      type: NotificationType.sessionCompleted,
      title: 'Session Completed',
      message:
          'Your charging session at $chargerName is complete. Energy: ${energyKwh.toStringAsFixed(1)} kWh.',
    );
  }

  Future<void> notifyNewReview(
      String hostId, String chargerName, int rating) async {
    await createNotification(
      userId: hostId,
      type: NotificationType.newReview,
      title: 'New Review',
      message: 'Your charger $chargerName received a $rating-star review.',
    );
  }
}
