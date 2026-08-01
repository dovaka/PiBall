import 'dart:math';

import 'package:flutter/material.dart';

import '../models/wind_layer.dart';
import '../services/units.dart';

class WindProfileChart extends StatelessWidget {
  final List<WindLayer> layers;
  final Units units;

  const WindProfileChart({super.key, required this.layers, required this.units});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 240,
      child: CustomPaint(
        painter: _ProfilePainter(
          layers: layers,
          units: units,
          line: scheme.primary,
          grid: scheme.onSurfaceVariant.withValues(alpha: 0.3),
          text: scheme.onSurfaceVariant,
          warn: scheme.error,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  final List<WindLayer> layers;
  final Units units;
  final Color line, grid, text, warn;

  _ProfilePainter({
    required this.layers,
    required this.units,
    required this.line,
    required this.grid,
    required this.text,
    required this.warn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (layers.isEmpty) return;
    const padL = 48.0, padR = 16.0, padT = 14.0, padB = 30.0;
    final plotW = size.width - padL - padR;
    final plotH = size.height - padT - padB;
    final bottom = padT + plotH;

    final maxHeight =
        layers.map((l) => l.heightFt).reduce(max).clamp(1.0, double.infinity);
    final maxSpeed =
        layers.map((l) => l.speedKts).reduce(max).clamp(5.0, double.infinity);

    final axis = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(Offset(padL, padT), Offset(padL, bottom), axis);
    canvas.drawLine(Offset(padL, bottom), Offset(padL + plotW, bottom), axis);

    double xOf(double kt) => padL + (kt / maxSpeed) * plotW;
    double yOf(double ft) => bottom - (ft / maxHeight) * plotH;

    _label(canvas, '0', Offset(padL - 4, bottom + 4), text, right: true);
    _label(canvas, units.heightLabel(maxHeight), Offset(padL - 4, padT),
        text, right: true);
    _label(canvas, units.speedLabel(maxSpeed),
        Offset(padL + plotW, bottom + 4), text, right: true);

    final sorted = [...layers]..sort((a, b) => a.heightFt.compareTo(b.heightFt));
    final path = Path();
    for (var i = 0; i < sorted.length; i++) {
      final p = Offset(xOf(sorted[i].speedKts), yOf(sorted[i].heightFt));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (final l in sorted) {
      final c = Offset(xOf(l.speedKts), yOf(l.heightFt));
      final dotColor = l.lowElevation ? warn : line;
      canvas.drawCircle(c, 3, Paint()..color = dotColor);
      _arrow(canvas, c, l.headingDeg, dotColor);
    }
  }

  void _arrow(Canvas canvas, Offset center, double bearingDeg, Color color) {
    const len = 13.0;
    final rad = bearingDeg * pi / 180.0;
    final dir = Offset(sin(rad), -cos(rad));
    final tip = center + dir * len;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, tip, paint);

    final back = bearingDeg * pi / 180.0;
    for (final off in [back + 2.6, back - 2.6]) {
      canvas.drawLine(
          tip, tip + Offset(sin(off), -cos(off)) * 5, paint);
    }
  }

  void _label(Canvas canvas, String s, Offset at, Color color,
      {bool right = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: color, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = right ? at.dx - tp.width : at.dx;
    tp.paint(canvas, Offset(dx, at.dy));
  }

  @override
  bool shouldRepaint(_ProfilePainter old) => old.layers != layers;
}
