library;

import 'android_process.dart';
import 'process_snapshot.dart';

/// An Android process combined with its historical usage data.
/// Used for rendering sparkline visualizations in the Task Manager.
///
/// Performance optimized:
/// - Cached computed properties
/// - Lazy evaluation where possible
/// - Minimal allocations
class ProcessWithHistory {
  final AndroidProcess process;
  final List<double> cpuHistory;
  final List<double> memoryHistory;

  // Cached values
  late final double _currentCpu;
  late final int _intensityLevel;
  late final bool _shouldGlow;

  ProcessWithHistory({
    required this.process,
    this.cpuHistory = const [],
    this.memoryHistory = const [],
  }) {
    _currentCpu = double.tryParse(process.cpu) ?? 0.0;
    _intensityLevel = _computeIntensity(_currentCpu);
    _shouldGlow = _intensityLevel >= 3;
  }

  /// Empty placeholder for pre-allocation
  static final empty = ProcessWithHistory(
    process: AndroidProcess.empty,
    cpuHistory: const [],
    memoryHistory: const [],
  );

  /// Whether we have enough history for visualization
  bool get hasHistory => cpuHistory.length >= 2;

  /// Get current CPU as double (cached)
  double get currentCpu => _currentCpu;

  /// Get intensity level for color coding (0-4) - cached
  int get intensityLevel => _intensityLevel;

  /// Whether this process should show a warning glow - cached
  bool get shouldGlow => _shouldGlow;

  /// Calculate CPU trend: rising, falling, or stable
  ResourceTrend get cpuTrend {
    final len = cpuHistory.length;
    if (len < 3) return ResourceTrend.stable;

    // Fast average calculation of last 3
    final sum = cpuHistory[len - 1] + cpuHistory[len - 2] + cpuHistory[len - 3];
    final avg = sum / 3;
    final diff = avg - cpuHistory[len - 3];

    if (diff > 5) return ResourceTrend.rising;
    if (diff < -5) return ResourceTrend.falling;
    return ResourceTrend.stable;
  }

  static int _computeIntensity(double cpu) {
    if (cpu < 5) return 0;
    if (cpu < 15) return 1;
    if (cpu < 35) return 2;
    if (cpu < 60) return 3;
    return 4;
  }

  /// Create from an AndroidProcess and ProcessHistory
  factory ProcessWithHistory.fromHistory(
    AndroidProcess process,
    ProcessHistory? history,
  ) {
    return ProcessWithHistory(
      process: process,
      cpuHistory: history?.cpuHistory ?? const [],
      memoryHistory: history?.memoryHistory ?? const [],
    );
  }
}

enum ResourceTrend { rising, stable, falling }
