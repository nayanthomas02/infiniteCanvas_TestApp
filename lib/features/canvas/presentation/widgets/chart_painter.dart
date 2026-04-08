import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  ChartPainter({
    required this.data,
    this.lineColor = const Color(0xFF6C63FF),
    this.fillColor = const Color(0x306C63FF),
    this.gridColor = const Color(0x1AFFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    final stepX = size.width / (data.length - 1).clamp(1, double.infinity);

    // ── Draw grid lines ──────────────────────────────────────────
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // ── Build path ───────────────────────────────────────────────
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalised = (data[i] - minVal) / range;
      final y = size.height * (1 - normalised);
      points.add(Offset(x, y));
    }

    // Smooth curve via cubic bezier
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    // ── Fill gradient under curve ─────────────────────────────────
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(0, size.height),
      [lineColor.withAlpha(120), lineColor.withAlpha(0)],
    );
    canvas.drawPath(
      fillPath,
      Paint()..shader = gradient,
    );

    // ── Draw line ─────────────────────────────────────────────────
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Draw data point dots ──────────────────────────────────────
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = const Color(0xFF0D0D1A)
      ..style = PaintingStyle.fill;

    for (final pt in points) {
      canvas.drawCircle(pt, 4.5, dotBorderPaint);
      canvas.drawCircle(pt, 3.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(ChartPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.lineColor != lineColor;
}
