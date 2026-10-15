/// Firestore schema models for the Society Admin Portal.
///
/// Collections:
///   societies/{societyId}
///     - name, address, buildings[]
///   societies/{societyId}/chargers/{chargerId}
///     - name, hostName, building, floor, status, totalKwh, totalEarnings
///   societies/{societyId}/sessions/{sessionId}
///     - userName, chargerName, chargerId, startTime, durationMinutes, costRupees, building, floor

enum ChargerStatus { online, offline, charging, maintenance }

enum UserRole { driver, host, societyAdmin }

class SocietyCharger {
  const SocietyCharger({
    required this.id,
    required this.name,
    required this.hostName,
    required this.building,
    required this.floor,
    required this.status,
    this.totalKwh = 0,
    this.totalEarnings = 0,
  });

  final String id;
  final String name;
  final String hostName;
  final String building;
  final int floor;
  final ChargerStatus status;
  final double totalKwh;
  final double totalEarnings;

  String get statusLabel => switch (status) {
    ChargerStatus.online => 'Online',
    ChargerStatus.offline => 'Offline',
    ChargerStatus.charging => 'Charging',
    ChargerStatus.maintenance => 'Maintenance',
  };
}

class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.userName,
    required this.chargerName,
    required this.startTime,
    required this.durationMinutes,
    required this.costRupees,
    required this.building,
    required this.floor,
    this.kwhUsed = 0,
  });

  final String id;
  final String userName;
  final String chargerName;
  final DateTime startTime;
  final int durationMinutes;
  final double costRupees;
  final String building;
  final int floor;
  final double kwhUsed;
}

class SocietyDashboardMetrics {
  const SocietyDashboardMetrics({
    required this.totalChargers,
    required this.totalSessions,
    required this.totalKwhShared,
    required this.totalEarningsDistributed,
    required this.onlineChargers,
    required this.chargingNow,
  });

  final int totalChargers;
  final int totalSessions;
  final double totalKwhShared;
  final double totalEarningsDistributed;
  final int onlineChargers;
  final int chargingNow;

  static const empty = SocietyDashboardMetrics(
    totalChargers: 0,
    totalSessions: 0,
    totalKwhShared: 0,
    totalEarningsDistributed: 0,
    onlineChargers: 0,
    chargingNow: 0,
  );
}

class DailyDataPoint {
  const DailyDataPoint({
    required this.date,
    required this.sessions,
    required this.revenue,
    required this.kwh,
  });

  final DateTime date;
  final int sessions;
  final double revenue;
  final double kwh;
}
