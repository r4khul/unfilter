import 'dart:typed_data';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../apps/domain/entities/device_app.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import '../../../../features/apps/presentation/pages/app_details_page.dart';

class StatisticsDialog extends ConsumerStatefulWidget {
  const StatisticsDialog({super.key});

  @override
  ConsumerState<StatisticsDialog> createState() => _StatisticsDialogState();
}

class _StatisticsDialogState extends ConsumerState<StatisticsDialog> {
  int _touchedIndex = -1;
  int _showTopCount = 5; // Default show top 5

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appsAsync = ref.watch(installedAppsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 750),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with Dropdown
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.pie_chart_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Usage Statistics",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  _buildTopSelector(theme),
                ],
              ),
            ),

            Expanded(
              child: appsAsync.when(
                data: (apps) => _buildContent(context, apps),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text("Error: $err")),
              ),
            ),

            // Close Button Footer
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text("Close"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSelector(ThemeData theme) {
    return PopupMenuButton<int>(
      initialValue: _showTopCount,
      onSelected: (value) => setState(() => _showTopCount = value),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 5, child: Text("Top 5 Apps")),
        const PopupMenuItem(value: 10, child: Text("Top 10 Apps")),
        const PopupMenuItem(value: 25, child: Text("Top 25 Apps")),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Text(
              "Top $_showTopCount",
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<DeviceApp> apps) {
    final validApps = apps.where((a) => a.totalTimeInForeground > 0).toList();
    if (validApps.isEmpty) {
      return const Center(child: Text("No usage data available yet."));
    }

    validApps.sort(
      (a, b) => b.totalTimeInForeground.compareTo(a.totalTimeInForeground),
    );

    final totalUsage = validApps.fold<int>(
      0,
      (sum, app) => sum + app.totalTimeInForeground,
    );

    // Logic for Top X vs Others
    final topApps = validApps.take(_showTopCount).toList();

    // We only show chart for Top 5 always to keep it clean, but list shows Top X
    // OR we show chart for Top X. If X=25 chart is messy.
    // Let's cap chart slices at 8 for visibility, group rest in chart as Others.
    final chartApps = validApps.take(7).toList();
    final chartTopUsage = chartApps.fold<int>(
      0,
      (sum, app) => sum + app.totalTimeInForeground,
    );
    final chartOtherUsage = totalUsage - chartTopUsage;

    return Column(
      children: [
        // Pie Chart Area
        SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        if (_touchedIndex != -1)
                          setState(() => _touchedIndex = -1);
                        return;
                      }
                      final newIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                      if (_touchedIndex != newIndex)
                        setState(() => _touchedIndex = newIndex);

                      // Handle touch navigation if touchUp
                      if (event is FlTapUpEvent &&
                          newIndex < chartApps.length) {
                        _navigateToApp(context, chartApps[newIndex]);
                      }
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: _generateSections(
                    context,
                    chartApps,
                    chartOtherUsage,
                    totalUsage,
                  ),
                ),
                swapAnimationDuration: const Duration(milliseconds: 600),
                swapAnimationCurve: Curves.easeOutQuint,
              ),
              // Center Info
              IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _touchedIndex != -1 && _touchedIndex < chartApps.length
                          ? "${((chartApps[_touchedIndex].totalTimeInForeground / totalUsage) * 100).toStringAsFixed(1)}%"
                          : "${validApps.length}",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Text(
                      _touchedIndex != -1 && _touchedIndex < chartApps.length
                          ? "Of total usage"
                          : "Apps Used",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Apps List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: topApps.length,
            // Optimization: Use prototype item if fixed height, but dynamic here.
            itemBuilder: (context, index) {
              final app = topApps[index];
              final percent = (app.totalTimeInForeground / totalUsage);
              // Highlight corresponding chart item if less than chart cap
              final isChartHighlighted =
                  index < chartApps.length && index == _touchedIndex;

              return GestureDetector(
                onTap: () => _navigateToApp(context, app),
                onTapDown: (_) {
                  // Interactive highlight on list touch
                  if (index < chartApps.length)
                    setState(() => _touchedIndex = index);
                },
                onTapCancel: () => setState(() => _touchedIndex = -1),
                onTapUp: (_) =>
                    setState(() => _touchedIndex = -1), // Reset after tap
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isChartHighlighted
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withOpacity(0.2)
                        : Theme.of(context).colorScheme.surfaceContainerHighest
                              .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isChartHighlighted
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.5)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: app.packageName,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(
                            2,
                          ), // White border effect
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: app.icon != null
                                ? Image.memory(
                                    app.icon!,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                  )
                                : const Icon(Icons.android, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.appName,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 6,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.1),
                                color: _getColor(context, index),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDuration(
                              Duration(milliseconds: app.totalTimeInForeground),
                            ),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                          Text(
                            "${(percent * 100).toStringAsFixed(1)}%",
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToApp(BuildContext context, DeviceApp app) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AppDetailsPage(app: app)),
    );
  }

  List<PieChartSectionData> _generateSections(
    BuildContext context,
    List<DeviceApp> displayApps,
    int otherUsage,
    int totalUsage,
  ) {
    List<PieChartSectionData> sections = [];

    for (int i = 0; i < displayApps.length; i++) {
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 65.0 : 55.0;
      final app = displayApps[i];
      final value = app.totalTimeInForeground.toDouble();

      sections.add(
        PieChartSectionData(
          color: _getColor(context, i),
          value: value,
          title:
              '', // Titles hidden on chart for cleaner look, shown in center/list
          radius: radius,
          badgeWidget: isTouched
              ? _Badge(
                  app.icon,
                  size: 45,
                  borderColor: Theme.of(context).colorScheme.primary,
                )
              : _Badge(app.icon, size: 35),
          badgePositionPercentageOffset: .98,
        ),
      );
    }

    if (otherUsage > 0) {
      final isTouched = sections.length == _touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;

      sections.add(
        PieChartSectionData(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          value: otherUsage.toDouble(),
          title: '',
          radius: radius,
          badgeWidget: Icon(
            Icons.more_horiz,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            size: 20,
          ),
          badgePositionPercentageOffset: .98,
        ),
      );
    }

    return sections;
  }

  Color _getColor(BuildContext context, int index) {
    // Use HSL for generative consistent smooth colors
    final seedColor = Theme.of(context).colorScheme.primary;
    final hsl = HSLColor.fromColor(seedColor);

    // Rotate hue for distinct but harmonious colors
    // Adjust lightness to keep readable
    final double hue = (hsl.hue + (index * 45)) % 360;
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.55).toColor();
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
    } else {
      return "${d.inMinutes}m";
    }
  }
}

class _Badge extends StatelessWidget {
  final Uint8List? iconBytes;
  final double size;
  final Color? borderColor;

  const _Badge(this.iconBytes, {required this.size, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2), // White padding
      child: ClipOval(
        child: iconBytes != null
            ? Image.memory(
                iconBytes!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.android, size: 16),
              )
            : const Icon(Icons.android, size: 16),
      ),
    );
  }
}
