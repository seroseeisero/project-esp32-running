import 'package:flutter/material.dart';

import '../models/models.dart';

/// สีของ Heatmap ตามค่า 0..1 (น้ำเงิน → เขียว → เหลือง → แดง)
Color heatColor(double v) {
  const stops = [
    Color(0xFF2962FF),
    Color(0xFF00C853),
    Color(0xFFFFD600),
    Color(0xFFD50000),
  ];
  final x = v.clamp(0.0, 1.0) * (stops.length - 1);
  final i = x.floor().clamp(0, stops.length - 2);
  return Color.lerp(stops[i], stops[i + 1], x - i)!;
}

/// รูปเท้าพร้อม Heatmap แรงกดของเซนเซอร์ 5 จุด และตำแหน่ง CoP
class FootHeatmap extends StatelessWidget {
  const FootHeatmap({
    super.key,
    required this.values,
    this.cop,
    this.trail = const [],
    this.mirror = false,
  });

  /// ค่า 0..1 ของ FSR1..FSR5
  final List<double> values;
  final Offset? cop;
  final List<Offset> trail;

  /// true = เท้าซ้าย (กลับด้านซ้าย-ขวา)
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.5,
      child: CustomPaint(
        painter: _FootPainter(
          values: values,
          cop: cop,
          trail: trail,
          mirror: mirror,
          base: Theme.of(context).colorScheme.surfaceContainerHighest,
          outline: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _FootPainter extends CustomPainter {
  _FootPainter({
    required this.values,
    required this.cop,
    required this.trail,
    required this.mirror,
    required this.base,
    required this.outline,
  });

  final List<double> values;
  final Offset? cop;
  final List<Offset> trail;
  final bool mirror;
  final Color base;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    Offset p(double x, double y) =>
        Offset((mirror ? 1 - x : x) * size.width, y * size.height);

    final path = Path();
    final start = p(0.30, 0.03);
    path.moveTo(start.dx, start.dy);
    void curve(double x1, double y1, double x2, double y2, double x3, double y3) {
      final a = p(x1, y1), b = p(x2, y2), c = p(x3, y3);
      path.cubicTo(a.dx, a.dy, b.dx, b.dy, c.dx, c.dy);
    }

    curve(0.12, 0.05, 0.08, 0.25, 0.14, 0.42); // ขอบด้านใน (medial) ช่วงปลายเท้า
    curve(0.20, 0.55, 0.26, 0.65, 0.28, 0.78); // โค้งอุ้งเท้า
    curve(0.28, 0.92, 0.40, 0.99, 0.52, 0.99); // ส้นเท้าด้านใน
    curve(0.68, 0.99, 0.78, 0.92, 0.76, 0.78); // ส้นเท้าด้านนอก
    curve(0.76, 0.62, 0.90, 0.50, 0.92, 0.35); // ขอบด้านนอก (lateral)
    curve(0.94, 0.20, 0.82, 0.08, 0.62, 0.06); // ปลายเท้าด้านนอก
    curve(0.52, 0.02, 0.40, 0.00, 0.30, 0.03); // นิ้วเท้า
    path.close();

    canvas.drawPath(path, Paint()..color = base);

    // Heatmap ภายในรูปเท้า
    canvas.save();
    canvas.clipPath(path);
    final radius = size.width * 0.34;
    for (var i = 0; i < kFsrCount && i < values.length; i++) {
      final v = values[i].clamp(0.0, 1.0).toDouble();
      if (v < 0.02) continue;
      final center = p(kFsr[i].pos.dx, kFsr[i].pos.dy);
      final color = heatColor(v);
      final paint = Paint()
        ..shader = RadialGradient(colors: [
          color.withValues(alpha: 0.35 + 0.6 * v),
          color.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
    canvas.restore();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = outline,
    );

    // เส้นทาง CoP
    if (trail.length > 1) {
      final tp = Path();
      for (var i = 0; i < trail.length; i++) {
        final o = p(trail[i].dx, trail[i].dy);
        if (i == 0) {
          tp.moveTo(o.dx, o.dy);
        } else {
          tp.lineTo(o.dx, o.dy);
        }
      }
      canvas.drawPath(
        tp,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = Colors.black.withValues(alpha: 0.55),
      );
    }

    // ตำแหน่งเซนเซอร์ (หมายเลข 1-5)
    for (var i = 0; i < kFsrCount; i++) {
      final c = p(kFsr[i].pos.dx, kFsr[i].pos.dy);
      canvas.drawCircle(c, 11, Paint()..color = Colors.white);
      canvas.drawCircle(c, 9, Paint()..color = kFsr[i].color);
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }

    // ศูนย์กลางแรงกด (CoP)
    if (cop != null) {
      final c = p(cop!.dx, cop!.dy);
      final pen = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.black;
      canvas.drawCircle(c, 9, pen);
      canvas.drawLine(c - const Offset(14, 0), c + const Offset(14, 0), pen);
      canvas.drawLine(c - const Offset(0, 14), c + const Offset(0, 14), pen);
    }
  }

  @override
  bool shouldRepaint(covariant _FootPainter old) => true;
}
