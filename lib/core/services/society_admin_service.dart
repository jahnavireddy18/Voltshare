import 'dart:math';

import 'package:vnest_app/core/models/society_admin_models.dart';

/// Provides demo data for the Society Admin portal.
/// In production, this would read from Firestore collections:
///   societies/{id}/chargers and societies/{id}/sessions
class SocietyAdminService {
  SocietyAdminService({Random? random}) : _random = random ?? Random(42);

  final Random _random;

  List<SocietyCharger>? _chargers;
  List<SessionRecord>? _sessions;

  static const _buildings = ['Tower A', 'Tower B', 'Tower C'];
  static const _hosts = ['Rajesh K.', 'Priya M.', 'Anil S.', 'Deepa R.', 'Vikram T.', 'Sonal P.'];
  static const _users = ['Maya S.', 'Arjun D.', 'Neha K.', 'Rohan P.', 'Kavita G.', 'Suresh L.', 'Meera V.', 'Amit B.'];
  static const _chargerNames = [
    'Tesla Wall Connector', 'Tata EZ Charge', 'Ather Grid',
    'ABB Terra AC', 'Delta AC Mini', 'Exicom Harmony',
    'Okaya Faast', 'Servotech Level 2',
  ];

  Future<List<SocietyCharger>> getChargers({String? building, int? floor}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _chargers ??= _generateChargers();
    var result = _chargers!;
    if (building != null) result = result.where((c) => c.building == building).toList();
    if (floor != null) result = result.where((c) => c.floor == floor).toList();
    return result;
  }

  Future<List<SessionRecord>> getSessions({
    String? building,
    int? floor,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _sessions ??= _generateSessions();
    var result = _sessions!;
    if (building != null) result = result.where((s) => s.building == building).toList();
    if (floor != null) result = result.where((s) => s.floor == floor).toList();
    if (startDate != null) result = result.where((s) => !s.startTime.isBefore(startDate)).toList();
    if (endDate != null) result = result.where((s) => s.startTime.isBefore(endDate)).toList();
    return result;
  }

  Future<SocietyDashboardMetrics> getMetrics() async {
    final chargers = await getChargers();
    final sessions = await getSessions();
    return SocietyDashboardMetrics(
      totalChargers: chargers.length,
      totalSessions: sessions.length,
      totalKwhShared: sessions.fold(0.0, (sum, s) => sum + s.kwhUsed),
      totalEarningsDistributed: sessions.fold(0.0, (sum, s) => sum + s.costRupees),
      onlineChargers: chargers.where((c) => c.status == ChargerStatus.online || c.status == ChargerStatus.charging).length,
      chargingNow: chargers.where((c) => c.status == ChargerStatus.charging).length,
    );
  }

  Future<List<DailyDataPoint>> getDailyTrend({int days = 14}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    return List.generate(days, (i) {
      final date = DateTime(now.year, now.month, now.day - (days - 1 - i));
      final sessions = 8 + _random.nextInt(12);
      final kwh = sessions * (3.5 + _random.nextDouble() * 4);
      final revenue = kwh * (8 + _random.nextDouble() * 4);
      return DailyDataPoint(date: date, sessions: sessions, revenue: revenue, kwh: kwh);
    });
  }

  List<String> get buildings => _buildings.toList();

  List<SocietyCharger> _generateChargers() {
    final statuses = ChargerStatus.values;
    return List.generate(8, (i) {
      return SocietyCharger(
        id: 'charger_${i + 1}',
        name: _chargerNames[i % _chargerNames.length],
        hostName: _hosts[i % _hosts.length],
        building: _buildings[i % _buildings.length],
        floor: (i % 4) + 1,
        status: i < 3 ? ChargerStatus.charging : (i < 6 ? ChargerStatus.online : statuses[_random.nextInt(statuses.length)]),
        totalKwh: 120 + _random.nextDouble() * 400,
        totalEarnings: 1800 + _random.nextDouble() * 6000,
      );
    });
  }

  List<SessionRecord> _generateSessions() {
    final now = DateTime.now();
    return List.generate(50, (i) {
      final daysAgo = _random.nextInt(14);
      final hour = 6 + _random.nextInt(16);
      final minute = _random.nextInt(60);
      final duration = 15 + _random.nextInt(90);
      final kwh = 2.0 + _random.nextDouble() * 8;
      return SessionRecord(
        id: 'session_${i + 1}',
        userName: _users[_random.nextInt(_users.length)],
        chargerName: _chargerNames[_random.nextInt(_chargerNames.length)],
        startTime: DateTime(now.year, now.month, now.day - daysAgo, hour, minute),
        durationMinutes: duration,
        costRupees: kwh * (8 + _random.nextDouble() * 4),
        building: _buildings[_random.nextInt(_buildings.length)],
        floor: 1 + _random.nextInt(4),
        kwhUsed: kwh,
      );
    })..sort((a, b) => b.startTime.compareTo(a.startTime));
  }
}
