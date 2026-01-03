import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A wrapper that facilitates a smooth circular reveal animation when switching themes.
///
/// This widget should be placed in the [MaterialApp.builder] property.
/// It works by:
/// 1. Capturing a screenshot of the current UI (old theme).
/// 2. Switching the theme (which rebuilds the app with the new theme).
/// 3. Overlaying the screenshot on top of the new theme.
/// 4. Animating a circular clip (hole) in the screenshot to reveal the new theme underneath.
class ThemeTransitionWrapper extends StatefulWidget {
  final Widget child;

  const ThemeTransitionWrapper({super.key, required this.child});

  static ThemeTransitionWrapperState of(BuildContext context) {
    return context.findAncestorStateOfType<ThemeTransitionWrapperState>()!;
  }

  @override
  State<ThemeTransitionWrapper> createState() => ThemeTransitionWrapperState();
}

class ThemeTransitionWrapperState extends State<ThemeTransitionWrapper>
    with SingleTickerProviderStateMixin {
  final GlobalKey _repaintKey = GlobalKey();

  ui.Image? _screenshot;
  Offset? _center;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 650,
      ), // Standard "pro" feel duration
    );
    _controller.addListener(() {
      setState(() {}); // Rebuild to animate the clipper
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Cleanup after animation
        setState(() {
          _screenshot = null;
          _center = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Triggers the theme switch animation.
  ///
  /// [center] is the point onscreen where the transition starts (e.g. the button).
  /// [onThemeSwitch] is the closure that actually updates the app's theme state.
  Future<void> switchTheme({
    required Offset center,
    required VoidCallback onThemeSwitch,
  }) async {
    // 1. Capture the current state
    final boundary =
        _repaintKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary != null && boundary.debugNeedsPaint == false) {
      // pixelRatio 1.0 is usually enough for transition and faster
      final image = await boundary.toImage(
        pixelRatio: ui.window.devicePixelRatio,
      );

      setState(() {
        _screenshot = image;
        _center = center;
        // _themeSwitchCallback = onThemeSwitch; // Not needed as we call it immediately
      });

      // 2. Perform the actual theme switch logic (rebuilds the widget tree)
      onThemeSwitch();

      // 3. Reset and start the animation
      _controller.forward(from: 0.0);
    } else {
      // Fallback if capture fails
      onThemeSwitch();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we have a screenshot and are animating, we show:
    // Bottom: New Theme (the normal child)
    // Top: Screenshot of Old Theme (clipped)

    // We want the NEW theme to "expand" from the center.
    // This means the NEW theme is visible inside the expanding circle,
    // and the OLD theme (screenshot) is visible outside.

    // So:
    // Layer 1 (Bottom): The Screenshot (Old Theme).
    // Layer 2 (Top): The Child (New Theme).
    // Clip: We clip the Top layer (New Theme) to a growing circle.

    // OR:
    // Layer 1 (Bottom): The Child (New Theme).
    // Layer 2 (Top): The Screenshot (Old Theme).
    // Clip: We clip the Top layer (Old Theme) to have a growing HOLE.
    // This is equivalent to `PathFillType.evenOdd`.

    // We will use the second approach:
    // The App (New Theme) runs underneath.
    // The Screenshot (Old Theme) sits on top, covering it.
    // We "erase" the Screenshot with an expanding circle.

    final child = RepaintBoundary(key: _repaintKey, child: widget.child);

    if (_screenshot == null || _center == null || !_controller.isAnimating) {
      return child;
    }

    return Stack(
      children: [
        // 1. The NEW theme (Active App)
        child,

        // 2. The OLD theme (Screenshot) with a growing hole
        Positioned.fill(
          child: CustomPaint(
            painter: _ClipRevealPainter(
              image: _screenshot!,
              center: _center!,
              percent: _controller.value,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClipRevealPainter extends CustomPainter {
  final ui.Image image;
  final Offset center;
  final double percent;

  _ClipRevealPainter({
    required this.image,
    required this.center,
    required this.percent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the old screenshot
    // But we need to "punch a hole" in it.

    // Calculate max radius to cover the screen
    final distanceToHzCorner = center.dx > size.width / 2
        ? center.dx
        : size.width - center.dx;
    final distanceToVtCorner = center.dy > size.height / 2
        ? center.dy
        : size.height - center.dy;
    final maxRadius =
        (Offset(distanceToHzCorner, distanceToVtCorner)).distance + 20;

    final radius = maxRadius * Curves.easeIn.transform(percent);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Create a path that covers the whole screen MINUS the circle
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.save();
    canvas.clipPath(path);
    canvas.drawImage(image, Offset.zero, Paint());
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ClipRevealPainter oldDelegate) {
    return oldDelegate.percent != percent;
  }
}
