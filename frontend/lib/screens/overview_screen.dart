// lib/screens/overview_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';

class OverviewScreen extends StatefulWidget {
  final String userId;
  const OverviewScreen({super.key, required this.userId});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen>
    with SingleTickerProviderStateMixin {
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end:   DateTime.now(),
  );

  List<_ActivityStat> _stats    = [];
  Map<String, dynamic> _summary = {};
  bool _loading = false;
  late TabController _tabCtrl;

  // Activity colour palette
  static const Map<String, Color> _palette = {
    'sleep':     Color(0xFF5C6BC0),
    'work':      Color(0xFF26C6DA),
    'study':     Color(0xFF66BB6A),
    'gym':       Color(0xFFFF7043),
    'breakfast': Color(0xFFFFCA28),
    'lunch':     Color(0xFFFFA726),
    'dinner':    Color(0xFFEF5350),
    'rest':      Color(0xFFAB47BC),
    'leisure':   Color(0xFF26A69A),
    'meeting':   Color(0xFF42A5F5),
    'reminder':  Color(0xFFEC407A),
    'note':      Color(0xFF8D6E63),
    'other':     Color(0xFF78909C),
  };

  Color _colorFor(String label) {
    final k = label.toLowerCase();
    for (final entry in _palette.entries) {
      if (k.contains(entry.key)) return entry.value;
    }
    return _palette['other']!;
  }

