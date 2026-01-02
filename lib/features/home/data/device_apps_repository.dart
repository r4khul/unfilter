import 'package:flutter/services.dart';
import '../domain/device_app.dart';

class DeviceAppsRepository {
  static const platform = MethodChannel('com.rakhul.findstack/apps');

  Future<List<DeviceApp>> getInstalledApps() async {
    try {
      final List<Object?> result = await platform.invokeMethod(
        'getInstalledApps',
      );
      return result
          .cast<Map<Object?, Object?>>()
          .map((e) => DeviceApp.fromMap(e))
          .toList();
    } on PlatformException catch (e) {
      print("Failed to get apps: '${e.message}'");
      return [];
    }
  }

  Future<bool> checkUsagePermission() async {
    try {
      final bool result = await platform.invokeMethod('checkUsagePermission');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check permission: '${e.message}'");
      return false;
    }
  }

  Future<void> requestUsagePermission() async {
    try {
      await platform.invokeMethod('requestUsagePermission');
    } on PlatformException catch (e) {
      print("Failed to request permission: '${e.message}'");
    }
  }
}
