library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/device_app.dart';
import 'common_widgets.dart';
import 'constants.dart';

class AppStatsRow extends StatelessWidget {
  final DeviceApp app;

  const AppStatsRow({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDetailsSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(AppDetailsOpacity.subtle)
            : Colors.black.withOpacity(AppDetailsOpacity.verySubtle),
        borderRadius: BorderRadius.circular(AppDetailsBorderRadius.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: "Version", value: app.version),
          const StatDivider(),
          _StatItem(
            label: "SDK",
            value: "${app.minSdkVersion} - ${app.targetSdkVersion}",
          ),
          const StatDivider(),
          _StatItem(
            label: "Updated",
            value: DateFormat("MMM d").format(app.updateDate),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(
                AppDetailsOpacity.half,
              ),
              fontWeight: FontWeight.bold,
              fontSize: AppDetailsFontSizes.sm,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDetailsSpacing.xs),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
