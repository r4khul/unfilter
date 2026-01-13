library;

import 'package:flutter/material.dart';

import '../constants/constants.dart';

/// A reusable section header widget with different style variants.
class SectionHeader extends StatelessWidget {
  final String title;
  final SectionHeaderStyle style;

  const SectionHeader({
    super.key,
    required this.title,
    this.style = SectionHeaderStyle.title,
  });

  const SectionHeader.label({super.key, required this.title})
    : style = SectionHeaderStyle.label;

  const SectionHeader.drawer({super.key, required this.title})
    : style = SectionHeaderStyle.drawer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (style) {
      case SectionHeaderStyle.title:
        return Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        );
      case SectionHeaderStyle.label:
        return Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(AppOpacity.high),
          ),
        );
      case SectionHeaderStyle.drawer:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontSize: 11,
              color: theme.colorScheme.primary.withOpacity(AppOpacity.high),
            ),
          ),
        );
    }
  }
}

enum SectionHeaderStyle { title, label, drawer }
