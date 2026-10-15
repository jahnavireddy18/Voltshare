import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vnest_app/core/models/vehicle_model.dart';
import 'package:uuid/uuid.dart';

/// Service for managing user vehicles.
class VehicleService {
  static final VehicleService _instance = VehicleService._internal();
  factory VehicleService() => _instance;
  VehicleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _collection = 'vehicles';
  static const _uuid = Uuid();

  /// Add a vehicle for a user.
  Future<VehicleModel> addVehicle(VehicleModel vehicle) async {
    final id = _uuid.v4();
    final newVehicle = VehicleModel(
      id: id,
      userId: vehicle.userId,
      brand: vehicle.brand,
      model: vehicle.model,
      registrationNumber: vehicle.registrationNumber,
      connectorType: vehicle.connectorType,
      batteryCapacity: vehicle.batteryCapacity,
      createdAt: DateTime.now(),
    );

    await _firestore.collection(_collection).doc(id).set(newVehicle.toJson());
    return newVehicle;
  }

  /// Get all vehicles for a user.
  Future<List<VehicleModel>> getVehiclesByUser(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => VehicleModel.fromFirestore(doc))
        .toList();
  }

  /// Update a vehicle.
  Future<void> updateVehicle(
      String vehicleId, Map<String, dynamic> updates) async {
    await _firestore.collection(_collection).doc(vehicleId).update(updates);
  }

  /// Delete a vehicle.
  Future<void> deleteVehicle(String vehicleId) async {
    await _firestore.collection(_collection).doc(vehicleId).delete();
  }
}
