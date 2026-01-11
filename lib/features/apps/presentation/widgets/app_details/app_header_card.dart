library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../domain/entities/device_app.dart';
import 'constants.dart';
import 'utils.dart';

class AppHeaderCard extends StatelessWidget {
  final DeviceApp app;

  final VoidCallback onShare;

  const AppHeaderCard({super.key, required this.app, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stackColor = getStackColor(app.stack, isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAppIcon(theme, stackColor),
        const SizedBox(height: AppDetailsSpacing.xl),
        _buildAppName(theme),
        const SizedBox(height: AppDetailsSpacing.sm),
        _buildPackageName(theme),
        const SizedBox(height: AppDetailsSpacing.standard),
        _buildStackBadge(stackColor),
        const SizedBox(height: AppDetailsSpacing.lg),
        _buildShareButton(theme),
      ],
    );
  }

  Widget _buildAppIcon(ThemeData theme, Color stackColor) {
    return Hero(
      tag: app.packageName,
      child: Container(
        width: AppDetailsSizes.appIconSize,
        height: AppDetailsSizes.appIconSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDetailsBorderRadius.xl),
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(AppDetailsOpacity.light),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: EdgeInsets.all(app.icon == null ? AppDetailsSpacing.xl : 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDetailsBorderRadius.xl),
          child: app.icon != null
              ? Image.memory(app.icon!, fit: BoxFit.cover)
              : Center(
                  child: Text(
                    app.appName.isNotEmpty ? app.appName[0].toUpperCase() : "?",
                    style: TextStyle(
                      fontSize: AppDetailsFontSizes.iconPlaceholder,
                      fontWeight: FontWeight.bold,
                      color: stackColor,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAppName(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDetailsSpacing.standard,
      ),
      child: Text(
        app.appName,
        textAlign: TextAlign.center,
        style: theme.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPackageName(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDetailsSpacing.xl),
      child: Text(
        app.packageName,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(
            AppDetailsOpacity.high,
          ),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStackBadge(Color stackColor) {
    final displayName = app.stack == 'Jetpack' ? 'Jetpack Compose' : app.stack;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDetailsSpacing.standard,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: stackColor.withOpacity(AppDetailsOpacity.subtle),
        borderRadius: BorderRadius.circular(AppDetailsBorderRadius.xl),
        border: Border.all(
          color: stackColor.withOpacity(AppDetailsOpacity.mediumLight),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            getStackIconPath(app.stack),
            width: AppDetailsSizes.techStackIconSize,
            height: AppDetailsSizes.techStackIconSize,
          ),
          const SizedBox(width: AppDetailsSpacing.sm),
          Text(
            displayName,
            style: TextStyle(
              color: stackColor,
              fontWeight: FontWeight.bold,
              fontSize: AppDetailsFontSizes.standard,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(ThemeData theme) {
    return GestureDetector(
      onTap: onShare,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDetailsSpacing.lg,
          vertical: AppDetailsSpacing.md,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppDetailsBorderRadius.xl),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(
              AppDetailsOpacity.mediumLight,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.ios_share_rounded,
              size: AppDetailsSizes.iconMedium,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppDetailsSpacing.sm),
            Text(
              "Share App Details",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: AppDetailsFontSizes.standard,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
