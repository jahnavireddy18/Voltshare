import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vnest_app/core/models/society_admin_models.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/services/society_admin_service.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class SocietyAdminDashboardScreen extends StatefulWidget {
  const SocietyAdminDashboardScreen({super.key});

  @override
  State<SocietyAdminDashboardScreen> createState() => _SocietyAdminDashboardScreenState();
}

class _SocietyAdminDashboardScreenState extends State<SocietyAdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _service = SocietyAdminService();
  late TabController _tabController;

  SocietyDashboardMetrics _metrics = SocietyDashboardMetrics.empty;
  List<SocietyCharger> _chargers = [];
  List<SessionRecord> _sessions = [];
  List<DailyDataPoint> _dailyTrend = [];
  bool _loading = true;

  // Filters
  String? _buildingFilter;
  int? _floorFilter;
  int _chartMode = 0; // 0=sessions, 1=revenue, 2=energy

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _service.getMetrics(),
      _service.getChargers(building: _buildingFilter, floor: _floorFilter),
      _service.getSessions(building: _buildingFilter, floor: _floorFilter),
      _service.getDailyTrend(),
    ]);
    if (mounted) {
      setState(() {
        _metrics = results[0] as SocietyDashboardMetrics;
        _chargers = results[1] as List<SocietyCharger>;
        _sessions = results[2] as List<SessionRecord>;
        _dailyTrend = results[3] as List<DailyDataPoint>;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Column(
          children: [
            Text('SOCIETY ADMIN', style: GoogleFonts.jetBrainsMono(
              fontSize: 10, color: AppColors.textSecondary, letterSpacing: 2,
            )),
            Text('GreenVille Residency', style: GoogleFonts.sora(
              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
            )),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: Text('READ ONLY', style: GoogleFonts.jetBrainsMono(
              fontSize: 9, color: AppColors.secondary,
            )),
          ),
          IconButton(
            key: const Key('admin_logout_button'),
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () => AuthProvider.showLogoutDialog(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Chargers'),
            Tab(text: 'Sessions'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildChargersTab(),
                _buildSessionsTab(),
              ],
            ),
    );
  }

  // ──────────── OVERVIEW TAB ────────────

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceDark,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterRow(),
            const SizedBox(height: 20),
            _buildMetricsGrid(),
            const SizedBox(height: 24),
            _buildChartSection(),
            const SizedBox(height: 24),
            _buildRecentSessions(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _buildingFilter,
                isExpanded: true,
                dropdownColor: AppColors.surfaceDark,
                hint: Text('All Buildings', style: GoogleFonts.manrope(color: AppColors.textSecondary, fontSize: 13)),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text('All Buildings', style: GoogleFonts.manrope(color: Colors.white, fontSize: 13))),
                  ..._service.buildings.map((b) => DropdownMenuItem(value: b, child: Text(b, style: GoogleFonts.manrope(color: Colors.white, fontSize: 13)))),
                ],
                onChanged: (val) { setState(() => _buildingFilter = val); _load(); },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _floorFilter,
                isExpanded: true,
                dropdownColor: AppColors.surfaceDark,
                hint: Text('All Floors', style: GoogleFonts.manrope(color: AppColors.textSecondary, fontSize: 13)),
                items: [
                  DropdownMenuItem<int?>(value: null, child: Text('All Floors', style: GoogleFonts.manrope(color: Colors.white, fontSize: 13))),
                  ...List.generate(4, (i) => DropdownMenuItem(value: i + 1, child: Text('Floor ${i + 1}', style: GoogleFonts.manrope(color: Colors.white, fontSize: 13)))),
                ],
                onChanged: (val) { setState(() => _floorFilter = val); _load(); },
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _metricCard('TOTAL CHARGERS', _metrics.totalChargers.toString(), Icons.ev_station, AppColors.primary, subtitle: '${_metrics.onlineChargers} online')),
          const SizedBox(width: 12),
          Expanded(child: _metricCard('TOTAL SESSIONS', _metrics.totalSessions.toString(), Icons.history, AppColors.secondary)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _metricCard('kWh SHARED', _metrics.totalKwhShared.toStringAsFixed(0), Icons.bolt, AppColors.warning)),
          const SizedBox(width: 12),
          Expanded(child: _metricCard('EARNINGS', '₹${_metrics.totalEarningsDistributed.toStringAsFixed(0)}', Icons.account_balance_wallet, AppColors.primary, subtitle: 'Distributed')),
        ]),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _metricCard(String label, String value, IconData icon, Color accent, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.textSecondary, letterSpacing: 1))),
          ]),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    final chartLabels = ['Sessions', 'Revenue', 'Energy'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TREND (14 DAYS)', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 2)),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: chartLabels.asMap().entries.map((e) {
                  final selected = _chartMode == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _chartMode = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(e.value, style: GoogleFonts.manrope(
                        fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? AppColors.primary : AppColors.textSecondary,
                      )),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: SizedBox(height: 200, child: _buildLineChart()),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildLineChart() {
    if (_dailyTrend.isEmpty) {
      return Center(child: Text('No data', style: GoogleFonts.manrope(color: AppColors.textSecondary)));
    }

    final spots = _dailyTrend.asMap().entries.map((e) {
      final v = switch (_chartMode) {
        0 => e.value.sessions.toDouble(),
        1 => e.value.revenue,
        _ => e.value.kwh,
      };
      return FlSpot(e.key.toDouble(), v);
    }).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2;
    final color = switch (_chartMode) {
      0 => AppColors.primary,
      1 => AppColors.warning,
      _ => AppColors.secondary,
    };

    return LineChart(LineChartData(
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (v) => FlLine(color: AppColors.borderDark, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 36, interval: maxY / 4,
          getTitlesWidget: (v, _) => Text(
            _chartMode == 1 ? '₹${v.toInt()}' : v.toInt().toString(),
            style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.textMuted),
          ),
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 28, interval: 3,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= _dailyTrend.length) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(DateFormat('d/M').format(_dailyTrend[i].date),
                style: GoogleFonts.jetBrainsMono(fontSize: 8, color: AppColors.textMuted)),
            );
          },
        )),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true, curveSmoothness: 0.25,
          color: color, barWidth: 2.5,
          dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
            FlDotCirclePainter(radius: 3, color: color, strokeWidth: 0)),
          belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.surfaceVariantDark,
          getTooltipItems: (spots) => spots.map((s) {
            final prefix = _chartMode == 1 ? '₹' : '';
            final suffix = _chartMode == 2 ? ' kWh' : (_chartMode == 0 ? ' sessions' : '');
            return LineTooltipItem('$prefix${s.y.toStringAsFixed(0)}$suffix',
              GoogleFonts.manrope(color: color, fontSize: 11, fontWeight: FontWeight.w600));
          }).toList(),
        ),
      ),
    ));
  }

  Widget _buildRecentSessions() {
    final recent = _sessions.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECENT SESSIONS', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 2)),
        const SizedBox(height: 12),
        ...recent.asMap().entries.map((e) => _sessionTile(e.value, e.key)),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _sessionTile(SessionRecord s, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Center(child: Text(s.userName[0], style: GoogleFonts.sora(color: AppColors.primary, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.userName, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              Text('${s.chargerName} · ${s.building}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
            ],
          )),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${s.costRupees.toStringAsFixed(0)}', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('${s.durationMinutes}m', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (100 + index * 60).ms).slideX(begin: 0.05);
  }

  // ──────────── CHARGERS TAB ────────────

  Widget _buildChargersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _chargers.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return _buildFilterRow().animate().fadeIn();
        final charger = _chargers[i - 1];
        return _chargerCard(charger, i - 1);
      },
    );
  }

  Widget _chargerCard(SocietyCharger c, int index) {
    final statusColor = switch (c.status) {
      ChargerStatus.online => AppColors.primary,
      ChargerStatus.charging => AppColors.secondary,
      ChargerStatus.offline => AppColors.textMuted,
      ChargerStatus.maintenance => AppColors.warning,
    };

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
            ),
            const SizedBox(width: 8),
            Text(c.statusLabel.toUpperCase(), style: GoogleFonts.jetBrainsMono(fontSize: 10, color: statusColor, letterSpacing: 1)),
            const Spacer(),
            Text('${c.building} · F${c.floor}', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 12),
          Text(c.name, style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Host: ${c.hostName}', style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.borderDark),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _chargerStat('kWh', c.totalKwh.toStringAsFixed(0)),
              _chargerStat('Earned', '₹${c.totalEarnings.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (100 + index * 60).ms).slideY(begin: 0.05);
  }

  Widget _chargerStat(String label, String value) {
    return Column(children: [
      Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.textMuted, letterSpacing: 1)),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
    ]);
  }

  // ──────────── SESSIONS TAB ────────────

  Widget _buildSessionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: _buildFilterRow(),
        ),
        const SizedBox(height: 12),
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: AppColors.surfaceDark,
          child: Row(children: [
            Expanded(flex: 3, child: Text('USER', style: _tableHeader)),
            Expanded(flex: 3, child: Text('CHARGER', style: _tableHeader)),
            Expanded(flex: 2, child: Text('TIME', style: _tableHeader)),
            Expanded(flex: 1, child: Text('DUR', style: _tableHeader)),
            Expanded(flex: 2, child: Text('COST', style: _tableHeader)),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _sessions.length,
            itemBuilder: (context, i) => _sessionRow(_sessions[i], i),
          ),
        ),
      ],
    );
  }

  TextStyle get _tableHeader => GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.textSecondary, letterSpacing: 1);

  Widget _sessionRow(SessionRecord s, int index) {
    final timeStr = DateFormat('MMM d, HH:mm').format(s.startTime);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderDark))),
      child: Row(children: [
        Expanded(flex: 3, child: Text(s.userName, style: GoogleFonts.manrope(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600))),
        Expanded(flex: 3, child: Text(s.chargerName, style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text(timeStr, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.textMuted))),
        Expanded(flex: 1, child: Text('${s.durationMinutes}m', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('₹${s.costRupees.toStringAsFixed(0)}', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
      ]),
    );
  }
}
