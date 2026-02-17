library;

import 'package:flutter/material.dart';

import '../../../domain/entities/device_app.dart';
import 'common_widgets.dart';
import 'constants.dart';
import 'premium_modal_header.dart';

class NativeLibsSection extends StatelessWidget {
  final DeviceApp app;

  static const int maxVisible = 5;

  static const int chipsThreshold = 6;

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
              color: theme.colorScheme.outline.withValues(alpha: 
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
                      color: theme.colorScheme.primary.withValues(alpha: 
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

  void _showAllNativeLibs(BuildContext context, ThemeData theme) {
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
                title: "Native Libraries",
                icon: Icons.memory_rounded,
                onClose: () => Navigator.pop(context),
              ),
              Expanded(child: _buildLibsList(controller, theme)),
            ],
          ),
        ),
      ),
    );
  }

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
            color: theme.colorScheme.primary.withValues(alpha: 
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
          color: theme.colorScheme.outline.withValues(alpha: AppDetailsOpacity.light),
        ),
        borderRadius: BorderRadius.circular(AppDetailsBorderRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.settings_system_daydream_rounded,
            size: AppDetailsSizes.iconSmall,
            color: theme.colorScheme.onSurface.withValues(alpha: 
              AppDetailsOpacity.high,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              library,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 
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
