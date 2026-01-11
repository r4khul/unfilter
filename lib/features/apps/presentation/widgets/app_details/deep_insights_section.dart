/// Widget displaying deep technical insights about the app.
library;

import 'package:flutter/material.dart';

import '../../../domain/entities/device_app.dart';
import 'common_widgets.dart';
import 'constants.dart';
import 'utils.dart';

/// A section displaying deep technical insights.
///
/// Shows:
/// - Installer store
/// - Tech framework versions
/// - Min/Target SDK with names
/// - Signing signature
/// - Split APKs
/// - App size and paths
/// - Component counts (Activities, Services, Receivers, Providers)
class DeepInsightsSection extends StatelessWidget {
  /// The app to display insights for.
  final DeviceApp app;

  /// Creates a deep insights section.
  const DeepInsightsSection({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Deep Insights"),
        const SizedBox(height: AppDetailsSpacing.standard),
        Container(
          padding: const EdgeInsets.all(AppDetailsSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppDetailsBorderRadius.xl),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(
                AppDetailsOpacity.mediumLight,
              ),
            ),
          ),
          child: Column(
            children: [
              ..._buildDetailItems(),
              const SizedBox(height: AppDetailsSpacing.xl),
              _buildComponentCounts(theme),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the list of detail items.
  List<Widget> _buildDetailItems() {
    final items = <Widget>[];

    // Installer
    if (app.installerStore != 'Unknown') {
      items.add(
        DetailItem(
          label: "Installer",
          value: formatInstallerName(app.installerStore),
          showDivider: true,
        ),
      );
    }

    // Tech versions
    if (app.techVersions.isNotEmpty) {
      for (final entry in app.techVersions.entries) {
        items.add(
          DetailItem(
            label: "${entry.key} Version",
            value: entry.value,
            showDivider: true,
          ),
        );
      }
    }

    // Kotlin version (if not already in tech versions)
    if (app.kotlinVersion != null && !app.techVersions.containsKey('Kotlin')) {
      items.add(
        DetailItem(
          label: "Kotlin Version",
          value: app.kotlinVersion!,
          showDivider: true,
        ),
      );
    }

    // Min SDK
    items.add(
      DetailItem(
        label: "Min SDK",
        value: "${app.minSdkVersion} (${getSdkVersionName(app.minSdkVersion)})",
        showDivider: true,
      ),
    );

    // Target SDK
    items.add(
      DetailItem(
        label: "Target SDK",
        value:
            "${app.targetSdkVersion} (${getSdkVersionName(app.targetSdkVersion)})",
        showDivider: true,
      ),
    );

    // Signing signature
    if (app.signingSha1 != null) {
      items.add(
        DetailItem(
          label: "Signature (SHA-1)",
          value: app.signingSha1!,
          showDivider: true,
        ),
      );
    }

    // Split APKs
    if (app.splitApks.isNotEmpty) {
      items.add(
        DetailItem(
          label: "Split APKs",
          value: "${app.splitApks.length} splits",
          showDivider: true,
        ),
      );
    }

    // App size
    items.add(
      DetailItem(
        label: "App Size",
        value: formatBytes(app.size),
        showDivider: true,
      ),
    );

    // APK path
    items.add(
      DetailItem(label: "APK Path", value: app.apkPath, showDivider: true),
    );

    // Data directory
    items.add(DetailItem(label: "Data Dir", value: app.dataDir));

    return items;
  }

  /// Builds the component counts grid.
  Widget _buildComponentCounts(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            _ComponentCount(label: "Activities", count: app.activitiesCount),
            const SizedBox(width: AppDetailsSpacing.md),
            _ComponentCount(label: "Services", count: app.servicesCount),
          ],
        ),
        const SizedBox(height: AppDetailsSpacing.md),
        Row(
          children: [
            _ComponentCount(label: "Receivers", count: app.receiversCount),
            const SizedBox(width: AppDetailsSpacing.md),
            _ComponentCount(label: "Providers", count: app.providersCount),
          ],
        ),
      ],
    );
  }
}

/// A component count display card.
class _ComponentCount extends StatelessWidget {
  final String label;
  final int count;

  const _ComponentCount({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppDetailsSpacing.standard,
          horizontal: AppDetailsSpacing.md,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(
            AppDetailsOpacity.standard,
          ),
          borderRadius: BorderRadius.circular(AppDetailsBorderRadius.md),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppDetailsSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
