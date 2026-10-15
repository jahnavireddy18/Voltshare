import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vnest_app/core/enums/app_enums.dart';

/// Represents a booking on the VoltShare platform.
class BookingModel {
  final String id;
  final String userId;
  final String userName;
  final String chargerId;
  final String chargerName;
  final String hostId;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final PricingSnapshot pricingSnapshot;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final double? finalCost;

  const BookingModel({
    required this.id,
    required this.userId,
    this.userName = '',
    required this.chargerId,
    this.chargerName = '',
    required this.hostId,
    required this.startTime,
    required this.endTime,
    this.status = BookingStatus.pending,
    required this.pricingSnapshot,
    required this.createdAt,
    this.cancelledAt,
    this.cancellationReason,
    this.finalCost,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'chargerId': chargerId,
        'chargerName': chargerName,
        'hostId': hostId,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'status': status.name,
        'pricingSnapshot': pricingSnapshot.toJson(),
        'createdAt': Timestamp.fromDate(createdAt),
        'cancelledAt':
            cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
        'cancellationReason': cancellationReason,
        'finalCost': finalCost,
      };

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      chargerId: json['chargerId'] as String? ?? '',
      chargerName: json['chargerName'] as String? ?? '',
      hostId: json['hostId'] as String? ?? '',
      startTime: _parseTimestamp(json['startTime']),
      endTime: _parseTimestamp(json['endTime']),
      status:
          BookingStatus.fromString(json['status'] as String? ?? 'pending'),
      pricingSnapshot: PricingSnapshot.fromJson(
          json['pricingSnapshot'] as Map<String, dynamic>? ?? {}),
      createdAt: _parseTimestamp(json['createdAt']),
      cancelledAt: json['cancelledAt'] != null
          ? _parseTimestamp(json['cancelledAt'])
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      finalCost: (json['finalCost'] as num?)?.toDouble(),
    );
  }

  factory BookingModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    data['id'] = doc.id;
    return BookingModel.fromJson(data);
  }

  BookingModel copyWith({
    BookingStatus? status,
    DateTime? cancelledAt,
    String? cancellationReason,
    double? finalCost,
  }) {
    return BookingModel(
      id: id,
      userId: userId,
      userName: userName,
      chargerId: chargerId,
      chargerName: chargerName,
      hostId: hostId,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      pricingSnapshot: pricingSnapshot,
      createdAt: createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      finalCost: finalCost ?? this.finalCost,
    );
  }

  /// Duration of the booking.
  Duration get duration => endTime.difference(startTime);

  /// Human-readable duration string.
  String get durationLabel {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  /// Whether this booking can be cancelled by the user.
  bool get isCancellable =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;

  /// Whether the booking start time is in the past.
  bool get isInPast => startTime.isBefore(DateTime.now());

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}

/// Immutable snapshot of pricing at booking time.
/// Prevents retroactive price changes from affecting past bookings.
class PricingSnapshot {
  final double pricePerKwh;
  final double estimatedKwh;
  final double estimatedCost;
  final double? surgeMultiplier;

  const PricingSnapshot({
    required this.pricePerKwh,
    required this.estimatedKwh,
    required this.estimatedCost,
    this.surgeMultiplier,
  });

  Map<String, dynamic> toJson() => {
        'pricePerKwh': pricePerKwh,
        'estimatedKwh': estimatedKwh,
        'estimatedCost': estimatedCost,
        'surgeMultiplier': surgeMultiplier,
      };

  factory PricingSnapshot.fromJson(Map<String, dynamic> json) {
    return PricingSnapshot(
      pricePerKwh: (json['pricePerKwh'] as num?)?.toDouble() ?? 0.0,
      estimatedKwh: (json['estimatedKwh'] as num?)?.toDouble() ?? 0.0,
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble() ?? 0.0,
      surgeMultiplier: (json['surgeMultiplier'] as num?)?.toDouble(),
    );
  }
}
