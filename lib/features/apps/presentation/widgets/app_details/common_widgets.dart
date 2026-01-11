/// Common UI components used across app details sections.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';

/// A section header with consistent styling.
///
/// Used to label major sections in the app details page.
class SectionHeader extends StatelessWidget {
  /// The title text to display.
  final String title;

  /// Creates a section header.
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }
}

/// A detail item row with label and value.
///
/// Supports long press to copy the value to clipboard.
class DetailItem extends StatelessWidget {
  /// The label for this detail.
  final String label;

  /// The value to display.
  final String value;

  /// Whether to show a divider below this item.
  final bool showDivider;

  /// Creates a detail item.
  const DetailItem({
    super.key,
    required this.label,
    required this.value,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied $label'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDetailsSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 3,
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(
                        AppDetailsOpacity.high,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppDetailsSpacing.standard),
                Flexible(
                  flex: 5,
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: AppDetailsSizes.dividerHeight,
              color: theme.colorScheme.outline.withOpacity(
                AppDetailsOpacity.light,
              ),
            ),
        ],
      ),
    );
  }
}

/// A vertical divider for stats.
class StatDivider extends StatelessWidget {
  /// Creates a stat divider.
  const StatDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: AppDetailsSizes.statDividerHeight,
      width: AppDetailsSizes.dividerWidth,
      color: theme.colorScheme.outline.withOpacity(AppDetailsOpacity.standard),
    );
  }
}

/// A section container with consistent styling.
class SectionContainer extends StatelessWidget {
  /// The child widget to display inside.
  final Widget child;

  /// Whether to use alternative background (less opaque).
  final bool useAltBackground;

  /// Creates a section container.
  const SectionContainer({
    super.key,
    required this.child,
    this.useAltBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDetailsSpacing.lg),
      decoration: BoxDecoration(
        color: useAltBackground
            ? theme.colorScheme.surface
            : (isDark
                  ? Colors.white.withOpacity(AppDetailsOpacity.subtle)
                  : Colors.black.withOpacity(AppDetailsOpacity.verySubtle)),
        borderRadius: BorderRadius.circular(AppDetailsBorderRadius.xl),
        border: useAltBackground
            ? Border.all(
                color: theme.colorScheme.outline.withOpacity(
                  AppDetailsOpacity.mediumLight,
                ),
              )
            : null,
      ),
      child: child,
    );
  }
}
