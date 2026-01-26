import 'package:flutter/foundation.dart';
import 'share_options_config.dart';

class ShareConfigNotifier extends ValueNotifier<ShareOptionsConfig> {
  ShareConfigNotifier() : super(const ShareOptionsConfig());

  void updateConfig(ShareOptionsConfig newConfig) {
    if (value != newConfig) {
      value = newConfig;
    }
  }

  void toggleVersion() =>
      value = value.copyWith(showVersion: !value.showVersion);
  void toggleSdk() => value = value.copyWith(showSdk: !value.showSdk);
  void toggleUsage() => value = value.copyWith(showUsage: !value.showUsage);
  void toggleInstallDate() =>
      value = value.copyWith(showInstallDate: !value.showInstallDate);
  void toggleSize() => value = value.copyWith(showSize: !value.showSize);
  void toggleSource() => value = value.copyWith(showSource: !value.showSource);
  void toggleTechVersions() =>
      value = value.copyWith(showTechVersions: !value.showTechVersions);
  void toggleComponents() =>
      value = value.copyWith(showComponents: !value.showComponents);
  void toggleSplitApks() =>
      value = value.copyWith(showSplitApks: !value.showSplitApks);
  void togglePosterDarkMode() =>
      value = value.copyWith(posterDarkMode: !value.posterDarkMode);
}
