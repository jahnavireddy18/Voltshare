import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an audit log entry for admin/system actions.
class AuditLogModel {
  final String id;
  final String actorId;
  final String actorName;
  final String action;
  final String resourceType; // e.g., 'user', 'charger', 'booking'
  final String resourceId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
    required this.actorId,
    this.actorName = '',
    required this.action,
    required this.resourceType,
    required this.resourceId,
    this.metadata,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'actorId': actorId,
        'actorName': actorName,
        'action': action,
        'resourceType': resourceType,
        'resourceId': resourceId,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      actorName: json['actorName'] as String? ?? '',
      action: json['action'] as String? ?? '',
      resourceType: json['resourceType'] as String? ?? '',
      resourceId: json['resourceId'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }

  factory AuditLogModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    data['id'] = doc.id;
    return AuditLogModel.fromJson(data);
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
