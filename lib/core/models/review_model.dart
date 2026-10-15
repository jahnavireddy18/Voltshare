import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user review of a charger after a completed booking.
class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final String chargerId;
  final String bookingId;
  final int rating; // 1-5
  final String comment;
  final bool isReported;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.userId,
    this.userName = '',
    this.userImageUrl,
    required this.chargerId,
    required this.bookingId,
    required this.rating,
    this.comment = '',
    this.isReported = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userImageUrl': userImageUrl,
        'chargerId': chargerId,
        'bookingId': bookingId,
        'rating': rating,
        'comment': comment,
        'isReported': isReported,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userImageUrl: json['userImageUrl'] as String?,
      chargerId: json['chargerId'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      isReported: json['isReported'] as bool? ?? false,
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }

  factory ReviewModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    data['id'] = doc.id;
    return ReviewModel.fromJson(data);
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
