library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/update_service.dart';
import '../providers/update_provider.dart';
import 'constants.dart';
import 'update_download_button.dart';

class ForceUpdateScreen extends ConsumerWidget {
  final UpdateCheckResult result;

  const ForceUpdateScreen({super.key, required this.result});

  bool get _isOffline => result.errorType == UpdateErrorType.offline;

  String? get _releasePageUrl => result.releasePageUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            _buildAmbientGlow(theme),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: UpdateSpacing.xl,
                  vertical: UpdateSpacing.hero,
                ),
                child: Column(
                  children: [
                    const Spacer(),
                    _buildHeroIcon(theme, isDark),
                    const SizedBox(height: UpdateSpacing.sectionLarge),
                    _buildTitle(theme),
                    const SizedBox(height: UpdateSpacing.standard),
                    _buildDescription(theme),
                    const SizedBox(height: UpdateSpacing.sectionLarge),
                    _buildVersionComparison(theme),
                    const Spacer(),
                    if (result.config?.releaseNotes != null) ...[
                      const SizedBox(height: UpdateSpacing.xl),
                      _buildReleaseNotesCard(theme),
                    ],
                    const SizedBox(height: UpdateSpacing.hero),
                    // Show download button only when online with config
                    if (!_isOffline && result.config != null) ...[
                      UpdateDownloadButton(
                        config: result.config,
                        version:
                            result.config?.latestNativeVersion.toString() ??
                            'latest',
                        isFullWidth: true,
                      ),
                      const SizedBox(height: UpdateSpacing.md),
                      _buildGitHubReleasesButton(theme, isSecondary: true),
                    ] else ...[
                      // Offline mode - show GitHub button as primary action
                      _buildOfflineNotice(theme),
                      const SizedBox(height: UpdateSpacing.standard),
                      _buildGitHubReleasesButton(theme, isSecondary: false),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineNotice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UpdateSpacing.standard,
        vertical: UpdateSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(UpdateBorderRadius.md),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: Colors.orange.shade700,
            size: UpdateSizes.iconSizeSmall,
          ),
          const SizedBox(width: UpdateSpacing.sm),
          Expanded(
            child: Text(
              'Connect to internet to download the update',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGitHubReleasesButton(
    ThemeData theme, {
    required bool isSecondary,
  }) {
    final releaseUrl = _releasePageUrl;

    if (releaseUrl == null) return const SizedBox.shrink();

    if (isSecondary) {
      final latestVersion = result.config?.latestNativeVersion;
      final targetUrl = latestVersion != null
          ? '$releaseUrl/tag/v$latestVersion'
          : '$releaseUrl/latest';

      // Compact text button for secondary action
      return TextButton.icon(
        onPressed: () => _launchReleases(targetUrl),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(
            horizontal: UpdateSpacing.standard,
            vertical: UpdateSpacing.sm,
          ),
        ),
        icon: Icon(
          Icons.info_outline_rounded,
          size: UpdateSizes.iconSizeSmall,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        label: Text(
          'Find out why this update is required',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final latestVersion = result.config?.latestNativeVersion;
    final targetUrl = latestVersion != null
        ? '$releaseUrl/tag/v$latestVersion'
        : '$releaseUrl/latest';

    // Primary button for offline state
    return SizedBox(
      width: double.infinity,
      height: UpdateSizes.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: () => _launchReleases(targetUrl),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UpdateBorderRadius.standard),
          ),
        ),
        icon: const Icon(Icons.open_in_new_rounded, size: UpdateSizes.iconSize),
        label: const Text(
          'Download from GitHub',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'UncutSans',
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Future<void> _launchReleases(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildAmbientGlow(ThemeData theme) {
    return Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primary.withOpacity(UpdateOpacity.subtle),
        ),
        child: BackdropFilter(filter: largeBlurFilter, child: const SizedBox()),
      ),
    );
  }

  Widget _buildHeroIcon(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(UpdateSpacing.hero),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(
          UpdateOpacity.standard,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(UpdateOpacity.light),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              isDark ? UpdateOpacity.standard : UpdateOpacity.subtle,
            ),
            blurRadius: UpdateBlur.shadow,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.system_security_update_rounded,
        size: UpdateSizes.heroIconSize,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      'Critical Update Required',
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -1.0,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(ThemeData theme) {
    return Text(
      'A critical update is available that improves stability and security.\nYou must update to continue using UnFilter.',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildVersionComparison(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(UpdateSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(
          UpdateOpacity.standard,
        ),
        borderRadius: BorderRadius.circular(UpdateBorderRadius.lg),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(UpdateOpacity.light),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _VersionColumn(
              label: 'Current',
              version: result.currentVersion?.toString() ?? '?',
              isOld: true,
            ),
          ),
          Icon(
            Icons.arrow_forward,
            color: theme.colorScheme.onSurfaceVariant,
            size: UpdateSizes.iconSize,
          ),
          Expanded(
            child: _VersionColumn(
              label: 'Required',
              version: result.latestVersionString ?? 'Latest',
              isHighlight: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseNotesCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(UpdateSpacing.standard),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(UpdateBorderRadius.standard),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.onSurfaceVariant,
            size: UpdateSizes.iconSize,
          ),
          const SizedBox(width: UpdateSpacing.md),
          Expanded(
            child: Text(
              result.config!.releaseNotes!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionColumn extends StatelessWidget {
  final String label;

  final String version;

  final bool isHighlight;

  final bool isOld;

  const _VersionColumn({
    required this.label,
    required this.version,
    this.isHighlight = false,
    this.isOld = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: UpdateSpacing.xs),
        Text(
          version,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: isHighlight
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
