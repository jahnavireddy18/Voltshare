import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vnest_app/core/enums/app_enums.dart';

/// Represents an in-app notification for a user.
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final bool read;
  final Map<String, dynamic>? data; // Action payload (e.g., bookingId)
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.read = false,
    this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'title': title,
        'message': message,
        'read': read,
        'data': data,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String? ?? 'system'),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }

  factory NotificationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    data['id'] = doc.id;
    return NotificationModel.fromJson(data);
  }

  NotificationModel copyWith({bool? read}) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      read: read ?? this.read,
      data: data,
      createdAt: createdAt,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
