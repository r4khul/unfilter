library;

import '../../domain/entities/android_process.dart';
import '../../domain/entities/process_snapshot.dart';
import '../../domain/entities/process_with_history.dart';

/// Tracks process history across multiple refresh cycles.
/// Maintains a map of PID -> ProcessHistory.
///
/// Performance optimizations:
/// - Uses fixed-size circular buffer for history (no list resizing)
/// - Lazy cleanup with batched removal
/// - Minimal object allocations per update cycle
class ProcessHistoryTracker {
  final Map<String, ProcessHistory> _historyMap = {};

  // Reusable sets to avoid allocations per update
  final Set<String> _currentPids = {};
  final List<String> _toRemove = [];

  // Cached DateTime for stale check
  DateTime _staleThreshold = DateTime.now();
  int _updateCount = 0;

  /// Update with new process data, returns processes enriched with history
  /// [cpuCores] is used to normalize CPU values to per-core average
  List<ProcessWithHistory> updateWithProcesses(
    List<AndroidProcess> processes, {
    int cpuCores = 1,
  }) {
    _currentPids.clear();
    final result = List<ProcessWithHistory>.filled(
      processes.length,
      ProcessWithHistory.empty,
      growable: false,
    );

    int resultIndex = 0;
    for (final process in processes) {
      final pid = process.pid;
      _currentPids.add(pid);

      // Get or create history for this PID
      var history = _historyMap[pid];
      if (history == null) {
        history = ProcessHistory(pid: pid);
        _historyMap[pid] = history;
      }

      // Parse and normalize CPU value efficiently
      final rawCpu = double.tryParse(process.cpu) ?? 0.0;
      final normalizedCpu = cpuCores > 1
          ? (rawCpu / cpuCores).clamp(0.0, 100.0)
          : rawCpu.clamp(0.0, 100.0);

      // Add snapshot with normalized CPU (uses circular buffer internally)
      history.addSnapshotFast(normalizedCpu, _parseMemoryFast(process.res));

      // Create normalized process only if CPU changed significantly
      final normalizedProcess = process.cpu == normalizedCpu.toStringAsFixed(1)
          ? process
          : AndroidProcess(
              pid: pid,
              user: process.user,
              name: process.name,
              cpu: normalizedCpu.toStringAsFixed(1),
              mem: process.mem,
              res: process.res,
              vsz: process.vsz,
              status: process.status,
              threads: process.threads,
              nice: process.nice,
              priority: process.priority,
              args: process.args,
              startTime: process.startTime,
            );

      result[resultIndex++] = ProcessWithHistory.fromHistory(
        normalizedProcess,
        history,
      );
    }

    // Cleanup only every 5 updates to reduce overhead
    _updateCount++;
    if (_updateCount >= 5) {
      _updateCount = 0;
      _cleanupStaleProcesses();
    }

    return result;
  }

  /// Fast memory parsing with minimal allocations
  double _parseMemoryFast(String memString) {
    if (memString.isEmpty) return 0.0;

    final len = memString.length;
    if (len < 2) return 0.0;

    final lastChar = memString[len - 1].toUpperCase();
    final numPart = memString.substring(0, len - 1);
    final value = double.tryParse(numPart) ?? 0.0;

    double memMb;
    switch (lastChar) {
      case 'G':
        memMb = value * 1024;
        break;
      case 'M':
        memMb = value;
        break;
      case 'K':
        memMb = value / 1024;
        break;
      default:
        memMb = double.tryParse(memString) ?? 0.0;
    }

    // Rough percentage (assuming 8GB total RAM)
    return (memMb / 8192 * 100).clamp(0.0, 100.0);
  }

  /// Batched cleanup of stale processes
  void _cleanupStaleProcesses() {
    _staleThreshold = DateTime.now().subtract(const Duration(seconds: 30));
    _toRemove.clear();

    for (final entry in _historyMap.entries) {
      if (!_currentPids.contains(entry.key)) {
        final lastTimestamp = entry.value.lastTimestamp;
        if (lastTimestamp == null || lastTimestamp.isBefore(_staleThreshold)) {
          _toRemove.add(entry.key);
        }
      }
    }

    for (final pid in _toRemove) {
      _historyMap.remove(pid);
    }
  }

  void reset() {
    _historyMap.clear();
    _currentPids.clear();
    _updateCount = 0;
  }

  ProcessHistory? getHistory(String pid) => _historyMap[pid];
}
