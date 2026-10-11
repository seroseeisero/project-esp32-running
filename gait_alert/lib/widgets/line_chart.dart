import 'dart:math';

import 'package:flutter/material.dart';

/// กราฟเส้นเล็ก ๆ ไม่พึ่งแพ็กเกจภายนอก
class MiniLineChart extends StatelessWidget {
  const MiniLineChart({
    super.key,
    required this.series,
    required this.colors,
    this.minY,
    this.maxY,
    this.threshold,
    this.height = 80,
  });

  final List<List<double>> series;
  final List<Color> colors;
  final double? minY;
  final double? maxY;

  /// เส้นเกณฑ์ (ประสีแดง)
  final double? threshold;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _LinePainter(
          series: series,
          colors: colors,
          minY: minY,
          maxY: maxY,
          threshold: threshold,
          grid: scheme.outlineVariant,
          label: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.series,
    required this.colors,
    required this.minY,
    required this.maxY,
    required this.threshold,
    required this.grid,
    required this.label,
  });

  final List<List<double>> series;
  final List<Color> colors;
  final double? minY;
  final double? maxY;
  final double? threshold;
  final Color grid;
  final Color label;

  void _text(Canvas canvas, String s, Offset o) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: 9, color: label)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, o);
  }

  @override
  void paint(Canvas canvas, Size size) {
    var lo = minY ?? double.infinity;
    var hi = maxY ?? double.negativeInfinity;
    for (final s in series) {
      for (final v in s) {
        if (minY == null) lo = min(lo, v);
        if (maxY == null) hi = max(hi, v);
      }
    }
    if (threshold != null) {
      if (minY == null) lo = min(lo, threshold!);
      if (maxY == null) hi = max(hi, threshold! * 1.1);
    }
    if (lo == double.infinity || hi == double.negativeInfinity) {
      lo = 0;
      hi = 1;
    }
    if (hi - lo < 1e-6) hi = lo + 1;
    if (minY == null || maxY == null) {
      final pad = (hi - lo) * 0.05;
      if (minY == null) lo -= pad;
      if (maxY == null) hi += pad;
    }

    double yOf(double v) =>
        size.height - ((v - lo) / (hi - lo)).clamp(0.0, 1.0) * size.height;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final y = size.height * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    _text(canvas, hi.toStringAsFixed(1), const Offset(2, 1));
    _text(canvas, lo.toStringAsFixed(1), Offset(2, size.height - 12));

    if (threshold != null) {
      final y = yOf(threshold!);
      final p = Paint()
        ..color = const Color(0xFFC62828)
        ..strokeWidth = 1.5;
      for (var x = 0.0; x < size.width; x += 10) {
        canvas.drawLine(Offset(x, y), Offset(min(x + 5, size.width), y), p);
      }
    }

    for (var k = 0; k < series.length; k++) {
      final s = series[k];
      if (s.isEmpty) continue;
      final path = Path();
      for (var i = 0; i < s.length; i++) {
        final x = s.length == 1 ? 0.0 : i / (s.length - 1) * size.width;
        final y = yOf(s[i]);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..color = colors[k % colors.length],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}
