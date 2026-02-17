library;

import 'package:flutter/material.dart';

import '../constants/constants.dart';

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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: useAltBackground
            ? theme.colorScheme.surface
            : (isDark
                  ? Colors.white.withValues(alpha: AppOpacity.subtle)
                  : Colors.black.withValues(alpha: AppOpacity.verySubtle)),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: useAltBackground
            ? Border.all(
                color: theme.colorScheme.outline.withValues(alpha: AppOpacity.low),
              )
            : null,
      ),
      child: child,
    );
  }
}
