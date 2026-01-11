library;

import 'package:flutter/material.dart';

import '../../../domain/entities/device_app.dart';
import 'common_widgets.dart';
import 'constants.dart';
import 'utils.dart';

class DeepInsightsSection extends StatelessWidget {
  final DeviceApp app;

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

  List<Widget> _buildDetailItems() {
    final items = <Widget>[];

    if (app.installerStore != 'Unknown') {
      items.add(
        DetailItem(
          label: "Installer",
          value: formatInstallerName(app.installerStore),
          showDivider: true,
        ),
      );
    }

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

    if (app.kotlinVersion != null && !app.techVersions.containsKey('Kotlin')) {
      items.add(
        DetailItem(
          label: "Kotlin Version",
          value: app.kotlinVersion!,
          showDivider: true,
        ),
      );
    }

    items.add(
      DetailItem(
        label: "Min SDK",
        value: "${app.minSdkVersion} (${getSdkVersionName(app.minSdkVersion)})",
        showDivider: true,
      ),
    );

    items.add(
      DetailItem(
        label: "Target SDK",
        value:
            "${app.targetSdkVersion} (${getSdkVersionName(app.targetSdkVersion)})",
        showDivider: true,
      ),
    );

    if (app.signingSha1 != null) {
      items.add(
        DetailItem(
          label: "Signature (SHA-1)",
          value: app.signingSha1!,
          showDivider: true,
        ),
      );
    }

    if (app.splitApks.isNotEmpty) {
      items.add(
        DetailItem(
          label: "Split APKs",
          value: "${app.splitApks.length} splits",
          showDivider: true,
        ),
      );
    }

    items.add(
      DetailItem(
        label: "App Size",
        value: formatBytes(app.size),
        showDivider: true,
      ),
    );

    items.add(
      DetailItem(label: "APK Path", value: app.apkPath, showDivider: true),
    );

    items.add(DetailItem(label: "Data Dir", value: app.dataDir));

    return items;
  }

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
