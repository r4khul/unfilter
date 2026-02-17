import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/device_apps_repository.dart';
import '../../domain/entities/device_app.dart';

final deviceAppsRepositoryProvider = Provider((ref) => DeviceAppsRepository());

class InstalledAppsNotifier extends AsyncNotifier<List<DeviceApp>> {
  bool _isScanInProgress = false;

  bool _isRevalidating = false;
  DateTime? _lastRevalidationTime;
  static const Duration _revalidationCooldown = Duration(seconds: 30);

  @override
  Future<List<DeviceApp>> build() async {
    final repository = ref.watch(deviceAppsRepositoryProvider);

    try {
      final cached = await repository.getInstalledApps(forceRefresh: false);
      if (cached.isNotEmpty) {
        return cached;
      }
    } catch (e) {
      // Ignore cache loading error
    }

    return [];
  }

  Future<void> fullScan() async {
    if (_isScanInProgress) {
      debugPrint("[Unfilter] fullScan: Scan already in progress, skipping");
      return;
    }

    _isScanInProgress = true;
    final repository = ref.read(deviceAppsRepositoryProvider);

    try {
      state = const AsyncValue.loading();
      await repository.clearCache();
      state = await AsyncValue.guard(
        () => repository.getInstalledApps(forceRefresh: true),
      );
      _lastRevalidationTime = DateTime.now();
    } finally {
      _isScanInProgress = false;
    }
  }

  Future<void> backgroundRevalidate() async {
    if (_isScanInProgress) {
      debugPrint(
        "[Unfilter] backgroundRevalidate: Full scan in progress, skipping",
      );
      return;
    }

    if (_isRevalidating) {
      debugPrint(
        "[Unfilter] backgroundRevalidate: Already revalidating, skipping",
      );
      return;
    }

    if (_lastRevalidationTime != null) {
      final elapsed = DateTime.now().difference(_lastRevalidationTime!);
      if (elapsed < _revalidationCooldown) {
        debugPrint(
          "[Unfilter] backgroundRevalidate: Cooldown active (${elapsed.inSeconds}s < ${_revalidationCooldown.inSeconds}s), skipping",
        );
        return;
      }
    }

    final currentApps = switch (state) {
      AsyncData(:final value) => value,
      _ => <DeviceApp>[],
    };
    if (currentApps.isEmpty) {
      debugPrint(
        "[Unfilter] backgroundRevalidate: No existing data, skipping (use fullScan instead)",
      );
      return;
    }

    _isRevalidating = true;
    debugPrint("[Unfilter] backgroundRevalidate: Starting...");

    try {
      await revalidate(cachedApps: currentApps);
      _lastRevalidationTime = DateTime.now();
      debugPrint("[Unfilter] backgroundRevalidate: Complete");
    } catch (e) {
      debugPrint("[Unfilter] backgroundRevalidate: Failed - $e");
    } finally {
      _isRevalidating = false;
    }
  }

  Future<DeviceApp?> resyncApp(String packageName) async {
    final repository = ref.read(deviceAppsRepositoryProvider);

    try {
      debugPrint("[Unfilter] ResyncApp: Fetching details for $packageName");

      final details = await repository.getAppsDetails([packageName]);

      if (details.isEmpty) {
        debugPrint(
          "[Unfilter] ResyncApp: No details returned for $packageName",
        );
        return null;
      }

      final updatedApp = details.first;
      debugPrint(
        "[Unfilter] ResyncApp: Got updated details for ${updatedApp.appName}",
      );

      final currentApps = switch (state) {
        AsyncData(:final value) => value,
        _ => <DeviceApp>[],
      };
      final updatedApps = currentApps.map((app) {
        if (app.packageName == packageName) {
          return updatedApp;
        }
        return app;
      }).toList();

      await repository.updateCache(updatedApps);
      state = AsyncValue.data(updatedApps);

      debugPrint("[Unfilter] ResyncApp: Updated cache and state");
      return updatedApp;
    } catch (e) {
      debugPrint("[Unfilter] ResyncApp: Failed - $e");
      return null;
    }
  }

  Future<void> revalidate({List<DeviceApp>? cachedApps}) async {
    final repository = ref.read(deviceAppsRepositoryProvider);

    try {
      debugPrint("[Unfilter] Revalidate: Start");
      final appsToCheck =
          cachedApps ?? await repository.getInstalledApps(forceRefresh: false);
      final cachedMap = {for (var app in appsToCheck) app.packageName: app};
      debugPrint(
        "[Unfilter] Revalidate: Cached apps count: ${appsToCheck.length}",
      );

      debugPrint("[Unfilter] Revalidate: Fetching lite apps...");
      final liteApps = await repository.getInstalledApps(
        forceRefresh: true,
        includeDetails: false,
      );
      debugPrint("[Unfilter] Revalidate: Lite apps count: ${liteApps.length}");

      final finalApps = <DeviceApp>[];
      final appsToResolve = <String>[];

      for (var liteApp in liteApps) {
        final cached = cachedMap[liteApp.packageName];
        if (cached != null && cached.updateDate == liteApp.updateDate) {
          finalApps.add(cached);
        } else {
          appsToResolve.add(liteApp.packageName);
        }
      }

      debugPrint(
        "[Unfilter] Revalidate: Need to resolve ${appsToResolve.length} apps",
      );
      if (appsToResolve.isNotEmpty) {
        final details = await repository.getAppsDetails(appsToResolve);
        finalApps.addAll(details);
        debugPrint("[Unfilter] Revalidate: Resolved details");
      }

      debugPrint("[Unfilter] Revalidate: Updating cache and state");
      await repository.updateCache(finalApps);

      state = AsyncValue.data(finalApps);
      debugPrint("[Unfilter] Revalidate: Done");
    } catch (e) {
      debugPrint("Revalidate failed: $e");
    }
  }
}

final installedAppsProvider =
    AsyncNotifierProvider<InstalledAppsNotifier, List<DeviceApp>>(() {
      return InstalledAppsNotifier();
    });

final usagePermissionProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(deviceAppsRepositoryProvider);
  return await repository.checkUsagePermission();
});
