/// Widget displaying native libraries used by the app.
library;

import 'package:flutter/material.dart';

import '../../../domain/entities/device_app.dart';
import 'common_widgets.dart';
import 'constants.dart';

/// A section displaying native libraries.
///
/// Shows libraries as chips if 6 or fewer, otherwise shows a list
/// with expansion to view all in a bottom sheet.
class NativeLibsSection extends StatelessWidget {
  /// The app to display native libraries for.
  final DeviceApp app;

  /// Maximum number of libs to show in list mode before requiring expansion.
  static const int maxVisible = 5;

  /// Threshold for switching from chips to list mode.
  static const int chipsThreshold = 6;

  /// Creates a native libs section.
  const NativeLibsSection({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (app.nativeLibraries.length > chipsThreshold) {
      return _buildListMode(context, theme);
    }

    return _buildChipsMode(theme, isDark);
  }

  /// Builds the list mode with expandable view for many libraries.
  Widget _buildListMode(BuildContext context, ThemeData theme) {
    final displayedLibs = app.nativeLibraries.take(maxVisible).toList();
    final remainingCount = app.nativeLibraries.length - maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Native Libraries"),
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
              ...displayedLibs.map((lib) => _NativeLibRow(library: lib)),
              const SizedBox(height: AppDetailsSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showAllNativeLibs(context, theme),
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

  /// Builds the chips mode for fewer libraries.
  Widget _buildChipsMode(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Native Libraries"),
        const SizedBox(height: AppDetailsSpacing.standard),
        Wrap(
          spacing: AppDetailsSpacing.sm,
          runSpacing: AppDetailsSpacing.sm,
          alignment: WrapAlignment.start,
          children: app.nativeLibraries
              .map((lib) => _NativeLibChip(library: lib, isDark: isDark))
              .toList(),
        ),
      ],
    );
  }

  /// Shows all native libraries in a draggable bottom sheet.
  void _showAllNativeLibs(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDetailsBorderRadius.xl),
            ),
          ),
          child: Column(
            children: [
              _buildHandle(theme),
              _buildSheetHeader(context, theme),
              Expanded(child: _buildLibsList(controller, theme)),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the draggable handle.
  Widget _buildHandle(ThemeData theme) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: AppDetailsSpacing.md),
        decoration: BoxDecoration(
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// Builds the sheet header.
  Widget _buildSheetHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppDetailsSpacing.standard),
      child: Row(
        children: [
          Text("Native Libraries", style: theme.textTheme.headlineSmall),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Builds the scrollable libraries list.
  Widget _buildLibsList(ScrollController controller, ThemeData theme) {
    return ListView.builder(
      controller: controller,
      itemCount: app.nativeLibraries.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(
            Icons.settings_system_daydream_rounded,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            app.nativeLibraries[index],
            style: theme.textTheme.bodyMedium,
          ),
        );
      },
    );
  }
}

/// A single native library row.
class _NativeLibRow extends StatelessWidget {
  final String library;

  const _NativeLibRow({required this.library});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDetailsSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.settings_system_daydream_rounded,
            size: AppDetailsSizes.iconMedium,
            color: theme.colorScheme.primary.withOpacity(
              AppDetailsOpacity.nearlyOpaque,
            ),
          ),
          const SizedBox(width: AppDetailsSpacing.md),
          Expanded(
            child: Text(
              library,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// A chip displaying a native library.
class _NativeLibChip extends StatelessWidget {
  final String library;
  final bool isDark;

  const _NativeLibChip({required this.library, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDetailsSpacing.md,
        vertical: AppDetailsSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(AppDetailsOpacity.light),
        ),
        borderRadius: BorderRadius.circular(AppDetailsBorderRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.settings_system_daydream_rounded,
            size: AppDetailsSizes.iconSmall,
            color: theme.colorScheme.onSurface.withOpacity(
              AppDetailsOpacity.high,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              library,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(
                  AppDetailsOpacity.nearlyOpaque,
                ),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
