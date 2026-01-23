library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/update_repository.dart';
import '../../domain/update_service.dart';
import '../../../../core/services/connectivity_service.dart';

enum UpdateErrorType {
  offline,

  serverUnreachable,

  parseError,

  downloadInterrupted,

  fileSystemError,

  installationFailed,

  unknown,
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

final connectivityStatusProvider = FutureProvider<ConnectivityStatus>((
  ref,
) async {
  final service = ref.read(connectivityServiceProvider);
  return service.checkConnectivity();
});

final updateServiceProvider = Provider<UpdateService>((ref) {
  throw UnimplementedError('Use updateServiceFutureProvider');
});

final updateServiceFutureProvider = FutureProvider<UpdateService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final repo = UpdateRepository(prefs: prefs);
  return UpdateService(repo);
});

const String _kCachedForceUpdateKey = 'cached_force_update_status';
const String _kCachedMinVersionKey = 'cached_min_supported_version';
const String _kCachedLatestVersionKey = 'cached_latest_version';
const String _kCachedReleasePageUrlKey = 'cached_release_page_url';

final updateCheckProvider = FutureProvider<UpdateCheckResult>((ref) async {
  final connectivity = ref.read(connectivityServiceProvider);
  final status = await connectivity.checkConnectivity();
  final prefs = await ref.watch(sharedPreferencesProvider.future);

  if (status == ConnectivityStatus.offline) {
    // Check if we have a cached force update status
    final cachedForceUpdate = prefs.getBool(_kCachedForceUpdateKey) ?? false;
    if (cachedForceUpdate) {
      final cachedMinVersion = prefs.getString(_kCachedMinVersionKey);
      final cachedLatestVersion = prefs.getString(_kCachedLatestVersionKey);
      final cachedReleasePageUrl = prefs.getString(_kCachedReleasePageUrlKey);

      // Return a force update result with cached data
      return UpdateCheckResult(
        status: UpdateStatus.forceUpdate,
        error: 'Update required. Connect to internet to download the update.',
        errorType: UpdateErrorType.offline,
        cachedMinVersion: cachedMinVersion,
        cachedLatestVersion: cachedLatestVersion,
        cachedReleasePageUrl: cachedReleasePageUrl,
      );
    }

    return const UpdateCheckResult(
      status: UpdateStatus.unknown,
      error: 'No internet connection. Please connect to WiFi or mobile data.',
      errorType: UpdateErrorType.offline,
    );
  }

  final service = await ref.watch(updateServiceFutureProvider.future);
  final result = await service.checkUpdate();

  // Cache the force update status for offline access
  if (result.status == UpdateStatus.forceUpdate) {
    await prefs.setBool(_kCachedForceUpdateKey, true);
    if (result.config?.minSupportedNativeVersion != null) {
      await prefs.setString(
        _kCachedMinVersionKey,
        result.config!.minSupportedNativeVersion.toString(),
      );
    }
    if (result.config?.latestNativeVersion != null) {
      await prefs.setString(
        _kCachedLatestVersionKey,
        result.config!.latestNativeVersion.toString(),
      );
    }
    if (result.config?.releasePageUrl != null) {
      await prefs.setString(
        _kCachedReleasePageUrlKey,
        result.config!.releasePageUrl,
      );
    }
  } else {
    // Clear cached force update if no longer needed
    await prefs.remove(_kCachedForceUpdateKey);
    await prefs.remove(_kCachedMinVersionKey);
    await prefs.remove(_kCachedLatestVersionKey);
    await prefs.remove(_kCachedReleasePageUrlKey);
  }

  return result;
});

final currentVersionProvider = FutureProvider<Version>((ref) async {
  final service = await ref.watch(updateServiceFutureProvider.future);
  return service.getCurrentVersion();
});

class DownloadState {
  final double progress;

  final bool isDownloading;

  final bool isDone;

  final String? error;

  final UpdateErrorType? errorType;

  final String? filePath;

  const DownloadState({
    this.progress = 0.0,
    this.isDownloading = false,
    this.isDone = false,
    this.error,
    this.errorType,
    this.filePath,
  });

  bool get isNetworkError =>
      errorType == UpdateErrorType.offline ||
      errorType == UpdateErrorType.serverUnreachable ||
      errorType == UpdateErrorType.downloadInterrupted;

