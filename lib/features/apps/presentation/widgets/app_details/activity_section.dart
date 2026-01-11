/// Widget displaying app activity and usage information.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/app_usage_point.dart';
import '../../../domain/entities/device_app.dart';
import '../usage_chart.dart';
import 'common_widgets.dart';
import 'constants.dart';

/// A section displaying app activity and usage stats.
///
/// Shows:
/// - Total usage time badge
/// - Usage description with install date
/// - Usage chart (if granular data available)
/// - Empty states for no data
class ActivitySection extends ConsumerWidget {
  /// The app to display activity for.
  final DeviceApp app;

  /// Async value containing usage history.
  final AsyncValue<List<AppUsagePoint>> historyAsync;

  /// Creates an activity section.
  const ActivitySection({
    super.key,
    required this.app,
    required this.historyAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalDuration = Duration(milliseconds: app.totalTimeInForeground);
    final totalUsageStr = _formatDuration(totalDuration);
    final daysSinceInstall = DateTime.now().difference(app.installDate).inDays;
    final installDateStr = DateFormat('MMM d, y').format(app.installDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme, totalUsageStr),
        if (app.totalTimeInForeground > 0)
          Padding(
            padding: const EdgeInsets.only(
              top: AppDetailsSpacing.sm,
              bottom: AppDetailsSpacing.xs,
            ),
            child: Text(
              "Used for $totalUsageStr since installed on $installDateStr ($daysSinceInstall days ago)",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(
                  AppDetailsOpacity.high,
                ),
              ),
            ),
          ),
        const SizedBox(height: AppDetailsSpacing.standard),
        _buildChart(theme, isDark),
      ],
    );
  }

  /// Formats a duration to a readable string.
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return "${duration.inHours}h ${duration.inMinutes % 60}m";
    }
    return "${duration.inMinutes}m";
  }

  /// Builds the section header with total usage badge.
  Widget _buildHeader(ThemeData theme, String totalUsageStr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SectionHeader(title: "Activity"),
        if (app.totalTimeInForeground > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDetailsSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(
                AppDetailsOpacity.light,
              ),
              borderRadius: BorderRadius.circular(AppDetailsBorderRadius.lg),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: AppDetailsSizes.iconSmall,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  totalUsageStr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Builds the usage chart or appropriate state.
  Widget _buildChart(ThemeData theme, bool isDark) {
    return historyAsync.when(
      data: (history) => _buildDataState(history, theme, isDark),
      loading: () => _buildLoadingState(isDark),
      error: (_, __) => _buildErrorState(isDark, theme),
    );
  }

  /// Builds the chart when data is available.
  Widget _buildDataState(
    List<AppUsagePoint> history,
    ThemeData theme,
    bool isDark,
  ) {
    final hasGranular =
        history.isNotEmpty && history.any((h) => h.usage.inSeconds > 0);
    final hasTotal = app.totalTimeInForeground > 0;

    final double containerHeight;
    if (hasGranular) {
      containerHeight = AppDetailsHeights.fullChart;
    } else if (hasTotal) {
      containerHeight = AppDetailsHeights.totalUsageOnly;
    } else {
      containerHeight = AppDetailsHeights.emptyState;
    }

    Widget content;
    if (hasGranular) {
      content = UsageChart(history: history, theme: theme, isDark: isDark);
    } else if (hasTotal) {
      content = _buildNoChartDataState(theme);
    } else {
      content = _buildEmptyState(history, theme);
    }

    return SectionContainer(
      useAltBackground: false,
      child: SizedBox(
        height: containerHeight,
        width: double.infinity,
        child: content,
      ),
    );
  }

  /// Builds state when there's total usage but no granular data.
  Widget _buildNoChartDataState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights_rounded,
            size: AppDetailsSizes.iconLarge,
            color: theme.colorScheme.onSurface.withOpacity(
              AppDetailsOpacity.standard,
            ),
          ),
          const SizedBox(height: AppDetailsSpacing.md),
          Text(
            "Adequate data not found to plot chart",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(
                AppDetailsOpacity.half,
              ),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds empty state when there's no usage data.
  Widget _buildEmptyState(List<AppUsagePoint> history, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: AppDetailsSizes.iconXLarge,
            color: theme.colorScheme.onSurface.withOpacity(
              AppDetailsOpacity.mediumLight,
            ),
          ),
          const SizedBox(height: AppDetailsSpacing.md),
          Text(
            history.isEmpty
                ? "No recent activity"
                : "No usage recorded in last year",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(
                AppDetailsOpacity.half,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds loading state.
  Widget _buildLoadingState(bool isDark) {
    return SectionContainer(
      useAltBackground: false,
      child: SizedBox(
        height: AppDetailsHeights.loading,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  /// Builds error state.
  Widget _buildErrorState(bool isDark, ThemeData theme) {
    return SectionContainer(
      useAltBackground: false,
      child: SizedBox(
        height: AppDetailsHeights.containerSmall,
        child: Center(
          child: Text(
            "Unable to load activity",
            style: theme.textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}
