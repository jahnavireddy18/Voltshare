import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vnest_app/core/models/grid_load_models.dart';
import 'package:vnest_app/core/services/grid_analytics_service.dart';
import 'package:vnest_app/core/theme/app_theme.dart';
import 'package:vnest_app/widgets/charts/grid_load_chart.dart';
import 'package:vnest_app/widgets/charts/metric_card.dart';

class GridLoadDashboardScreen extends StatefulWidget {
  const GridLoadDashboardScreen({
    super.key,
    required this.analytics,
  });

  final GridAnalyticsService analytics;

  @override
  State<GridLoadDashboardScreen> createState() => _GridLoadDashboardScreenState();
}

class _GridLoadDashboardScreenState extends State<GridLoadDashboardScreen> {
  GridLoadView _view = GridLoadView.weekly;
  GridLoadMetrics? _metrics;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final metrics = await widget.analytics.loadDashboard(view: _view);
      if (mounted) setState(() { _metrics = metrics; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onViewChanged(GridLoadView view) {
    if (_view == view) return;
    setState(() => _view = view);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: cs.surfaceContainer,
          onRefresh: () async {
            widget.analytics.clearCache();
            await _load();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildViewSelector()),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildError(),
                )
              else if (_metrics != null)
                SliverToBoxAdapter(child: _buildContent(_metrics!)),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grid Load',
            style: GoogleFonts.sora(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How P2P charging shifts demand off peak hours',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildViewSelector() {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: GridLoadView.values.map((view) {
            final selected = _view == view;
            return Expanded(
              child: GestureDetector(
                onTap: () => _onViewChanged(view),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: selected
                        ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Text(
                    _viewLabel(view),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primary : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildContent(GridLoadMetrics metrics) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRange(metrics),
          const SizedBox(height: 20),
          _buildMetricsGrid(metrics),
          const SizedBox(height: 20),
          InsightsCard(
            message: metrics.insightMessage,
            percentageShifted: metrics.percentageShifted,
          ),
          const SizedBox(height: 24),
          Text(
            'LOAD DISTRIBUTION',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: cs.onSurfaceVariant,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _chartSubtitle(metrics),
            style: GoogleFonts.manrope(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: GridLoadChart(metrics: metrics),
          ),
          const SizedBox(height: 12),
          _buildSourceBadge(metrics),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildDateRange(GridLoadMetrics metrics) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('MMM d');
    final range = '${fmt.format(metrics.rangeStart)} – ${fmt.format(metrics.rangeEnd.subtract(const Duration(days: 1)))}';
    return Text(
      range,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        color: cs.onSurfaceVariant,
      ),
    );
  }

  Widget _buildMetricsGrid(GridLoadMetrics metrics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'TOTAL SESSIONS',
                value: metrics.totalSessions.toString(),
                icon: Icons.ev_station,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: '% SHIFTED',
                value: '${metrics.percentageShifted.round()}%',
                icon: Icons.swap_horiz,
                accentColor: AppColors.primary,
                subtitle: 'Off-peak share',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'PEAK (6–10 PM)',
                value: metrics.peakHourSessions.toString(),
                icon: Icons.trending_up,
                accentColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: 'OFF-PEAK',
                value: metrics.offPeakSessions.toString(),
                icon: Icons.nightlight_round,
                accentColor: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSourceBadge(GridLoadMetrics metrics) {
    final cs = Theme.of(context).colorScheme;
    final isDemo = metrics.source == 'demo';

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Text(
          isDemo ? 'Demo data — connect Firestore for live metrics' : 'Live Firestore data',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: cs.onSurfaceVariant, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load grid data',
              style: GoogleFonts.manrope(color: cs.onSurface, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _viewLabel(GridLoadView view) {
    switch (view) {
      case GridLoadView.daily:
        return 'Daily';
      case GridLoadView.weekly:
        return 'Weekly';
      case GridLoadView.monthly:
        return 'Monthly';
    }
  }

  String _chartSubtitle(GridLoadMetrics metrics) {
    switch (metrics.view) {
      case GridLoadView.daily:
        return 'Hourly session distribution vs traditional 6–10 PM baseline';
      case GridLoadView.weekly:
        return 'Daily sessions vs peak-concentrated baseline';
      case GridLoadView.monthly:
        return 'Monthly daily trend — P2P vs traditional charging pattern';
    }
  }
}
