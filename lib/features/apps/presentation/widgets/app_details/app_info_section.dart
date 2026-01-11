/// Widget displaying basic app information details.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/device_app.dart';
import 'common_widgets.dart';
import 'constants.dart';

/// A section displaying basic app details.
///
/// Shows package name, UID, and install date in a styled container.
class AppInfoSection extends StatelessWidget {
  /// The app to display info for.
  final DeviceApp app;

  /// Creates an app info section.
  const AppInfoSection({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Details"),
        const SizedBox(height: AppDetailsSpacing.standard),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDetailsSpacing.lg,
            vertical: 10,
          ),
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
              DetailItem(
                label: "Package",
                value: app.packageName,
                showDivider: true,
              ),
              DetailItem(
                label: "UID",
                value: app.uid.toString(),
                showDivider: true,
              ),
              DetailItem(
                label: "Install Date",
                value: DateFormat.yMMMd().format(app.installDate),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
