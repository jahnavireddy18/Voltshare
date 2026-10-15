import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vnest_app/core/models/telemetry_models.dart';

abstract class TelemetryRepository {
  Stream<TelemetryReading> streamReadings({required String chargerId, int limit});
  Future<void> pushReading(TelemetryReading reading);
  Future<List<TelemetryReading>> fetchHistory({
    required String chargerId,
    required DateTime since,
    int limit = 100,
  });
}

class FirestoreTelemetryRepository implements TelemetryRepository {
  FirestoreTelemetryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _collection = 'telemetry';

  @override
  Stream<TelemetryReading> streamReadings({
    required String chargerId,
    int limit = 1,
  }) {
    return _firestore
        .collection(_collection)
        .where('chargerId', isEqualTo: chargerId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        throw TelemetryRepositoryException('No telemetry for charger $chargerId');
      }
      final doc = snapshot.docs.first;
      return TelemetryReading.fromFirestore(doc.data(), id: doc.id);
    });
  }

  @override
  Future<void> pushReading(TelemetryReading reading) async {
    await _firestore.collection(_collection).add({
      ...reading.toFirestore(),
      'timestamp': Timestamp.fromDate(reading.timestamp),
    });
  }

  @override
  Future<List<TelemetryReading>> fetchHistory({
    required String chargerId,
    required DateTime since,
    int limit = 100,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('chargerId', isEqualTo: chargerId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((d) => TelemetryReading.fromFirestore(d.data(), id: d.id))
        .toList()
        .reversed
        .toList();
  }
}

class TelemetryRepositoryException implements Exception {
  TelemetryRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}
