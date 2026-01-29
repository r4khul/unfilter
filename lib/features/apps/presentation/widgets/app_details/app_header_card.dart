library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/entities/device_app.dart';
import 'constants.dart';
import 'framework_info.dart';
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

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return GestureDetector(
          onTap: () => _showFrameworkInfo(context, theme),
          child: Container(
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
          ),
        );
      },
    );
  }

  void _showFrameworkInfo(BuildContext context, ThemeData theme) {
    final frameworkInfo = FrameworkInfoData.getInfo(app.stack);
    final isDark = theme.brightness == Brightness.dark;
    final stackColor = getStackColor(app.stack, isDark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            children: [
              // Custom header with tech stack icon
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      children: [
                        // Tech Stack Icon Container
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: stackColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SvgPicture.asset(
                            getStackIconPath(app.stack),
                            width: 22,
                            height: 22,
                            colorFilter: ColorFilter.mode(
                              stackColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title
                        Expanded(
                          child: Text(
                            frameworkInfo.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        // Close Button
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.05,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.05),
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(AppDetailsSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About ${frameworkInfo.name}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDetailsSpacing.md),
                      Text(
                        frameworkInfo.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(
                            AppDetailsOpacity.nearlyOpaque,
                          ),
                          height: 1.5,
                        ),
                      ),
                      if (frameworkInfo.docsUrl != null) ...[
                        const SizedBox(height: AppDetailsSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(frameworkInfo.docsUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppDetailsSpacing.md,
                                horizontal: AppDetailsSpacing.lg,
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
                            icon: Icon(
                              Icons.open_in_new_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            label: Text(
                              'View Official Documentation',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
