library;

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// A compact sparkline chart for visualizing process history.
/// Displays a smooth curved line with gradient fill.
///
/// Performance optimizations:
/// - RepaintBoundary for isolation
/// - Cached Paint objects
/// - Efficient shouldRepaint with listEquals
/// - Pre-computed paths
class SparklineChart extends StatelessWidget {
  final List<double> data;
  final double width;
  final double height;
  final Color lineColor;
  final Color? fillColor;
  final double lineWidth;

  const SparklineChart({
    super.key,
    required this.data,
    this.width = 70,
    this.height = 24,
    this.lineColor = const Color(0xFF4CAF50),
    this.fillColor,
    this.lineWidth = 1.5,
  });

  /// Create with intensity-based coloring
  factory SparklineChart.forIntensity({
    Key? key,
    required List<double> data,
    required int intensityLevel,
    double width = 70,
    double height = 24,
  }) {
    final color = _intensityColors[intensityLevel.clamp(0, 4)];
    return SparklineChart(
      key: key,
      data: data,
      width: width,
      height: height,
      lineColor: color,
      fillColor: color.withOpacity(0.2),
    );
  }

  // Pre-computed intensity colors
  static const _intensityColors = [
    Color(0xFF4CAF50), // Idle - Green
    Color(0xFF8BC34A), // Low - Light Green
    Color(0xFFFFC107), // Moderate - Amber
    Color(0xFFFF9800), // High - Orange
    Color(0xFFF44336), // Critical - Red
  ];

  @override
  Widget build(BuildContext context) {
    // Early exit for empty data
    if (data.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    // If only 1 data point, create a flat line
    final displayData = data.length < 2 ? [data.first, data.first] : data;

    return SizedBox(
      width: width,
      height: height,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(width, height),
          isComplex: false,
          willChange: false,
          painter: _SparklinePainter(
            data: displayData,
            lineColor: lineColor,
            fillColor: fillColor,
            lineWidth: lineWidth,
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color? fillColor;
  final double lineWidth;

  // Cached paint objects
  late final Paint _linePaint;
  late final Paint _dotPaint;

  _SparklinePainter({
    required this.data,
    required this.lineColor,
    this.fillColor,
    required this.lineWidth,
  }) {
    _linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    // Fast min/max calculation
    double minVal = data[0], maxVal = data[0];
    for (int i = 1; i < data.length; i++) {
      final v = data[i];
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }

    // Clamp and ensure range
    minVal = minVal.clamp(0.0, 100.0);
    maxVal = maxVal.clamp(1.0, 100.0);
    final range = (maxVal - minVal).clamp(1.0, 100.0);

    const padding = 2.0;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;
    final dataLenMinus1 = data.length - 1;

    // Build points directly
    final points = List<Offset>.generate(data.length, (i) {
      final x = padding + (i / dataLenMinus1) * drawWidth;
      final normalized = (data[i].clamp(0.0, 100.0) - minVal) / range;
      final y = padding + drawHeight - (normalized * drawHeight);
      return Offset(x, y);
    });

    // Create smooth path
    final path = _createSmoothPath(points);

    // Draw fill gradient
    if (fillColor != null) {
      final fillPath = Path.from(path)
        ..lineTo(points.last.dx, size.height)
        ..lineTo(points.first.dx, size.height)
        ..close();

      final gradient = ui.Gradient.linear(Offset.zero, Offset(0, size.height), [
        fillColor!,
        fillColor!.withOpacity(0),
      ]);

      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill,
      );
    }

    // Draw line and dot
    canvas.drawPath(path, _linePaint);
    canvas.drawCircle(points.last, 2.5, _dotPaint);
  }

  Path _createSmoothPath(List<Offset> points) {
    final path = Path()..moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    // Cubic bezier curves for smoothing
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[0];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : p2;

      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) {
    if (old.lineColor != lineColor) return true;
    if (old.data.length != data.length) return true;

    // Fast data comparison
    for (int i = 0; i < data.length; i++) {
      if (old.data[i] != data[i]) return true;
    }
    return false;
  }
}
