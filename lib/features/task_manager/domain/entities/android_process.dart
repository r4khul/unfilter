library;

class AndroidProcess {
  final String pid;
  final String user;
  final String name;
  final String cpu;
  final String mem;
  final String res;
  final String vsz;
  final String status;

  final int? threads;
  final int? nice;
  final int? priority;
  final String? args;
  final String? startTime;

  // Cached uppercase status for fast comparisons
  late final String _statusUpper;

  AndroidProcess({
    required this.pid,
    required this.user,
    required this.name,
    this.cpu = "0.0",
    this.mem = "0.0",
    this.res = "0",
    this.vsz = "0",
    this.status = "S",
    this.threads,
    this.nice,
    this.priority,
    this.args,
    this.startTime,
  }) {
    _statusUpper = status.toUpperCase();
  }

  /// Empty placeholder for pre-allocation
  static final empty = AndroidProcess(pid: '0', user: '', name: '');

  factory AndroidProcess.fromMap(Map<Object?, Object?> map) {
    return AndroidProcess(
      pid: map['pid']?.toString() ?? "?",
      user: map['user']?.toString() ?? "?",
      name: map['name']?.toString() ?? "Unknown",
      cpu: map['cpu']?.toString() ?? "0.0",
      mem: map['mem']?.toString() ?? "0.0",
      res: map['res']?.toString() ?? "0",
      vsz: map['vsz']?.toString() ?? "0",
      status: map['s']?.toString() ?? "S",
      threads: _parseIntOrNull(map['threads']),
      nice: _parseIntOrNull(map['nice']),
      priority: _parseIntOrNull(map['priority']),
      args: map['args']?.toString(),
      startTime: map['startTime']?.toString(),
    );
  }

  static int? _parseIntOrNull(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  String get statusDescription {
    switch (_statusUpper) {
      case 'R':
        return 'Running';
      case 'S':
        return 'Sleeping';
      case 'D':
        return 'Disk Sleep';
      case 'T':
        return 'Stopped';
      case 'Z':
        return 'Zombie';
      case 'X':
        return 'Dead';
      case 'I':
        return 'Idle';
      default:
        return 'Unknown';
    }
  }

  bool get isRunning => _statusUpper == 'R';
  bool get isSleeping => _statusUpper == 'S';
  bool get isZombie => _statusUpper == 'Z';
  bool get isRootProcess => user == 'root';

  String get formattedMemory {
    final resValue = int.tryParse(res) ?? 0;
    if (resValue >= 1024 * 1024) {
      return '${(resValue / (1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (resValue >= 1024) {
      return '${(resValue / 1024).toStringAsFixed(1)} MB';
    }
    return '$resValue KB';
  }

  double get cpuUsage => double.tryParse(cpu) ?? 0.0;
  double get memUsage => double.tryParse(mem) ?? 0.0;
  bool get isActive => cpuUsage > 0;
}
