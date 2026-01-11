library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'constants.dart';

void showPremiumSnackbar({
  required BuildContext context,
  required IconData icon,
  required String message,
  required bool isSuccess,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  final iconColor = isSuccess
      ? const Color(0xFF4CAF50)
      : theme.colorScheme.error;

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: ClipRRect(
        borderRadius: BorderRadius.circular(AppDetailsBorderRadius.md),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDetailsSpacing.standard,
              vertical: AppDetailsSpacing.standard - 2,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A1A1A).withOpacity(0.92)
                  : const Color(0xFFF0F0F0).withOpacity(0.92),
              borderRadius: BorderRadius.circular(AppDetailsBorderRadius.md),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(
                  AppDetailsOpacity.light,
                ),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDetailsSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: AppDetailsSizes.iconMedium,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: AppDetailsSpacing.md),
                Flexible(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppDetailsFontSizes.standard,
                      color: theme.colorScheme.onSurface.withOpacity(
                        AppDetailsOpacity.veryHigh,
                      ),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: AppDetailsDurations.snackbar,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDetailsSpacing.lg,
        vertical: AppDetailsSpacing.standard,
      ),
    ),
  );
}
