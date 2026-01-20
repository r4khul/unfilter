library;

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

const int kMaxHistoryPoints = 15;

class ProcessHistory {
  final String pid;

  final List<ProcessSnapshot> _buffer = List.filled(
    kMaxHistoryPoints,
    _emptySnapshot,
  );
  int _head = 0;
  int _count = 0;

  static final _emptySnapshot = ProcessSnapshot(
    cpu: 0,
    memory: 0,
    timestamp: DateTime(1970),
  );

  ProcessHistory({required this.pid});

  int get length => _count;

  DateTime? get lastTimestamp {
    if (_count == 0) return null;
    final idx = (_head - 1 + kMaxHistoryPoints) % kMaxHistoryPoints;
    return _buffer[idx].timestamp;
  }

  List<double> get cpuHistory {
    if (_count == 0) return const [];
    final result = List<double>.filled(_count, 0.0);
    for (int i = 0; i < _count; i++) {
      final idx = (_head - _count + i + kMaxHistoryPoints) % kMaxHistoryPoints;
      result[i] = _buffer[idx].cpu;
    }
    return result;
  }

  List<double> get memoryHistory {
    if (_count == 0) return const [];
    final result = List<double>.filled(_count, 0.0);
    for (int i = 0; i < _count; i++) {
      final idx = (_head - _count + i + kMaxHistoryPoints) % kMaxHistoryPoints;
      result[i] = _buffer[idx].memory;
    }
    return result;
  }

  double get currentCpu {
    if (_count == 0) return 0;
    final idx = (_head - 1 + kMaxHistoryPoints) % kMaxHistoryPoints;
    return _buffer[idx].cpu;
  }

  double get currentMemory {
    if (_count == 0) return 0;
    final idx = (_head - 1 + kMaxHistoryPoints) % kMaxHistoryPoints;
    return _buffer[idx].memory;
  }

  bool get hasEnoughData => _count >= 2;

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

  void addSnapshotFast(double cpu, double memory) {
    _buffer[_head] = ProcessSnapshot(
      cpu: cpu,
      memory: memory,
      timestamp: DateTime.now(),
    );
    _head = (_head + 1) % kMaxHistoryPoints;
    if (_count < kMaxHistoryPoints) _count++;
  }

  void addSnapshot(ProcessSnapshot snapshot) {
    _buffer[_head] = snapshot;
    _head = (_head + 1) % kMaxHistoryPoints;
    if (_count < kMaxHistoryPoints) _count++;
  }

  void clear() {
    _head = 0;
    _count = 0;
  }

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
