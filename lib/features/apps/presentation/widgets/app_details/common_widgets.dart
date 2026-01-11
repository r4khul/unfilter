library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';

class SectionHeader extends StatelessWidget {
  final String title;

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

class DetailItem extends StatelessWidget {
  final String label;

  final String value;

  final bool showDivider;

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

class StatDivider extends StatelessWidget {
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

class SectionContainer extends StatelessWidget {
  final Widget child;

  final bool useAltBackground;

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