  // 🟢 Helper for Grid Icons
  IconData _iconFor(String label) {
    final k = label.toLowerCase();
    if (k.contains('sleep')) return Icons.bed;
    if (k.contains('work') || k.contains('assignment')) return Icons.work;
    if (k.contains('study')) return Icons.menu_book;
    if (k.contains('gym') || k.contains('workout')) return Icons.fitness_center;
    if (k.contains('breakfast') || k.contains('lunch') || k.contains('dinner')) return Icons.restaurant;
    if (k.contains('rest') || k.contains('leisure')) return Icons.weekend;
    if (k.contains('meeting')) return Icons.groups;
    if (k.contains('walk')) return Icons.directions_walk;
    if (k.contains('reminder') || k.contains('task')) return Icons.check_circle_outline;
    return Icons.local_activity;
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetch();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final s = DateFormat('yyyy-MM-dd').format(_range.start);
    final e = DateFormat('yyyy-MM-dd').format(_range.end);
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/dashboard/life-overview'
      '?user_id=${widget.userId}&start_date=$s&end_date=$e',
    );
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final raw  = (data['activities'] as List? ?? []);
        setState(() {
          _summary = data['summary'] as Map<String, dynamic>? ?? {};
          _stats   = raw.map((a) => _ActivityStat.fromJson(a)).toList()
            ..sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));
        });
      }
    } catch (err) {
      debugPrint('Overview fetch error: $err');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context:          context,
      firstDate:        DateTime(2024),
      lastDate:         DateTime.now(),
      initialDateRange: _range,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary:  AppTheme.kPrimaryTeal,
            surface:  AppTheme.kCardDark,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _range = picked);
      _fetch();
    }
  }

  int get _totalMinutes =>
      _stats.fold(0, (sum, s) => sum + s.totalMinutes);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      appBar: AppBar(
        title: const Text('Life Overview',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.kBackgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.kPrimaryTeal),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.kPrimaryTeal,
          labelColor: AppTheme.kPrimaryTeal,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view_rounded), text: 'Activities'),
            Tab(icon: Icon(Icons.donut_large), text: 'Summary'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildRangeChip(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.kPrimaryTeal))
                : _stats.isEmpty
                    ? _buildEmpty()
                    : TabBarView(
                        controller: _tabCtrl,
                        children: [_buildBreakdown(), _buildSummaryTab()],
                      ),
          ),
        ],
      ),
    );
  }

  // ── Range chip ──────────────────────────────────────────────────────────────
  Widget _buildRangeChip() {
    final days = _range.end.difference(_range.start).inDays + 1;
    return GestureDetector(
      onTap: _pickRange,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:        AppTheme.kCardDark,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: AppTheme.kPrimaryTeal.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: AppTheme.kPrimaryTeal, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${DateFormat("MMM d, y").format(_range.start)}  →  '
                '${DateFormat("MMM d, y").format(_range.end)}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.kPrimaryTeal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$days days',
                style: const TextStyle(
                    color: AppTheme.kPrimaryTeal, fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  // ── Breakdown tab (Grid Layout) ───────────────────────────────────────────
  Widget _buildBreakdown() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,        // 2 boxes per row
        crossAxisSpacing: 16,     // Horizontal space between boxes
        mainAxisSpacing: 16,      // Vertical space between rows
        childAspectRatio: 1.0,    // 1.0 makes them perfect squares
      ),
      itemCount: _stats.length,
      itemBuilder: (_, i) {
        final s   = _stats[i];
        final clr = _colorFor(s.label);
        final icon = _iconFor(s.label);

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.kCardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: clr.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: clr.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: clr.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: clr, size: 28),
              ),
              const SizedBox(height: 12),
              
              // Activity Label
              Text(
                s.label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              
              // Time Consumed
              Text(
                _fmtDuration(s.totalMinutes),
                style: TextStyle(
                  color: clr, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 22
                ),
              ),
              const SizedBox(height: 4),
              
              // Subtext (Entries)
              Text(
                '${s.count} entries',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Summary tab ─────────────────────────────────────────────────────────────
  Widget _buildSummaryTab() {
    final totalH = (_totalMinutes / 60).toStringAsFixed(1);
    final days   = _range.end.difference(_range.start).inDays + 1;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryCard(
          icon:  Icons.access_time,
          label: 'Total Tracked',
          value: '$totalH hours',
          sub:   'across $days days',
          color: AppTheme.kPrimaryTeal,
        ),
        _summaryCard(
          icon:  Icons.trending_up,
          label: 'Most Active',
          value: _stats.isNotEmpty ? _stats.first.label : '—',
          sub:   _stats.isNotEmpty ? _fmtDuration(_stats.first.totalMinutes) : '',
          color: const Color(0xFF66BB6A),
        ),
        _summaryCard(
          icon:  Icons.event_note,
          label: 'Total Entries',
          value: '${_summary['total_entries'] ?? _stats.fold(0, (s, a) => s + a.count)}',
          sub:   'reminders + events + notes',
          color: const Color(0xFF42A5F5),
        ),
        const SizedBox(height: 16),
        const Text('Activity Distribution',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._stats.take(6).map((s) {
          final pct = _totalMinutes == 0 ? 0.0 : s.totalMinutes / _totalMinutes;
          final clr = _colorFor(s.label);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(width: 12, height: 12,
                  decoration: BoxDecoration(color: clr, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(s.label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13))),
              Text('${(pct * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: clr, fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ]),
          );
        }),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppTheme.kCardDark,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:        color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          Text(value, style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          if (sub.isNotEmpty)
            Text(sub, style: const TextStyle(color: Colors.white30, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.insights, size: 72,
            color: AppTheme.kPrimaryTeal.withOpacity(0.3)),
        const SizedBox(height: 16),
        const Text('No activity data for this period',
            style: TextStyle(color: Colors.white38, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Try a wider date range or speak to MindMate first',
            style: TextStyle(color: Colors.white24, fontSize: 12)),
      ]),
    );
  }

  String _fmtDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class _ActivityStat {
  final String label;
  final int    totalMinutes;
  final int    avgMinutes;
  final int    count;

  const _ActivityStat({
    required this.label,
    required this.totalMinutes,
    required this.avgMinutes,
    required this.count,
  });

  factory _ActivityStat.fromJson(Map<String, dynamic> j) => _ActivityStat(
    label:        j['activity']?.toString() ?? j['label']?.toString() ?? 'Other',
    totalMinutes: (j['total_minutes'] as num?)?.toInt() ??
                  (((j['total_hours'] as num?) ?? 0) * 60).toInt(),
    avgMinutes:   (j['avg_minutes'] as num?)?.toInt() ?? 0,
    count:        (j['count'] as num?)?.toInt() ?? 0,
  );
}