import 'dart:typed_data';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../apps/domain/entities/device_app.dart';
import '../../../apps/presentation/providers/apps_provider.dart';

class StatisticsDialog extends ConsumerStatefulWidget {
  const StatisticsDialog({super.key});

  @override
  ConsumerState<StatisticsDialog> createState() => _StatisticsDialogState();
}

class _StatisticsDialogState extends ConsumerState<StatisticsDialog> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appsAsync = ref.watch(installedAppsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
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
                  Text(
                    "Usage Statistics",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                    ),
                  ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<DeviceApp> apps) {
    // 1. Process Data
    final validApps = apps.where((a) => a.totalTimeInForeground > 0).toList();
    if (validApps.isEmpty) {
      return const Center(child: Text("No usage data available yet."));
    }

    validApps.sort(
      (a, b) => b.totalTimeInForeground.compareTo(a.totalTimeInForeground),
    );

    // Take top 5
    final topApps = validApps.take(5).toList();

    // Calculate totals for percentages
    final totalUsage = validApps.fold<int>(
      0,
      (sum, app) => sum + app.totalTimeInForeground,
    );
    final topUsage = topApps.fold<int>(
      0,
      (sum, app) => sum + app.totalTimeInForeground,
    );
    final otherUsage = totalUsage - topUsage;

    // If we have rest, add a dummy entry for chart (not for list maybe?)
    // Actually, asking for "top of the them", implying list should show top apps.

    return Column(
      children: [
        // Pie Chart Section
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _generateSections(
                    context,
                    topApps,
                    otherUsage,
                    totalUsage,
                  ),
                ),
              ),
              // Center Info
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${validApps.length}",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  Text(
                    "Apps",
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // List Section (Only Top Apps)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: topApps.length,
            itemBuilder: (context, index) {
              final app = topApps[index];
              final isTouched = index == _touchedIndex;
              final percent = (app.totalTimeInForeground / totalUsage);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isTouched
                      ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.2)
                      : Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isTouched
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    // Dot
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getColor(context, index),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.appName,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Usage Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: percent, // Relative to total usage
                              minHeight: 4,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.1),
                              color: _getColor(context, index),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDuration(
                        Duration(milliseconds: app.totalTimeInForeground),
                      ),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generateSections(
    BuildContext context,
    List<DeviceApp> topApps,
    int otherUsage,
    int totalUsage,
  ) {
    List<PieChartSectionData> sections = [];

    // Top Apps
    for (int i = 0; i < topApps.length; i++) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched
          ? 16.0
          : 0.0; // Hide text if not touched to be cleaner? Or show %
      final radius = isTouched ? 60.0 : 50.0;
      final app = topApps[i];
      final value = app.totalTimeInForeground.toDouble();

      sections.add(
        PieChartSectionData(
          color: _getColor(context, i),
          value: value,
          title: '${((value / totalUsage) * 100).toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: isTouched
              ? _Badge(app.icon, size: 40)
              : _Badge(app.icon, size: 30),
          badgePositionPercentageOffset: .98,
        ),
      );
    }

    // Others
    if (otherUsage > 0) {
      final isTouched = sections.length == _touchedIndex;
      final radius = isTouched
          ? 55.0
          : 45.0; // Slightly smaller for contrast? or same.

      sections.add(
        PieChartSectionData(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          value: otherUsage.toDouble(),
          title: '', // No title for others to keep clean
          radius: radius,
          showTitle: false,
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
    final theme = Theme.of(context);
    // Sophisticated palette
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.error,
      theme.colorScheme.primaryContainer,
      Colors.grey,
    ];
    return colors[index % colors.length];
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

  const _Badge(this.iconBytes, {required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
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
