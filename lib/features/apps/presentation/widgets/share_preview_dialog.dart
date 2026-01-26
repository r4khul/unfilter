import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/device_app.dart';
import 'customizable_share_poster.dart';
import 'share_options_config.dart';
import 'share_config_notifier.dart';

class SharePreviewDialog extends StatefulWidget {
  final DeviceApp app;

  const SharePreviewDialog({super.key, required this.app});

  static Future<void> show(BuildContext context, DeviceApp app) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      enableDrag: true,
      useSafeArea: true,
      builder: (context) => SharePreviewDialog(app: app),
    );
  }

  @override
  State<SharePreviewDialog> createState() => _SharePreviewDialogState();
}

class _SharePreviewDialogState extends State<SharePreviewDialog>
    with SingleTickerProviderStateMixin {
  final GlobalKey _posterKey = GlobalKey();
  late final ShareConfigNotifier _configNotifier;
  bool _isSharing = false;

  late final AnimationController _entranceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _configNotifier = ShareConfigNotifier();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _configNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      await _waitForFrame();

      final posterContext = _posterKey.currentContext;
      if (posterContext == null) throw Exception("Poster not found");

      final boundary =
          posterContext.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("Boundary not found");

      for (int i = 0; i < 3; i++) {
        await _waitForFrame();
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception("Failed to encode image");

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/unfilter_custom_${widget.app.packageName.hashCode}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      if (mounted) navigator.pop();

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: _buildShareText(_configNotifier.value),
        ),
      );
    } catch (e) {
      debugPrint("Share error: $e");
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("Failed to share: ${e.toString()}"),
            backgroundColor: errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _waitForFrame() async {
    await WidgetsBinding.instance.endOfFrame;
  }

  String _buildShareText(ShareOptionsConfig config) {
    final buffer = StringBuffer();
    buffer.writeln("${widget.app.appName} just got exposed 🔍");
    buffer.writeln();
    buffer.writeln("Built with: ${widget.app.stack}");

    if (config.showVersion) {
      buffer.writeln("Version: ${widget.app.version}");
    }
    if (config.showSize) {
      buffer.writeln("Size: ${_formatBytes(widget.app.size)}");
    }

    buffer.writeln();
    buffer.writeln("See what your apps are really made of.");
    buffer.writeln("github.com/r4khul/unfilter/releases/latest");
    buffer.writeln();
    buffer.writeln("Don't forget to give a star!");

    return buffer.toString();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1024 * 1024 * 1024) {
      return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    }
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: _BackdropContainer(
            isDark: isDark,
            child: Container(
              height: screenHeight * 0.85,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0D0D0D).withOpacity(0.95)
                    : const Color(0xFFF8F8F8).withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Column(
                children: [
                  _DialogHeader(configNotifier: _configNotifier),
                  _OptionsRow(app: widget.app, configNotifier: _configNotifier),
                  Expanded(
                    child: _PreviewSection(
                      posterKey: _posterKey,
                      app: widget.app,
                      configNotifier: _configNotifier,
                    ),
                  ),
                  _ShareButton(isSharing: _isSharing, onShare: _handleShare),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackdropContainer extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _BackdropContainer({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: isDark ? 30 : 15,
          sigmaY: isDark ? 30 : 15,
        ),
        child: child,
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final ShareConfigNotifier configNotifier;

  const _DialogHeader({required this.configNotifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Customize & Share",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                _ThemeToggle(configNotifier: configNotifier),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final ShareConfigNotifier configNotifier;

  const _ThemeToggle({required this.configNotifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: ValueListenableBuilder<ShareOptionsConfig>(
        valueListenable: configNotifier,
        builder: (context, config, _) {
          return GestureDetector(
            onTap: configNotifier.togglePosterDarkMode,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: config.posterDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    config.posterDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    config.posterDarkMode ? "Dark" : "Light",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OptionsRow extends StatelessWidget {
  final DeviceApp app;
  final ShareConfigNotifier configNotifier;

  const _OptionsRow({required this.app, required this.configNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ShareOptionsConfig>(
      valueListenable: configNotifier,
      builder: (context, config, _) {
        final options = <_OptionData>[
          _OptionData(
            "Version",
            Icons.info_outline_rounded,
            config.showVersion,
            configNotifier.toggleVersion,
          ),
          _OptionData(
            "SDK",
            Icons.developer_mode_rounded,
            config.showSdk,
            configNotifier.toggleSdk,
          ),
          _OptionData(
            "Usage",
            Icons.access_time_rounded,
            config.showUsage,
            configNotifier.toggleUsage,
          ),
          _OptionData(
            "Install Date",
            Icons.calendar_today_rounded,
            config.showInstallDate,
            configNotifier.toggleInstallDate,
          ),
          _OptionData(
            "Size",
            Icons.storage_rounded,
            config.showSize,
            configNotifier.toggleSize,
          ),
          if (app.installerStore != 'Unknown')
            _OptionData(
              "Source",
              Icons.store_rounded,
              config.showSource,
              configNotifier.toggleSource,
            ),
          if (app.techVersions.isNotEmpty)
            _OptionData(
              "Tech",
              Icons.code_rounded,
              config.showTechVersions,
              configNotifier.toggleTechVersions,
            ),
          _OptionData(
            "Components",
            Icons.widgets_rounded,
            config.showComponents,
            configNotifier.toggleComponents,
          ),
          if (app.splitApks.isNotEmpty)
            _OptionData(
              "Splits",
              Icons.extension_rounded,
              config.showSplitApks,
              configNotifier.toggleSplitApks,
            ),
        ];

        return SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return _OptionChip(option: options[index]);
            },
          ),
        );
      },
    );
  }
}

class _OptionChip extends StatelessWidget {
  final _OptionData option;

  const _OptionChip({required this.option});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: option.onToggle,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: option.isEnabled
                ? theme.colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1)
                : theme.colorScheme.onSurface.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: option.isEnabled
                  ? theme.colorScheme.primary.withOpacity(0.4)
                  : theme.colorScheme.onSurface.withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (option.isEnabled) ...[
                Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                option.icon,
                size: 14,
                color: option.isEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                option.label,
                style: TextStyle(
                  color: option.isEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: option.isEnabled
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewSection extends StatelessWidget {
  final GlobalKey posterKey;
  final DeviceApp app;
  final ShareConfigNotifier configNotifier;

  const _PreviewSection({
    required this.posterKey,
    required this.app,
    required this.configNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ValueListenableBuilder<ShareOptionsConfig>(
                valueListenable: configNotifier,
                builder: (context, config, _) {
                  return RepaintBoundary(
                    key: posterKey,
                    child: CustomizableSharePoster(app: app, config: config),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final bool isSharing;
  final VoidCallback onShare;

  const _ShareButton({required this.isSharing, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: GestureDetector(
            onTap: isSharing ? null : onShare,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: isSharing
                    ? null
                    : LinearGradient(
                        colors: isDark
                            ? [const Color(0xFFFFFFFF), const Color(0xFFE8E8E8)]
                            : [
                                const Color(0xFF1A1A1A),
                                const Color(0xFF000000),
                              ],
                      ),
                color: isSharing
                    ? theme.colorScheme.onSurface.withOpacity(0.1)
                    : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSharing
                    ? null
                    : [
                        BoxShadow(
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Center(
                child: isSharing
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.colorScheme.onSurface,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.ios_share_rounded,
                            size: 20,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Share Image",
                            style: TextStyle(
                              color: isDark ? Colors.black : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionData {
  final String label;
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onToggle;

  const _OptionData(this.label, this.icon, this.isEnabled, this.onToggle);
}
