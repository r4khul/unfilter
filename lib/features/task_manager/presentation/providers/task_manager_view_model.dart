import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../apps/domain/entities/device_app.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import '../../domain/entities/android_process.dart';
import 'process_provider.dart';

class TaskManagerData {
  final List<AndroidProcess> shellProcesses;
  final List<DeviceApp> activeApps;
  final Map<String, AndroidProcess> matches;

  const TaskManagerData({
    this.shellProcesses = const [],
    this.activeApps = const [],
    this.matches = const {},
  });
}

final taskManagerViewModelProvider =
    Provider.autoDispose<AsyncValue<TaskManagerData>>((ref) {
      final appsState = ref.watch(installedAppsProvider);
      final processesState = ref.watch(activeProcessesProvider);

      if (appsState.isLoading || processesState.isLoading) {
        return const AsyncValue.loading();
      }

      if (appsState.hasError) {
        return AsyncValue.error(appsState.error!, appsState.stackTrace!);
      }
      if (processesState.hasError) {
        return AsyncValue.error(
          processesState.error!,
          processesState.stackTrace!,
        );
      }

      final shellProcesses = processesState.value ?? [];
      final userApps = appsState.value ?? [];

      // Filter: Active in last 24h
      final activeApps = userApps.where((app) {
        final lastUsed = DateTime.fromMillisecondsSinceEpoch(app.lastTimeUsed);
        final diff = DateTime.now().difference(lastUsed);
        return diff.inHours < 24;
      }).toList();

      // Sort by most recent
      activeApps.sort((a, b) => b.lastTimeUsed.compareTo(a.lastTimeUsed));

      // Match processes
      final matches = <String, AndroidProcess>{};
      for (final app in activeApps) {
        try {
          final match = shellProcesses.firstWhere(
            (p) =>
                p.name.contains(app.packageName) ||
                app.packageName.contains(p.name),
            // orElse is implicitly throwing StateError, handled by try-catch usually or we check carefully
          );
          matches[app.packageName] = match;
        } catch (_) {
          // No match found
        }
      }

      return AsyncValue.data(
        TaskManagerData(
          shellProcesses: shellProcesses,
          activeApps: activeApps,
          matches: matches,
        ),
      );
    });
