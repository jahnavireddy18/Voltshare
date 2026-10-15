import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vnest_app/core/enums/app_enums.dart';

/// Represents a charging session associated with a booking.
class SessionModel {
  final String id;
  final String bookingId;
  final String userId;
  final String chargerId;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final double energyConsumed; // kWh
  final int durationSeconds;
  final SessionStatus status;
  final DateTime createdAt;

  const SessionModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.chargerId,
    this.startedAt,
    this.endedAt,
    this.energyConsumed = 0.0,
    this.durationSeconds = 0,
    this.status = SessionStatus.starting,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'userId': userId,
        'chargerId': chargerId,
        'startedAt':
            startedAt != null ? Timestamp.fromDate(startedAt!) : null,
        'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
        'energyConsumed': energyConsumed,
        'durationSeconds': durationSeconds,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      chargerId: json['chargerId'] as String? ?? '',
      startedAt: json['startedAt'] != null
          ? _parseTimestamp(json['startedAt'])
          : null,
      endedAt:
          json['endedAt'] != null ? _parseTimestamp(json['endedAt']) : null,
      energyConsumed:
          (json['energyConsumed'] as num?)?.toDouble() ?? 0.0,
      durationSeconds:
          (json['durationSeconds'] as num?)?.toInt() ?? 0,
      status:
          SessionStatus.fromString(json['status'] as String? ?? 'starting'),
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }

  factory SessionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    data['id'] = doc.id;
    return SessionModel.fromJson(data);
  }

  SessionModel copyWith({
    DateTime? startedAt,
    DateTime? endedAt,
    double? energyConsumed,
    int? durationSeconds,
    SessionStatus? status,
  }) {
    return SessionModel(
      id: id,
      bookingId: bookingId,
      userId: userId,
      chargerId: chargerId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      energyConsumed: energyConsumed ?? this.energyConsumed,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  /// Human-readable duration.
  String get durationLabel {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  bool get isActive => status == SessionStatus.active;

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
