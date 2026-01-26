import 'package:flutter/material.dart';

/// A professional top shadow gradient that creates a modern "fade into darkness" effect
/// where scrolling content appears to disappear into the shadow at the top.
///
/// Dark mode: Uses black shadow for depth
/// Light mode: Uses white shadow for clean fade
class TopShadowGradient extends StatelessWidget {
  const TopShadowGradient({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          height: 200, // Increased height to prevent abrupt cut-off
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      // Dark mode: More aggressive deep black shadow
                      Colors.black.withOpacity(0.85), // Increased from 0.6
                      Colors.black.withOpacity(0.65), // Increased from 0.4
                      Colors.black.withOpacity(0.4), // Increased from 0.2
                      Colors.black.withOpacity(0.1), // Reduced from 0.15
                      Colors.transparent,
                    ]
                  : [
                      // Light mode: More aggressive white shadow
                      Colors.white.withOpacity(0.75), // Increased from 0.5
                      Colors.white.withOpacity(0.55), // Increased from 0.35
                      Colors.white.withOpacity(0.35), // Increased from 0.2
                      Colors.white.withOpacity(0.1), // Reduced from 0.12
                      Colors.transparent,
                    ],
              // Adjusted stops to ensure fully transparent well before the bottom edge
              stops: const [0.0, 0.2, 0.45, 0.7, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
