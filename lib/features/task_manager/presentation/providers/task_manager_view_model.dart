library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/active_app.dart';
import '../../domain/entities/android_process.dart';
import '../../domain/entities/process_with_history.dart';
import 'process_history_tracker.dart';
import 'process_provider.dart';

final _historyTracker = ProcessHistoryTracker();

class TaskManagerData {
  final List<AndroidProcess> shellProcesses;
  final List<ProcessWithHistory> processesWithHistory;
  final List<ActiveApp> activeApps;
  final Map<String, AndroidProcess> matches;
  final bool isRefreshingProcesses;
  final bool isLoadingApps;
  final DateTime? processesLastUpdated;
  final ProcessFetchException? processError;
  final String? appsError;
  final int cpuCores;

  const TaskManagerData({
    this.shellProcesses = const [],
    this.processesWithHistory = const [],
    this.activeApps = const [],
    this.matches = const {},
    this.isRefreshingProcesses = false,
    this.isLoadingApps = false,
    this.processesLastUpdated,
    this.processError,
    this.appsError,
    this.cpuCores = 1,
  });

  bool get hasProcessError => processError != null;
  bool get hasAppsError => appsError != null;
  bool get hasProcessData => shellProcesses.isNotEmpty;
  bool get hasAppsData => activeApps.isNotEmpty;
}

final taskManagerViewModelProvider =
    Provider.autoDispose<AsyncValue<TaskManagerData>>((ref) {
      final activeAppsState = ref.watch(recentlyActiveAppsProvider);
      final processesState = ref.watch(activeProcessesProvider);
      final systemDetails = ref.watch(systemDetailsProvider).asData?.value;

      final cpuCores = systemDetails?.cpuCores ?? 1;

      final processListState = processesState.when(
        data: (state) => state,
        loading: () => const ProcessListState(isRefreshing: true),
        error: (e, _) => ProcessListState(
          error: e is ProcessFetchException
              ? e
              : ProcessFetchException('Unknown error', e),
        ),
      );

      final appsListState = activeAppsState.when(
        data: (state) => state,
        loading: () => const ActiveAppsState(isLoading: true),
        error: (e, _) => ActiveAppsState(error: e.toString()),
      );

      if (processListState.isRefreshing &&
          appsListState.isLoading &&
          !processListState.hasData &&
          !appsListState.hasData) {
        return const AsyncValue.loading();
      }

      if (processListState.hasError &&
          appsListState.hasError &&
          !processListState.hasData &&
          !appsListState.hasData) {
        return AsyncValue.error(
          processListState.error ??
              const ProcessFetchException('Failed to load data'),
          StackTrace.current,
        );
      }

      final shellProcesses = processListState.processes;
      final activeApps = appsListState.apps;

      final processesWithHistory = _historyTracker.updateWithProcesses(
        shellProcesses,
        cpuCores: cpuCores,
      );

      final matches = _matchProcessesToApps(activeApps, shellProcesses);

      return AsyncValue.data(
        TaskManagerData(
          shellProcesses: shellProcesses,
          processesWithHistory: processesWithHistory,
          activeApps: activeApps,
          matches: matches,
          isRefreshingProcesses: processListState.isRefreshing,
          isLoadingApps: appsListState.isLoading,
          processesLastUpdated: processListState.lastUpdated,
          processError: processListState.error,
          appsError: appsListState.error,
          cpuCores: cpuCores,
        ),
      );
    });

Map<String, AndroidProcess> _matchProcessesToApps(
  List<ActiveApp> apps,
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
