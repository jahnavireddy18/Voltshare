import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vnest_app/core/enums/app_enums.dart';

/// Represents a charger listing on the VoltShare platform.
class ChargerModel {
  final String id;
  final String hostId;
  final String hostName;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final ChargerType chargerType;
  final ConnectorType connectorType;
  final double powerOutput; // kW
  final double pricePerKwh; // ₹/kWh
  final ChargerListingStatus status;
  final List<String> imageUrls;
  final double averageRating;
  final int reviewCount;
  final List<AvailabilitySlot> availability;
  final List<String> amenities;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChargerModel({
    required this.id,
    required this.hostId,
    this.hostName = '',
    required this.name,
    this.description = '',
    required this.address,
    required this.latitude,
    required this.longitude,
    this.chargerType = ChargerType.ac,
    this.connectorType = ConnectorType.type2,
    this.powerOutput = 7.2,
    this.pricePerKwh = 12.0,
    this.status = ChargerListingStatus.pendingApproval,
    this.imageUrls = const [],
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.availability = const [],
    this.amenities = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'hostId': hostId,
        'hostName': hostName,
        'name': name,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'chargerType': chargerType.name,
        'connectorType': connectorType.name,
        'powerOutput': powerOutput,
        'pricePerKwh': pricePerKwh,
        'status': status.name,
        'imageUrls': imageUrls,
        'averageRating': averageRating,
        'reviewCount': reviewCount,
        'availability': availability.map((a) => a.toJson()).toList(),
        'amenities': amenities,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory ChargerModel.fromJson(Map<String, dynamic> json) {
    return ChargerModel(
      id: json['id'] as String? ?? '',
      hostId: json['hostId'] as String? ?? '',
      hostName: json['hostName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      chargerType:
          ChargerType.fromString(json['chargerType'] as String? ?? 'ac'),
      connectorType: ConnectorType.fromString(
          json['connectorType'] as String? ?? 'type2'),
      powerOutput: (json['powerOutput'] as num?)?.toDouble() ?? 7.2,
      pricePerKwh: (json['pricePerKwh'] as num?)?.toDouble() ?? 12.0,
      status: ChargerListingStatus.fromString(
          json['status'] as String? ?? 'pendingApproval'),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      availability: (json['availability'] as List<dynamic>?)
              ?.map((a) => AvailabilitySlot.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      amenities: List<String>.from(json['amenities'] ?? []),
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
    );
  }

  factory ChargerModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    data['id'] = doc.id;
    return ChargerModel.fromJson(data);
  }

  ChargerModel copyWith({
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    ChargerType? chargerType,
    ConnectorType? connectorType,
    double? powerOutput,
    double? pricePerKwh,
    ChargerListingStatus? status,
    List<String>? imageUrls,
    double? averageRating,
    int? reviewCount,
    List<AvailabilitySlot>? availability,
    List<String>? amenities,
  }) {
    return ChargerModel(
      id: id,
      hostId: hostId,
      hostName: hostName,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      chargerType: chargerType ?? this.chargerType,
      connectorType: connectorType ?? this.connectorType,
      powerOutput: powerOutput ?? this.powerOutput,
      pricePerKwh: pricePerKwh ?? this.pricePerKwh,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      availability: availability ?? this.availability,
      amenities: amenities ?? this.amenities,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get powerLabel => '${powerOutput.toStringAsFixed(1)} kW';
  String get priceLabel => '₹${pricePerKwh.toStringAsFixed(0)}/kWh';
  String get ratingLabel =>
      averageRating > 0 ? averageRating.toStringAsFixed(1) : 'New';
  bool get isActive => status == ChargerListingStatus.active;

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}

/// A single availability window for a charger on a specific day.
class AvailabilitySlot {
  final DayOfWeek dayOfWeek;
  final String startTime; // HH:mm format
  final String endTime; // HH:mm format
  final bool isEnabled;

  const AvailabilitySlot({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek.index,
        'startTime': startTime,
        'endTime': endTime,
        'isEnabled': isEnabled,
      };

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      dayOfWeek: DayOfWeek.fromInt((json['dayOfWeek'] as num?)?.toInt() ?? 0),
      startTime: json['startTime'] as String? ?? '08:00',
      endTime: json['endTime'] as String? ?? '22:00',
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  /// Returns default 7-day availability (8 AM – 10 PM daily).
  static List<AvailabilitySlot> defaultWeekly() {
    return DayOfWeek.values
        .map((day) => AvailabilitySlot(
              dayOfWeek: day,
              startTime: '08:00',
              endTime: '22:00',
            ))
        .toList();
  }
}
