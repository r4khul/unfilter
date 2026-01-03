import 'dart:math' as math;
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
      // Standard "pro" feel duration and curve
      duration: const Duration(milliseconds: 650),
    );
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Explicitly dispose of the old screenshot to free GPU memory immediately
        _screenshot?.dispose();
        _screenshot = null;
        _center = null;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _screenshot?.dispose();
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
      // MICRO-OPTIMIZATION:
      // Cap the pixel ratio to max 1.5. On high-res screens (3.0+), capturing
      // full resolution is unnecessary for a sub-second animation and causes frame drops.
      // 1.5 provides crisp enough visuals without the heavy GPU/Memory cost.
      final deviceRatio = View.of(context).devicePixelRatio;
      final pixelRatio = deviceRatio > 1.5 ? 1.5 : deviceRatio;

      final image = await boundary.toImage(pixelRatio: pixelRatio);

      setState(() {
        _screenshot = image;
        _center = center;
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
    final child = RepaintBoundary(key: _repaintKey, child: widget.child);

    // If we have a screenshot and are animating, overlay it
    if (_screenshot == null || _center == null || !_controller.isAnimating) {
      return child;
    }

    return Stack(
      children: [
        // 1. The NEW theme (Active App) running underneath
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

  // Reusable paint object to avoid allocation on every frame
  static final Paint _paint = Paint();

  _ClipRevealPainter({
    required this.image,
    required this.center,
    required this.percent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // MICRO-OPTIMIZATION: Use basic math, avoid extra object creations where possible

    // Calculate max radius to cover the screen
    final maxW = size.width;
    final maxH = size.height;

    final dX = center.dx > maxW / 2 ? center.dx : maxW - center.dx;
    final dY = center.dy > maxH / 2 ? center.dy : maxH - center.dy;

    // Simple Pythagorean theorem without Offset object creation
    final maxRadius = (dX * dX + dY * dY).toDouble() + 50;

    // Use easeInOutCubic for that "smoothy" organic feel (starts slow, fast middle, ends slow)
    // We manually calculate sqrt of maxRadius effectively here for the distance
    final radius =
        math.sqrt(maxRadius) * Curves.easeInOutCubic.transform(percent);

    final rect = Rect.fromLTWH(0, 0, maxW, maxH);

    // We must create a new path each frame as the geometry changes completely
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.save();
    canvas.clipPath(path);

    // Draw the image scaled to fit the view (prevents zoomed-in effect)
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      ), // Source
      Rect.fromLTWH(0, 0, size.width, size.height), // Destination
      _paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ClipRevealPainter oldDelegate) {
    return oldDelegate.percent != percent;
  }
}
