library;

/// A single point-in-time snapshot of a process's resource usage.
/// Used for building history buffers for sparkline visualizations.
class ProcessSnapshot {
  final double cpu;
  final double memory;
  final DateTime timestamp;

  const ProcessSnapshot({
    required this.cpu,
    required this.memory,
    required this.timestamp,
  });
}

/// Maximum number of history points to keep (15 points × 2s = 30 seconds)
const int kMaxHistoryPoints = 15;

/// Maintains a fixed-size circular buffer of process snapshots.
/// Performance optimized: no list resizing, O(1) add, minimal allocations.
class ProcessHistory {
  final String pid;

  // Fixed-size circular buffer
  final List<ProcessSnapshot> _buffer = List.filled(
    kMaxHistoryPoints,
    _emptySnapshot,
  );
  int _head = 0; // Next write position
  int _count = 0; // Current number of valid items

  static final _emptySnapshot = ProcessSnapshot(
    cpu: 0,
    memory: 0,
    timestamp: DateTime(1970),
  );

  ProcessHistory({required this.pid});

  /// Number of valid snapshots
  int get length => _count;

  /// Last timestamp for stale detection
  DateTime? get lastTimestamp {
    if (_count == 0) return null;
    final idx = (_head - 1 + kMaxHistoryPoints) % kMaxHistoryPoints;
    return _buffer[idx].timestamp;
  }

  /// CPU usage history as a list of values (0-100)
  /// Returns a view, not a copy when possible
  List<double> get cpuHistory {
    if (_count == 0) return const [];
    final result = List<double>.filled(_count, 0.0);
    for (int i = 0; i < _count; i++) {
      final idx = (_head - _count + i + kMaxHistoryPoints) % kMaxHistoryPoints;
      result[i] = _buffer[idx].cpu;
    }
    return result;
  }

  /// Memory history as a list of percentages
  List<double> get memoryHistory {
    if (_count == 0) return const [];
    final result = List<double>.filled(_count, 0.0);
    for (int i = 0; i < _count; i++) {
      final idx = (_head - _count + i + kMaxHistoryPoints) % kMaxHistoryPoints;
      result[i] = _buffer[idx].memory;
    }
    return result;
  }

  /// Latest CPU value
  double get currentCpu {
    if (_count == 0) return 0;
    final idx = (_head - 1 + kMaxHistoryPoints) % kMaxHistoryPoints;
    return _buffer[idx].cpu;
  }

  /// Latest memory value
  double get currentMemory {
    if (_count == 0) return 0;
    final idx = (_head - 1 + kMaxHistoryPoints) % kMaxHistoryPoints;
    return _buffer[idx].memory;
  }

  /// Whether we have enough data for visualization (at least 2 points)
  bool get hasEnoughData => _count >= 2;

  /// CPU trend: positive = rising, negative = falling, 0 = stable
  double get cpuTrend {
    if (_count < 3) return 0;
    double sum = 0;
    double oldest = 0;
    for (int i = 0; i < 3; i++) {
      final idx = (_head - 3 + i + kMaxHistoryPoints) % kMaxHistoryPoints;
      final cpu = _buffer[idx].cpu;
      sum += cpu;
      if (i == 0) oldest = cpu;
    }
    return (sum / 3) - oldest;
  }

  /// Fast add without allocating ProcessSnapshot externally
  void addSnapshotFast(double cpu, double memory) {
    _buffer[_head] = ProcessSnapshot(
      cpu: cpu,
      memory: memory,
      timestamp: DateTime.now(),
    );
    _head = (_head + 1) % kMaxHistoryPoints;
    if (_count < kMaxHistoryPoints) _count++;
  }

  /// Legacy method for compatibility
  void addSnapshot(ProcessSnapshot snapshot) {
    _buffer[_head] = snapshot;
    _head = (_head + 1) % kMaxHistoryPoints;
    if (_count < kMaxHistoryPoints) _count++;
  }

  void clear() {
    _head = 0;
    _count = 0;
  }

  /// Legacy getter for compatibility
  List<ProcessSnapshot> get snapshots {
    if (_count == 0) return const [];
    final result = <ProcessSnapshot>[];
    for (int i = 0; i < _count; i++) {
      final idx = (_head - _count + i + kMaxHistoryPoints) % kMaxHistoryPoints;
      result.add(_buffer[idx]);
    }
    return result;
  }
}
