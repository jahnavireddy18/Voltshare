import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vnest_app/core/enums/app_enums.dart';

/// Represents an EV vehicle owned by a user.
class VehicleModel {
  final String id;
  final String userId;
  final String brand;
  final String model;
  final String registrationNumber;
  final ConnectorType connectorType;
  final double batteryCapacity; // kWh
  final DateTime createdAt;

  const VehicleModel({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    this.registrationNumber = '',
    this.connectorType = ConnectorType.type2,
    this.batteryCapacity = 40.0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'brand': brand,
        'model': model,
        'registrationNumber': registrationNumber,
        'connectorType': connectorType.name,
        'batteryCapacity': batteryCapacity,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      connectorType:
          ConnectorType.fromString(json['connectorType'] as String? ?? 'type2'),
      batteryCapacity: (json['batteryCapacity'] as num?)?.toDouble() ?? 40.0,
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }

  factory VehicleModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    data['id'] = doc.id;
    return VehicleModel.fromJson(data);
  }

  VehicleModel copyWith({
    String? brand,
    String? model,
    String? registrationNumber,
    ConnectorType? connectorType,
    double? batteryCapacity,
  }) {
    return VehicleModel(
      id: id,
      userId: userId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      connectorType: connectorType ?? this.connectorType,
      batteryCapacity: batteryCapacity ?? this.batteryCapacity,
      createdAt: createdAt,
    );
  }

  String get displayName => '$brand $model';

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
