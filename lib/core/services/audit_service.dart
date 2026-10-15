import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:vnest_app/core/models/audit_log_model.dart';

/// Service for recording audit logs of important actions.
class AuditService {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _collection = 'audit_logs';
  static const _uuid = Uuid();

  /// Log an action.
  Future<void> logAction({
    required String actorId,
    String actorName = '',
    required String action,
    required String resourceType,
    required String resourceId,
    Map<String, dynamic>? metadata,
  }) async {
    final id = _uuid.v4();
    final log = AuditLogModel(
      id: id,
      actorId: actorId,
      actorName: actorName,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      metadata: metadata,
      createdAt: DateTime.now(),
    );

    await _firestore.collection(_collection).doc(id).set(log.toJson());
  }

  /// Get audit logs with optional filters.
  Future<List<AuditLogModel>> getAuditLogs({
    String? actorId,
    String? resourceType,
    String? action,
    int limit = 100,
  }) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection(_collection);

    if (actorId != null) {
      query = query.where('actorId', isEqualTo: actorId);
    }
    if (resourceType != null) {
      query = query.where('resourceType', isEqualTo: resourceType);
    }
    if (action != null) {
      query = query.where('action', isEqualTo: action);
    }

    final snapshot = await query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => AuditLogModel.fromFirestore(doc))
        .toList();
  }
}
