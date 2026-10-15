import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing user favorite chargers.
class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _collection = 'favorites';

  /// Toggle a charger as favorite. Returns true if added, false if removed.
  Future<bool> toggleFavorite(String userId, String chargerId) async {
    final docId = '${userId}_$chargerId';
    final doc = await _firestore.collection(_collection).doc(docId).get();

    if (doc.exists) {
      await _firestore.collection(_collection).doc(docId).delete();
      return false;
    } else {
      await _firestore.collection(_collection).doc(docId).set({
        'userId': userId,
        'chargerId': chargerId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    }
  }

  /// Check if a charger is favorited by a user.
  Future<bool> isFavorite(String userId, String chargerId) async {
    final docId = '${userId}_$chargerId';
    final doc = await _firestore.collection(_collection).doc(docId).get();
    return doc.exists;
  }

  /// Get all favorite charger IDs for a user.
  Future<List<String>> getFavoriteChargerIds(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => doc.data()['chargerId'] as String)
        .toList();
  }
}
