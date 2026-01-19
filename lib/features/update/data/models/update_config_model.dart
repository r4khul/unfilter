library;

import 'package:pub_semver/pub_semver.dart';

class UpdateConfigModel {
  final Version latestNativeVersion;

  final Version minSupportedNativeVersion;

  final String releasePageUrl;

  final String apkDirectDownloadUrl;

  final Map<String, String>? apkPerAbiUrls;

  final bool usePerAbi;

  final String? releaseNotes;

  final bool forceUpdate;

  final List<String> features;

  final List<String> fixes;

  static const List<String> _abiPriority = [
    'arm64-v8a',
    'armeabi-v7a',
    'x86_64',
    'x86',
  ];

  const UpdateConfigModel({
    required this.latestNativeVersion,
    required this.minSupportedNativeVersion,
    required this.releasePageUrl,
    required this.apkDirectDownloadUrl,
    this.apkPerAbiUrls,
    this.usePerAbi = false,
    this.releaseNotes,
    required this.forceUpdate,
    this.features = const [],
    this.fixes = const [],
  });

  bool get hasChangelog => features.isNotEmpty || fixes.isNotEmpty;

  int get totalChanges => features.length + fixes.length;

  bool get hasPerAbiUrls =>
      usePerAbi && apkPerAbiUrls != null && apkPerAbiUrls!.isNotEmpty;

  String getDownloadUrlForAbi(String? deviceAbi) {
    if (!hasPerAbiUrls || deviceAbi == null || deviceAbi.isEmpty) {
      return apkDirectDownloadUrl;
    }

    final normalizedAbi = deviceAbi.toLowerCase().trim();

    for (final abi in _abiPriority) {
      if (normalizedAbi.contains(abi) && apkPerAbiUrls!.containsKey(abi)) {
        return apkPerAbiUrls![abi]!;
      }
    }

    if (apkPerAbiUrls!.containsKey(normalizedAbi)) {
      return apkPerAbiUrls![normalizedAbi]!;
    }

    return apkDirectDownloadUrl;
  }

  factory UpdateConfigModel.fromJson(Map<String, dynamic> json) {
    try {
      Map<String, String>? perAbiUrls;
      final abiUrlsJson = json['apk_per_abi_urls'];
      if (abiUrlsJson != null && abiUrlsJson is Map) {
        perAbiUrls = Map<String, String>.from(
          abiUrlsJson.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ),
        );
      }

      return UpdateConfigModel(
        latestNativeVersion: Version.parse(
          json['latest_native_version'] as String,
        ),
        minSupportedNativeVersion: Version.parse(
          json['min_supported_native_version'] as String,
        ),
        releasePageUrl: json['release_page_url'] as String,
        apkDirectDownloadUrl: json['apk_direct_download_url'] as String,
        apkPerAbiUrls: perAbiUrls,
        usePerAbi: json['use_per_abi'] as bool? ?? false,
        releaseNotes: json['release_notes'] as String?,
        forceUpdate: json['force_update'] as bool? ?? false,
        features:
            (json['features'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        fixes:
            (json['fixes'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );
    } catch (e) {
      throw FormatException('Failed to parse UpdateConfigModel: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_native_version': latestNativeVersion.toString(),
      'min_supported_native_version': minSupportedNativeVersion.toString(),
      'release_page_url': releasePageUrl,
      'apk_direct_download_url': apkDirectDownloadUrl,
      'apk_per_abi_urls': apkPerAbiUrls,
      'use_per_abi': usePerAbi,
      'release_notes': releaseNotes,
      'force_update': forceUpdate,
      'features': features,
      'fixes': fixes,
    };
  }
}
