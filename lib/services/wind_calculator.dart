import 'dart:math';

import '../models/reading.dart';
import '../models/wind_layer.dart';

const _degPerRad = 180.0 / pi;
const _secPerHr = 3600.0;
const _ftPerNM = 6076.12;

const kMinReliableElevationDeg = 6.0;

List<WindLayer> computeWinds(List<Reading> raw, double ascentRateFtPerMin) {
  if (raw.length < 2) return const [];

  final res = <WindLayer>[];
  double x0 = 0, y0 = 0, h0 = 0;

  for (var i = 0; i < raw.length - 1; i++) {
    final r = raw[i + 1];
    final lowEl = r.el < kMinReliableElevationDeg;

    final ht = r.time / 60.0 * ascentRateFtPerMin;

    final elRad = max(r.el, 0.1) / _degPerRad;
    final hd = ht / tan(elRad);
    final x = hd * cos(r.az / _degPerRad);
    final y = hd * sin(r.az / _degPerRad);

    final dt = r.time - raw[i].time;
    final dh = ht - h0;
    final dx = x - x0;
    final dy = y - y0;
    final dd = sqrt(dx * dx + dy * dy);

    final spd = dd / dt * _secPerHr / _ftPerNM;

    var hdg = atan2(dy, dx) * _degPerRad;
    hdg += 180;
    hdg %= 360;
    if (hdg < 0) hdg += 360;

    res.add(WindLayer(h0 + dh / 2.0, hdg, spd, lowElevation: lowEl));

    x0 = x;
    y0 = y;
    h0 = ht;
  }
  return res;
}
