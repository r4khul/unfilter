library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/device_apps_repository.dart';
import '../../domain/entities/device_app.dart';
import 'app_details_page.dart';

class AppDetailsByPackagePage extends ConsumerStatefulWidget {
  final String packageName;
  final String? appName;

  const AppDetailsByPackagePage({
    super.key,
    required this.packageName,
    this.appName,
  });

  @override
  ConsumerState<AppDetailsByPackagePage> createState() =>
      _AppDetailsByPackagePageState();
}

class _AppDetailsByPackagePageState
    extends ConsumerState<AppDetailsByPackagePage> {
  final DeviceAppsRepository _repository = DeviceAppsRepository();
  DeviceApp? _app;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppDetails();
  }

  Future<void> _loadAppDetails() async {
    try {
      final apps = await _repository.getAppsDetails([widget.packageName]);
      if (apps.isNotEmpty && mounted) {
        setState(() {
          _app = apps.first;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _error = 'App not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load app details';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(widget.appName ?? 'Loading...'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _app == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(widget.appName ?? 'Error'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: theme.colorScheme.error.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'App not found',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                widget.packageName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return AppDetailsPage(app: _app!);
  }
}
