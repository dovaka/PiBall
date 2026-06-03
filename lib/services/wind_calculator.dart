import 'dart:math';

import '../models/reading.dart';
import '../models/wind_layer.dart';

const _degPerRad = 180.0 / pi;
const _secPerHr = 3600.0;
const _ftPerNM = 6076.12;

/// Turns a track of balloon sightings into a per-layer wind profile.
///
/// Each sighting's slant geometry (height from ascent rate, horizontal range
/// from elevation, bearing from azimuth) gives an (x, y) ground position; the
/// displacement between consecutive points gives the layer wind.
///
/// Differences from the original PiBall:
///  * ascent rate is a parameter, not hard-coded to 300 ft/min;
///  * heading uses atan2 (all four quadrants), not atan;
///  * heading is reported as "wind from" (meteorological), via the +180 the
///    original left commented out.
List<WindLayer> computeWinds(List<Reading> raw, double ascentRateFtPerMin) {
  if (raw.length < 2) return const [];

  final res = <WindLayer>[];
  double x0 = 0, y0 = 0, h0 = 0;

  for (var i = 0; i < raw.length - 1; i++) {
    final r = raw[i + 1];

    final ht = r.time / 60.0 * ascentRateFtPerMin; // height, ft
    final hd = ht / tan(r.el / _degPerRad); // horizontal range, ft
    final x = hd * cos(r.az / _degPerRad);
    final y = hd * sin(r.az / _degPerRad);

    final dt = r.time - raw[i].time;
    final dh = ht - h0;
    final dx = x - x0;
    final dy = y - y0;
    final dd = sqrt(dx * dx + dy * dy); // ground track this layer, ft

    final spd = dd / dt * _secPerHr / _ftPerNM; // knots

    var hdg = atan2(dy, dx) * _degPerRad; // direction balloon moved
    hdg += 180; // convert "wind to" -> "wind from"
    hdg %= 360;
    if (hdg < 0) hdg += 360;

    res.add(WindLayer(h0 + dh / 2.0, hdg, spd));

    x0 = x;
    y0 = y;
    h0 = ht;
  }
  return res;
}