  DownloadState copyWith({
    double? progress,
    bool? isDownloading,
    bool? isDone,
    String? error,
    UpdateErrorType? errorType,
    String? filePath,
  }) {
    return DownloadState(
      progress: progress ?? this.progress,
      isDownloading: isDownloading ?? this.isDownloading,
      isDone: isDone ?? this.isDone,
      error: error,
      errorType: errorType,
      filePath: filePath ?? this.filePath,
    );
  }
}

class UpdateDownloadController extends Notifier<DownloadState> {
  @override
  DownloadState build() {
    return const DownloadState();
  }

  Future<void> downloadAndInstall(String url, String version) async {
    if (state.isDownloading) return;

    if (state.isDone && state.filePath != null) {
      await _installExistingFile();
      return;
    }

    final connectivityStatus = await _checkConnectivityBeforeDownload();
    if (connectivityStatus == ConnectivityStatus.offline) {
      state = DownloadState(
        error:
            'No internet connection. Please connect to WiFi or mobile data to download the update.',
        errorType: UpdateErrorType.offline,
      );
      return;
    }

    state = const DownloadState(isDownloading: true);

    try {
      await _performDownload(url, version);
    } on SocketException catch (_) {
      _handleSocketException();
    } on FileSystemException catch (e) {
      _handleFileSystemException(e);
    } catch (e) {
      _handleGenericException(e);
    }
  }

  Future<void> _installExistingFile() async {
    final file = File(state.filePath!);
    if (await file.exists()) {
      final serviceAsync = ref.read(updateServiceFutureProvider);
      if (serviceAsync.hasValue) {
        try {
          await serviceAsync.value!.installApk(file);
        } catch (e) {
          state = state.copyWith(
            error: 'Installation failed. Please try again.',
            errorType: UpdateErrorType.installationFailed,
          );
        }
      }
    }
  }

  Future<ConnectivityStatus> _checkConnectivityBeforeDownload() async {
    final connectivity = ref.read(connectivityServiceProvider);
    return connectivity.checkConnectivity();
  }

  Future<void> _performDownload(String url, String version) async {
    final serviceAsync = ref.read(updateServiceFutureProvider);
    if (!serviceAsync.hasValue) {
      throw Exception('Update service not ready');
    }
    final service = serviceAsync.value!;

    final file = await service.downloadApk(
      url,
      version,
      onProgress: (p) {
        state = state.copyWith(progress: p);
      },
    );

    state = state.copyWith(
      isDownloading: false,
      isDone: true,
      progress: 1.0,
      filePath: file.path,
    );

    await service.installApk(file);
  }

  void _handleSocketException() {
    state = DownloadState(
      error:
          'Connection lost during download. Please check your internet and try again.',
      errorType: UpdateErrorType.downloadInterrupted,
    );
  }

  void _handleFileSystemException(FileSystemException e) {
    state = DownloadState(
      error: 'Unable to save update file: ${e.message}',
      errorType: UpdateErrorType.fileSystemError,
    );
  }

  void _handleGenericException(Object e) {
    final errorMsg = e.toString().toLowerCase();
    UpdateErrorType errorType = UpdateErrorType.unknown;
    String userMessage = 'Download failed. Please try again.';

    if (errorMsg.contains('socket') ||
        errorMsg.contains('connection') ||
        errorMsg.contains('network') ||
        errorMsg.contains('timeout')) {
      errorType = UpdateErrorType.downloadInterrupted;
      userMessage =
          'Connection error. Please check your internet and try again.';
    } else if (errorMsg.contains('permission') ||
        errorMsg.contains('denied') ||
        errorMsg.contains('storage')) {
      errorType = UpdateErrorType.fileSystemError;
      userMessage =
          'Storage permission required. Please check app permissions.';
    }

    state = DownloadState(error: userMessage, errorType: errorType);
  }

  Future<ConnectivityStatus> checkConnectivity() async {
    final connectivity = ref.read(connectivityServiceProvider);
    return connectivity.checkConnectivity();
  }

  void reset() {
    state = const DownloadState();
  }
}

final updateDownloadProvider =
    NotifierProvider<UpdateDownloadController, DownloadState>(
      UpdateDownloadController.new,
    );
