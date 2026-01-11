/// Centralized constants for the App Details feature.
///
/// This file contains all UI-related constants used across app details
/// widgets to ensure consistency and maintainability.
library;

// =============================================================================
// SPACING & PADDING
// =============================================================================

/// Spacing values used in app details.
abstract class AppDetailsSpacing {
  /// Extra small spacing (4dp).
  static const double xs = 4.0;

  /// Small spacing (8dp).
  static const double sm = 8.0;

  /// Medium spacing (12dp).
  static const double md = 12.0;

  /// Standard spacing (16dp).
  static const double standard = 16.0;

  /// Large spacing (20dp).
  static const double lg = 20.0;

  /// Extra large spacing (24dp).
  static const double xl = 24.0;

  /// Section spacing (32dp).
  static const double section = 32.0;

  /// Bottom spacing (40dp).
  static const double bottom = 40.0;
}

// =============================================================================
// BORDER RADII
// =============================================================================

/// Border radius values for app details.
abstract class AppDetailsBorderRadius {
  /// Medium radius (16dp).
  static const double md = 16.0;

  /// Large radius (20dp).
  static const double lg = 20.0;

  /// Extra large radius (24dp).
  static const double xl = 24.0;
}

// =============================================================================
// SIZING
// =============================================================================

/// Standard sizes for UI elements.
abstract class AppDetailsSizes {
  /// App icon size.
  static const double appIconSize = 100.0;

  /// Tech stack icon size.
  static const double techStackIconSize = 20.0;

  /// Small icon size.
  static const double iconSmall = 14.0;

  /// Medium icon size.
  static const double iconMedium = 18.0;

  /// Large icon size.
  static const double iconLarge = 32.0;

  /// Extra large icon size.
  static const double iconXLarge = 48.0;

  /// Stat divider height.
  static const double statDividerHeight = 30.0;

  /// Divider width.
  static const double dividerWidth = 1.0;

  /// Divider height.
  static const double dividerHeight = 1.0;
}

// =============================================================================
// OPACITY VALUES
// =============================================================================

/// Opacity values for consistent transparency.
abstract class AppDetailsOpacity {
  /// Very subtle opacity.
  static const double verySubtle = 0.03;

  /// Subtle opacity.
  static const double subtle = 0.05;

  /// Light opacity.
  static const double light = 0.1;

  /// Medium-light opacity.
  static const double mediumLight = 0.2;

  /// Standard opacity.
  static const double standard = 0.3;

  /// Half opacity.
  static const double half = 0.5;

  /// High opacity.
  static const double high = 0.6;

  /// Nearly opaque.
  static const double nearlyOpaque = 0.8;

  /// Very high opacity.
  static const double veryHigh = 0.9;
}

// =============================================================================
// FONT SIZES
// =============================================================================

/// Font size constants.
abstract class AppDetailsFontSizes {
  /// Small font size (10dp).
  static const double sm = 10.0;

  /// Medium font size (12dp).
  static const double md = 12.0;

  /// Standard font size (14dp).
  static const double standard = 14.0;

  /// Large font size (40dp) - for icon placeholders.
  static const double iconPlaceholder = 40.0;
}

// =============================================================================
// CHART HEIGHTS
// =============================================================================

/// Chart and container height constants.
abstract class AppDetailsHeights {
  /// Small container height.
  static const double containerSmall = 120.0;

  /// Empty state container height.
  static const double emptyState = 130.0;

  /// Total usage only container height.
  static const double totalUsageOnly = 180.0;

  /// Loading container height.
  static const double loading = 340.0;

  /// Full chart container height.
  static const double fullChart = 360.0;
}

// =============================================================================
// ANIMATION DURATIONS
// =============================================================================

/// Animation durations.
abstract class AppDetailsDurations {
  /// Snackbar duration.
  static const Duration snackbar = Duration(seconds: 2);

  /// Quick snackbar duration.
  static const Duration snackbarQuick = Duration(seconds: 1);
}
