library;

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
