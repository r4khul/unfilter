/// The app details page displaying comprehensive app information.
///
/// This page shows:
/// - App header with icon, name, and tech stack
/// - Version and SDK information
/// - Usage statistics and charts
/// - Deep technical insights
/// - Native libraries (if any)
/// - Detected packages/SDKs
/// - Permissions (if any)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/widgets/premium_sliver_app_bar.dart';
import '../../domain/entities/device_app.dart';
import '../providers/app_detail_provider.dart';
import '../providers/apps_provider.dart';
import '../widgets/app_details/app_details_widgets.dart';
import '../widgets/share_preview_dialog.dart';

/// The main app details page.
///
/// Displays comprehensive information about an installed application
/// including technical details, usage statistics, and insights.
class AppDetailsPage extends ConsumerStatefulWidget {
  /// The app to display details for.
  final DeviceApp app;

  /// Creates an app details page.
  const AppDetailsPage({super.key, required this.app});

  @override
  ConsumerState<AppDetailsPage> createState() => _AppDetailsPageState();
}

class _AppDetailsPageState extends ConsumerState<AppDetailsPage> {
  /// Whether a resync operation is in progress.
  bool _isResyncing = false;

  /// The current app data (may be updated after resync).
  late DeviceApp _currentApp;

  /// Convenience getter for the current app.
  DeviceApp get app => _currentApp;

  @override
  void initState() {
    super.initState();
    _currentApp = widget.app;
  }

  /// Handles resyncing app data from the system.
  Future<void> _handleResync() async {
    if (_isResyncing) return;

    setState(() => _isResyncing = true);

    try {
      // Invalidate cached usage history
      ref.invalidate(appUsageHistoryProvider(_currentApp.packageName));

      // Fetch updated app data
      final updatedApp = await ref
          .read(installedAppsProvider.notifier)
          .resyncApp(_currentApp.packageName);

      if (updatedApp != null && mounted) {
        setState(() {
          _currentApp = updatedApp;
        });

        _showSnackbar(
          icon: Icons.check_circle_rounded,
          message: 'App data refreshed',
          isSuccess: true,
        );
      }
    } catch (e) {
      debugPrint('Resync error: $e');
      if (mounted) {
        _showSnackbar(
          icon: Icons.error_outline_rounded,
          message: 'Failed to resync',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isResyncing = false);
    }
  }

  /// Shows a premium styled snackbar.
  void _showSnackbar({
    required IconData icon,
    required String message,
    required bool isSuccess,
  }) {
    showPremiumSnackbar(
      context: context,
      icon: icon,
      message: message,
      isSuccess: isSuccess,
    );
  }

  /// Opens the share dialog for this app.
  void _openShareDialog() {
    SharePreviewDialog.show(context, app);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usageHistoryAsync = ref.watch(
      appUsageHistoryProvider(app.packageName),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PremiumSliverAppBar(
            title: "App Details",
            onResync: _isResyncing ? null : _handleResync,
            onShare: _openShareDialog,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDetailsSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App header with icon, name, stack badge, and share button
                  AppHeaderCard(app: app, onShare: _openShareDialog),
                  const SizedBox(height: AppDetailsSpacing.section),

                  // Version, SDK, and update date stats
                  AppStatsRow(app: app),
                  const SizedBox(height: AppDetailsSpacing.section),

                  // Activity/usage section with chart
                  ActivitySection(app: app, historyAsync: usageHistoryAsync),
                  const SizedBox(height: AppDetailsSpacing.section),

                  // Basic details: Package, UID, Install date
                  AppInfoSection(app: app),
                  const SizedBox(height: AppDetailsSpacing.section),

                  // Deep technical insights
                  DeepInsightsSection(app: app),
                  const SizedBox(height: AppDetailsSpacing.section),

                  // Native libraries (if any)
                  if (app.nativeLibraries.isNotEmpty) ...[
                    NativeLibsSection(app: app),
                    const SizedBox(height: AppDetailsSpacing.section),
                  ],

                  // Detected packages/SDKs
                  DeveloperSection(app: app),
                  const SizedBox(height: AppDetailsSpacing.section),

                  // Permissions (if any)
                  if (app.permissions.isNotEmpty) ...[
                    PermissionsSection(app: app),
                    const SizedBox(height: AppDetailsSpacing.bottom),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
