library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../apps/domain/entities/device_app.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import '../../domain/entities/android_process.dart';
import 'process_provider.dart';

class TaskManagerData {
  final List<AndroidProcess> shellProcesses;
  final List<DeviceApp> activeApps;
  final Map<String, AndroidProcess> matches;
  final bool isRefreshingProcesses;
  final DateTime? processesLastUpdated;
  final ProcessFetchException? processError;

  const TaskManagerData({
    this.shellProcesses = const [],
    this.activeApps = const [],
    this.matches = const {},
    this.isRefreshingProcesses = false,
    this.processesLastUpdated,
    this.processError,
  });

  bool get hasProcessError => processError != null;
  bool get hasProcessData => shellProcesses.isNotEmpty;
  bool get hasAppsData => activeApps.isNotEmpty;
}

final taskManagerViewModelProvider =
    Provider.autoDispose<AsyncValue<TaskManagerData>>((ref) {
      final appsState = ref.watch(installedAppsProvider);
      final processesState = ref.watch(activeProcessesProvider);

      final processListState = processesState.when(
        data: (state) => state,
        loading: () => const ProcessListState(isRefreshing: true),
        error: (e, _) => ProcessListState(
          error: e is ProcessFetchException
              ? e
              : ProcessFetchException('Unknown error', e),
        ),
      );

      if (appsState.isLoading && !processListState.hasData) {
        return const AsyncValue.loading();
      }

      if (appsState.hasError && processListState.hasError) {
        return AsyncValue.error(appsState.error!, appsState.stackTrace!);
      }

      final shellProcesses = processListState.processes;
      final userApps = appsState.value ?? [];

      final activeApps = _filterRecentlyActiveApps(userApps);
      activeApps.sort((a, b) => b.lastTimeUsed.compareTo(a.lastTimeUsed));

      final matches = _matchProcessesToApps(activeApps, shellProcesses);

      return AsyncValue.data(
        TaskManagerData(
          shellProcesses: shellProcesses,
          activeApps: activeApps,
          matches: matches,
          isRefreshingProcesses: processListState.isRefreshing,
          processesLastUpdated: processListState.lastUpdated,
          processError: processListState.error,
        ),
      );
    });

List<DeviceApp> _filterRecentlyActiveApps(List<DeviceApp> apps) {
  return apps.where((app) {
    final lastUsed = DateTime.fromMillisecondsSinceEpoch(app.lastTimeUsed);
    final diff = DateTime.now().difference(lastUsed);
    return diff.inHours < 24;
  }).toList();
}

Map<String, AndroidProcess> _matchProcessesToApps(
  List<DeviceApp> apps,
  List<AndroidProcess> processes,
) {
  final matches = <String, AndroidProcess>{};

  for (final app in apps) {
    try {
      final match = processes.firstWhere(
        (p) =>
            p.name.contains(app.packageName) ||
            app.packageName.contains(p.name),
      );
      matches[app.packageName] = match;
    } catch (_) {}
  }

  return matches;
}
