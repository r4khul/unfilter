library;

import '../../domain/entities/android_process.dart';
import '../../domain/entities/process_snapshot.dart';
import '../../domain/entities/process_with_history.dart';

class ProcessHistoryTracker {
  final Map<String, ProcessHistory> _historyMap = {};

  final Set<String> _currentPids = {};
  final List<String> _toRemove = [];

  DateTime _staleThreshold = DateTime.now();
  int _updateCount = 0;

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

      var history = _historyMap[pid];
      if (history == null) {
        history = ProcessHistory(pid: pid);
        _historyMap[pid] = history;
      }

      final rawCpu = double.tryParse(process.cpu) ?? 0.0;
      final normalizedCpu = cpuCores > 1
          ? (rawCpu / cpuCores).clamp(0.0, 100.0)
          : rawCpu.clamp(0.0, 100.0);

      history.addSnapshotFast(normalizedCpu, _parseMemoryFast(process.res));

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

    _updateCount++;
    if (_updateCount >= 5) {
      _updateCount = 0;
      _cleanupStaleProcesses();
    }

    return result;
  }

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

    return (memMb / 8192 * 100).clamp(0.0, 100.0);
  }

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
