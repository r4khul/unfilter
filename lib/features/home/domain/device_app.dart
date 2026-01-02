class DeviceApp {
  final String appName;
  final String packageName;
  final String version;
  final String stack;
  final List<String> nativeLibraries;
  final bool isSystem;
  final int firstInstallTime;
  final int lastUpdateTime;
  final int minSdkVersion;
  final int targetSdkVersion;
  final List<String> permissions;
  final List<String> services;
  final List<String> receivers;
  final List<String> providers;
  final int totalTimeInForeground; // Milliseconds
  final int lastTimeUsed;
  final int uid;
  final int versionCode;

  DeviceApp({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.stack,
    required this.nativeLibraries,
    required this.isSystem,
    required this.firstInstallTime,
    required this.lastUpdateTime,
    required this.minSdkVersion,
    required this.targetSdkVersion,
    required this.permissions,
    required this.services,
    required this.receivers,
    required this.providers,
    required this.totalTimeInForeground,
    required this.lastTimeUsed,
    required this.uid,
    required this.versionCode,
  });

  factory DeviceApp.fromMap(Map<Object?, Object?> map) {
    return DeviceApp(
      appName: map['appName'] as String? ?? 'Unknown',
      packageName: map['packageName'] as String? ?? '',
      version: map['version'] as String? ?? '',
      stack: map['stack'] as String? ?? 'Unknown',
      nativeLibraries:
          (map['nativeLibraries'] as List<Object?>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isSystem: map['isSystem'] as bool? ?? false,
      firstInstallTime: map['firstInstallTime'] as int? ?? 0,
      lastUpdateTime: map['lastUpdateTime'] as int? ?? 0,
      minSdkVersion: map['minSdkVersion'] as int? ?? 0,
      targetSdkVersion: map['targetSdkVersion'] as int? ?? 0,
      permissions:
          (map['permissions'] as List<Object?>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      services:
          (map['services'] as List<Object?>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      receivers:
          (map['receivers'] as List<Object?>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      providers:
          (map['providers'] as List<Object?>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      totalTimeInForeground: map['totalTimeInForeground'] as int? ?? 0,
      lastTimeUsed: map['lastTimeUsed'] as int? ?? 0,
      uid: map['uid'] as int? ?? 0,
      versionCode: map['versionCode'] as int? ?? 0,
    );
  }

  // Helper getters
  Duration get totalUsageDuration =>
      Duration(milliseconds: totalTimeInForeground);
  DateTime get installDate =>
      DateTime.fromMillisecondsSinceEpoch(firstInstallTime);
  DateTime get updateDate =>
      DateTime.fromMillisecondsSinceEpoch(lastUpdateTime);
  DateTime get lastUsedDate =>
      DateTime.fromMillisecondsSinceEpoch(lastTimeUsed);
}
