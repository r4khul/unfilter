library;

import 'package:flutter/material.dart';

import '../../../domain/entities/device_app.dart';
import 'common_widgets.dart';
import 'constants.dart';
import 'premium_modal_header.dart';

class DeveloperSection extends StatelessWidget {
  final DeviceApp app;

  static const int maxVisible = 5;

  static const int expandThreshold = 6;

  const DeveloperSection({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final packages = _detectPackages();
    if (packages.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    if (packages.length > expandThreshold) {
      return _buildExpandableMode(context, theme, packages);
    }

    return _buildCompactMode(theme, packages);
  }

  Map<String, String> _detectPackages() {
    final Map<String, String> detected = {};
    for (final lib in app.nativeLibraries) {
      if (lib.contains("stripe")) {
        detected["Stripe"] = "Payment Gateway";
      } else if (lib.contains("mapbox")) {
        detected["Mapbox"] = "Maps & Location";
      } else if (lib.contains("realm")) {
        detected["Realm"] = "Database";
      } else if (lib.contains("firebase")) {
        detected["Firebase"] = "Backend/Analytics";
      } else if (lib.contains("appwrite")) {
        detected["Appwrite"] = "Backend";
      } else if (lib.contains("supabase")) {
        detected["Supabase"] = "Backend";
      } else if (lib.contains("sentry")) {
        detected["Sentry"] = "Crash Reporting";
      }
    }
    return detected;
  }

  Widget _buildExpandableMode(
    BuildContext context,
    ThemeData theme,
    Map<String, String> packages,
  ) {
    final displayedPackages = packages.values.take(maxVisible).toList();
    final remainingCount = packages.length - maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Detected Packages"),
        const SizedBox(height: AppDetailsSpacing.standard),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDetailsSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(
                AppDetailsOpacity.mediumLight,
              ),
            ),
            borderRadius: BorderRadius.circular(AppDetailsBorderRadius.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...displayedPackages.map((pkg) => _PackageRow(package: pkg)),
              const SizedBox(height: AppDetailsSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showAllPackages(
                    context,
                    theme,
                    packages.values.toList(),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDetailsSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDetailsBorderRadius.md,
                      ),
                    ),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(
                        AppDetailsOpacity.half,
                      ),
                    ),
                  ),
                  child: Text(
                    "View $remainingCount More",
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMode(ThemeData theme, Map<String, String> packages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Detected Packages"),
        const SizedBox(height: AppDetailsSpacing.standard),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDetailsSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(
                AppDetailsOpacity.mediumLight,
              ),
            ),
            borderRadius: BorderRadius.circular(AppDetailsBorderRadius.xl),
          ),
          child: Column(
            children: packages.values
                .map((pkg) => _PackageRow(package: pkg))
                .toList(),
          ),
        ),
      ],
    );
  }

  void _showAllPackages(
    BuildContext context,
    ThemeData theme,
    List<String> packages,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            children: [
              PremiumModalHeader(
                title: "Detected Packages",
                icon: Icons.extension_rounded,
                onClose: () => Navigator.pop(context),
              ),
              Expanded(child: _buildPackagesList(controller, theme, packages)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackagesList(
    ScrollController controller,
    ThemeData theme,
    List<String> packages,
  ) {
    return ListView.builder(
      controller: controller,
      itemCount: packages.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(
            Icons.extension_rounded,
            color: theme.colorScheme.secondary,
          ),
          title: Text(packages[index], style: theme.textTheme.bodyMedium),
        );
      },
    );
  }
}

class _PackageRow extends StatelessWidget {
  final String package;

  const _PackageRow({required this.package});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDetailsSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.extension_rounded,
            size: AppDetailsSizes.iconMedium,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: AppDetailsSpacing.md),
          Text(
            package,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
