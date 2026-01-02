import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../domain/entities/app_usage_point.dart';

class UsageChart extends StatefulWidget {
  final List<AppUsagePoint> history;
  final ThemeData theme;
  final bool isDark;

  const UsageChart({
    super.key,
    required this.history,
    required this.theme,
    required this.isDark,
  });

  @override
  State<UsageChart> createState() => _UsageChartState();
}

class _UsageChartState extends State<UsageChart> {
  String _selectedRange = '1Y'; // 1W, 1M, 3M, 6M, 1Y
  int? _touchedIndex;

  // Cache for filtered points
  late List<AppUsagePoint> _currentPoints;

  @override
  void initState() {
    super.initState();
    _updatePoints();
  }

  void _updatePoints() {
    final full = widget.history;
    if (full.isEmpty) {
      _currentPoints = [];
      return;
    }

    int count;
    switch (_selectedRange) {
      case '1W':
        count = 7;
        break;
      case '1M':
        count = 30;
        break;
      case '3M':
        count = 90;
        break;
      case '6M':
        count = 180;
        break;
      case '1Y':
      default:
        count = 365;
        break;
    }

    // Since list is oldest->newest, we filtered from filtered from END
    if (full.length <= count) {
      _currentPoints = full;
    } else {
      _currentPoints = full.sublist(full.length - count);
    }
  }

  @override
  void didUpdateWidget(UsageChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.history != widget.history) {
      _updatePoints();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPoints.isEmpty) return const SizedBox.shrink();

    // Calculate focused value
    AppUsagePoint focusedPoint;
    if (_touchedIndex != null &&
        _touchedIndex! >= 0 &&
        _touchedIndex! < _currentPoints.length) {
      focusedPoint = _currentPoints[_touchedIndex!];
    } else {
      // Default: Average of displayed period
      final totalMins = _currentPoints.fold(
        0,
        (sum, p) => sum + p.usage.inMinutes,
      );
      final avgMins = _currentPoints.isNotEmpty
          ? totalMins ~/ _currentPoints.length
          : 0;
      focusedPoint = AppUsagePoint(
        date: DateTime.now(), // Ignored for label if not hovering
        usage: Duration(minutes: avgMins),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header (Value & Date)
        _buildHeader(focusedPoint, _touchedIndex != null),
        const SizedBox(height: 16),
        // Chart
        Expanded(child: _buildLineChart()),
        const SizedBox(height: 16),
        // Time Range Selector
        _buildTimeSelector(),
      ],
    );
  }

  Widget _buildHeader(AppUsagePoint point, bool isHovering) {
    final theme = widget.theme;

    String label = "Average Daily Usage";
    String dateStr = "Past $_selectedRange";

    if (isHovering) {
      label = "Usage";
      dateStr = DateFormat('EEE, MMM d, y').format(point.date);
    }

    final mins = point.usage.inMinutes;
    String timeStr;
    if (mins >= 60) {
      timeStr = "${mins ~/ 60}h ${mins % 60}m";
    } else {
      timeStr = "${mins}m";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timeStr,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (isHovering)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                Text(
                  "$label • $dateStr",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    final theme = widget.theme;
    final history = _currentPoints;

    final maxY =
        history
            .map((e) => e.usage.inMinutes.toDouble())
            .reduce((a, b) => max(a, b)) *
        1.2;
    final effectiveMaxY = maxY > 10 ? maxY : 60.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: history.length.toDouble() - 1,
        minY: 0,
        maxY: effectiveMaxY,
        lineTouchData: LineTouchData(
          enabled: true,
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((index) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    ),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: theme.colorScheme.surface,
                            strokeWidth: 2,
                            strokeColor: theme.colorScheme.primary,
                          ),
                    ),
                  );
                }).toList();
              },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent, // Disable tooltip bg
            getTooltipItems: (spots) =>
                spots.map((_) => null).toList(), // Disable tooltip text
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (response == null || response.lineBarSpots == null) {
              if (event is FlPanEndEvent || event is FlTapUpEvent) {
                setState(() => _touchedIndex = null);
              }
              return;
            }
            if (event is FlPanEndEvent || event is FlTapUpEvent) {
              setState(() => _touchedIndex = null);
              return;
            }
            final spotIndex = response.lineBarSpots!.first.spotIndex;
            setState(() {
              _touchedIndex = spotIndex;
            });
          },
          handleBuiltInTouches: true,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: history.asMap().entries.map((e) {
              return FlSpot(
                e.key.toDouble(),
                e.value.usage.inMinutes.toDouble(),
              );
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.1,
            color: theme.colorScheme.primary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.15),
                  theme.colorScheme.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }

  Widget _buildTimeSelector() {
    final ranges = ['1W', '1M', '3M', '6M', '1Y'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: ranges.map((r) => _buildRangeChip(r)).toList(),
      ),
    );
  }

  Widget _buildRangeChip(String range) {
    final isSelected = _selectedRange == range;
    // theme is used via widget.theme in usage below if needed, but it's already in scope via widget.theme.
    // However, the original code used `theme` variable. Let's see.
    // Line 300: final theme = widget.theme;
    // Line 316: color: isSelected ? theme.colorScheme.surface ...
    // Ah, wait. The lint error said line 266?
    // Let's check line 266 in previous view_file output.
    // The previous view_file output for usage_chart.dart (Step 207) showed line 266 inside _buildLineChart? No.
    // Let's re-read the lint error carefully.
    // "The value of the local variable 'theme' isn't used. ... at line 266"
    // Line 266 corresponds to ... wait "theme" variable.
    // Let's look at Step 207 output around line 266.
    // 257:             color: theme.colorScheme.primary,
    // ...
    // 279:   Widget _buildTimeSelector() {
    // 280:     final theme = widget.theme;   <-- This is likely the one if it's not used.
    // 281:     final ranges = ['1W', '1M', '3M', '6M', '1Y'];
    // 282:
    // 283:     return Container(
    // 284:       padding: const EdgeInsets.all(4),
    // 285:       decoration: BoxDecoration(
    // 286:         color: widget.isDark
    // ...
    // It seems `theme` is NOT used in `_buildTimeSelector`. It uses `widget.isDark`.
    // It does NOT use `theme` colorScheme here.
    // Yes, line 280 (in Step 207 view) is `final theme = widget.theme;`.
    // And it is not used in that method.

    final theme = widget.theme;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRange = range;
            _touchedIndex = null;
            _updatePoints();
          });
          HapticFeedback.selectionClick();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            range,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}
