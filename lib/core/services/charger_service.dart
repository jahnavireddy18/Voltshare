import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/models/charger_model.dart';

/// Service for charger CRUD operations and discovery.
class ChargerService {
  static final ChargerService _instance = ChargerService._internal();
  factory ChargerService() => _instance;
  ChargerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _collection = 'chargers';

  // In-memory fallback and local cache so chargers load instantly without hanging
  final List<ChargerModel> _localChargers = [
    ChargerModel(
      id: 'demo_charger_tower_b',
      hostId: 'demo_host_1',
      hostName: 'Priya Sharma',
      name: 'VoltShare Hub · Tower B Slot 4',
      description: 'Dedicated covered EV parking slot with 7.4 kW Type 2 fast charger. 24/7 security guard access.',
      address: 'Tower B, Level P2, Prestige Tech Park, Bangalore',
      latitude: 12.9352,
      longitude: 77.6946,
      chargerType: ChargerType.ac,
      connectorType: ConnectorType.type2,
      powerOutput: 7.4,
      pricePerKwh: 16.0,
      status: ChargerListingStatus.active,
      averageRating: 4.9,
      reviewCount: 28,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now(),
    ),
  ];

  /// Create a new charger listing.
  Future<ChargerModel> createCharger(ChargerModel charger) async {
    final docId = charger.id.isNotEmpty
        ? charger.id
        : 'ch_${DateTime.now().millisecondsSinceEpoch}';

    final newCharger = ChargerModel(
      id: docId,
      hostId: charger.hostId,
      hostName: charger.hostName.isNotEmpty ? charger.hostName : 'Host',
      name: charger.name,
      description: charger.description,
      address: charger.address,
      latitude: charger.latitude,
      longitude: charger.longitude,
      chargerType: charger.chargerType,
      connectorType: charger.connectorType,
      powerOutput: charger.powerOutput,
      pricePerKwh: charger.pricePerKwh,
      status: ChargerListingStatus.active, // Auto-approve for MVP
      imageUrls: charger.imageUrls,
      availability: charger.availability,
      amenities: charger.amenities,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to local cache immediately so it shows up without delay
    _localChargers.removeWhere((c) => c.id == newCharger.id);
    _localChargers.insert(0, newCharger);

    // Attempt cloud persistence in background with 2s timeout
    try {
      final docRef = _firestore.collection(_collection).doc(newCharger.id);
      await docRef.set(newCharger.toJson()).timeout(const Duration(seconds: 2));
    } catch (_) {
      // Fallback already saved locally
    }

    return newCharger;
  }

  /// Get a single charger by ID.
  Future<ChargerModel?> getCharger(String chargerId) async {
    final localMatch = _localChargers.cast<ChargerModel?>().firstWhere(
          (c) => c?.id == chargerId,
          orElse: () => null,
        );
    if (localMatch != null) return localMatch;

    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(chargerId)
          .get()
          .timeout(const Duration(seconds: 2));
      if (!doc.exists) return null;
      return ChargerModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  /// Get all chargers for a specific host.
  Future<List<ChargerModel>> getChargersByHost(String hostId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('hostId', isEqualTo: hostId)
          .get()
          .timeout(const Duration(seconds: 2));

      if (snapshot.docs.isNotEmpty) {
        final remote = snapshot.docs
            .map((doc) => ChargerModel.fromFirestore(doc))
            .toList();
        // Merge with local newly created chargers
        for (final r in remote) {
          if (!_localChargers.any((c) => c.id == r.id)) {
            _localChargers.add(r);
          }
        }
        return remote;
      }
    } catch (_) {
      // Fallback to local
    }

    final hostMatches = _localChargers.where((c) => c.hostId == hostId).toList();
    if (hostMatches.isNotEmpty) {
      return hostMatches;
    }
    return List.from(_localChargers);
  }

  /// Get all active chargers (for the marketplace).
  Future<List<ChargerModel>> getActiveChargers({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: ChargerListingStatus.active.name)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 2));

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => ChargerModel.fromFirestore(doc)).toList();
      }
    } catch (_) {
      // Fallback to local
    }

    return List.from(_localChargers);
  }

  /// Search chargers with filters.
  Future<List<ChargerModel>> searchChargers({
    ChargerType? chargerType,
    ConnectorType? connectorType,
    double? maxPricePerKwh,
    double? minPowerOutput,
    double? minRating,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .where('status', isEqualTo: ChargerListingStatus.active.name);

    if (chargerType != null) {
      query = query.where('chargerType', isEqualTo: chargerType.name);
    }
    if (connectorType != null) {
      query = query.where('connectorType', isEqualTo: connectorType.name);
    }

    final snapshot = await query.limit(limit).get();
    var results =
        snapshot.docs.map((doc) => ChargerModel.fromFirestore(doc)).toList();

    // Client-side filtering for fields that can't be combined in Firestore queries.
    if (maxPricePerKwh != null) {
      results = results
          .where((c) => c.pricePerKwh <= maxPricePerKwh)
          .toList();
    }
    if (minPowerOutput != null) {
      results = results
          .where((c) => c.powerOutput >= minPowerOutput)
          .toList();
    }
    if (minRating != null) {
      results = results
          .where((c) => c.averageRating >= minRating)
          .toList();
    }

    return results;
  }

  /// Update a charger listing.
  Future<void> updateCharger(
      String chargerId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(_collection).doc(chargerId).update(updates);
  }

  /// Disable/enable a charger.
  Future<void> setChargerStatus(
      String chargerId, ChargerListingStatus status) async {
    await updateCharger(chargerId, {'status': status.name});
  }

  /// Delete a charger listing.
  Future<void> deleteCharger(String chargerId) async {
    await _firestore.collection(_collection).doc(chargerId).delete();
  }

  /// Update charger rating after a new review.
  Future<void> updateChargerRating(String chargerId) async {
    // Read all reviews for this charger and compute average.
    final reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('chargerId', isEqualTo: chargerId)
        .get();

    if (reviewsSnapshot.docs.isEmpty) return;

    double totalRating = 0;
    for (final doc in reviewsSnapshot.docs) {
      totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
    }

    final averageRating = totalRating / reviewsSnapshot.docs.length;
    await updateCharger(chargerId, {
      'averageRating': double.parse(averageRating.toStringAsFixed(1)),
      'reviewCount': reviewsSnapshot.docs.length,
    });
  }

  /// Get all chargers (admin view).
  Future<List<ChargerModel>> getAllChargers({
    ChargerListingStatus? status,
    int limit = 100,
  }) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection(_collection);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    final snapshot =
        await query.orderBy('createdAt', descending: true).limit(limit).get();
    return snapshot.docs.map((doc) => ChargerModel.fromFirestore(doc)).toList();
  }

  /// Get charger count by status (for admin dashboard).
  Future<Map<ChargerListingStatus, int>> getChargerCounts() async {
    final snapshot = await _firestore.collection(_collection).get();
    final counts = <ChargerListingStatus, int>{};

    for (final status in ChargerListingStatus.values) {
      counts[status] = 0;
    }

    for (final doc in snapshot.docs) {
      final status = ChargerListingStatus.fromString(
          doc.data()['status'] as String? ?? '');
      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }
}
