library;

import 'package:flutter/material.dart';

Color getStackColor(String stack, bool isDark) {
  switch (stack.toLowerCase()) {
    case 'flutter':
      return isDark ? const Color(0xFF5CACEE) : const Color(0xFF1E88E5);
    case 'react native':
      return isDark ? const Color(0xFF61DAFB) : const Color(0xFF00ACC1);
    case 'kotlin':
      return isDark ? const Color(0xFFB388FF) : const Color(0xFF7C4DFF);
    case 'jetpack compose':
    case 'jetpack':
      return isDark ? const Color(0xFF42D08D) : const Color(0xFF00C853);
    case 'java':
      return isDark ? const Color(0xFFEF9A9A) : const Color(0xFFE53935);
    case 'pwa':
      return isDark ? const Color(0xFFB39DDB) : const Color(0xFF7E57C2);
    case 'ionic':
      return isDark ? const Color(0xFF90CAF9) : const Color(0xFF42A5F5);
    case 'cordova':
      return isDark ? const Color(0xFFB0BEC5) : const Color(0xFF78909C);
    case 'xamarin':
      return isDark ? const Color(0xFF81D4FA) : const Color(0xFF29B6F6);
    case 'nativescript':
      return isDark ? const Color(0xFF80CBC4) : const Color(0xFF26A69A);
    case 'unity':
      return isDark ? const Color(0xFFEDEDED) : const Color(0xFF424242);
    case 'godot':
      return isDark ? const Color(0xFF81D4FA) : const Color(0xFF039BE5);
    case 'corona':
      return isDark ? const Color(0xFFFFCC80) : const Color(0xFFEF6C00);
    default:
      return isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
  }
}

String getStackIconPath(String stack) {
  final stackLower = stack.toLowerCase();
  switch (stackLower) {
    case 'flutter':
      return 'assets/vectors/icon_flutter.svg';
    case 'react native':
      return 'assets/vectors/icon_react.svg';
    case 'kotlin':
      return 'assets/vectors/icon_kotlin.svg';
    case 'jetpack compose':
    case 'jetpack':
      return 'assets/vectors/icon_jetpack.svg';
    case 'java':
      return 'assets/vectors/icon_java.svg';
    case 'pwa':
      return 'assets/vectors/icon_pwa.svg';
    case 'ionic':
      return 'assets/vectors/icon_ionic.svg';
    case 'cordova':
      return 'assets/vectors/icon_cordova.svg';
    case 'xamarin':
      return 'assets/vectors/icon_xamarin.svg';
    case 'nativescript':
      return 'assets/vectors/icon_nativescript.svg';
    case 'unity':
      return 'assets/vectors/icon_unity.svg';
    case 'godot':
      return 'assets/vectors/icon_godot.svg';
    case 'corona':
      return 'assets/vectors/icon_corona.svg';
    default:
      return 'assets/vectors/icon_native.svg';
  }
}

String getSdkVersionName(int sdk) {
  if (sdk >= 35) return "Android 15+";
  if (sdk == 34) return "Android 14";
  if (sdk == 33) return "Android 13";
  if (sdk == 32) return "Android 12L";
  if (sdk == 31) return "Android 12";
  if (sdk == 30) return "Android 11";
  if (sdk == 29) return "Android 10";
  if (sdk == 28) return "Pie";
  if (sdk == 27) return "Oreo 8.1";
  if (sdk == 26) return "Oreo 8.0";
  if (sdk == 25) return "Nougat 7.1";
  if (sdk == 24) return "Nougat 7.0";
  if (sdk == 23) return "Marshmallow";
  if (sdk == 22) return "Lollipop 5.1";
  if (sdk == 21) return "Lollipop 5.0";
  return "API $sdk";
}

String formatBytes(int bytes) {
  if (bytes < 1024) return "$bytes B";
  if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
  if (bytes < 1024 * 1024 * 1024) {
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }
  return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
}

String formatInstallerName(String installer) {
  if (installer.contains('google') ||
      installer.contains('com.android.vending')) {
    return 'Google Play Store';
  }
  if (installer.contains('samsung')) {
    return 'Samsung Galaxy Store';
  }
  if (installer.contains('amazon')) {
    return 'Amazon Appstore';
  }
  if (installer.contains('xiaomi') || installer.contains('miui')) {
    return 'Mi GetApps';
  }
  if (installer.contains('huawei')) {
    return 'Huawei AppGallery';
  }
  if (installer.contains('oppo')) {
    return 'Oppo App Market';
  }
  if (installer.contains('vivo')) {
    return 'Vivo App Store';
  }
  if (installer.contains('oneplus')) {
    return 'OnePlus Store';
  }
  if (installer.contains('fdroid')) {
    return 'F-Droid';
  }
  if (installer.contains('apkpure')) {
    return 'APKPure';
  }
  if (installer.contains('apkmirror')) {
    return 'APKMirror';
  }
  if (installer.contains('package.installer') ||
      installer.contains('com.android.packageinstaller')) {
    return 'Package Installer (Sideloaded)';
  }
  return installer;
}

String formatNumber(int number) {
  return number.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}
