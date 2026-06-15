import 'reading.dart';
import 'wind_layer.dart';

/// A saved winds-aloft run: its sightings, the computed layers, and metadata.
class WindProfile {
  final int timestampMs;
  final double ascentRateFtPerMin;
  final double? lat;
  final double? lon;
  final List<Reading> readings;
  final List<WindLayer> layers;

  const WindProfile({
    required this.timestampMs,
    required this.ascentRateFtPerMin,
    required this.readings,
    required this.layers,
    this.lat,
    this.lon,
  });

  Map<String, dynamic> toJson() => {
        't': timestampMs,
        'ar': ascentRateFtPerMin,
        'lat': lat,
        'lon': lon,
        'r': readings.map((e) => [e.time, e.az, e.el]).toList(),
        'w': layers
            .map((e) =>
                [e.heightFt, e.headingDeg, e.speedKts, e.lowElevation ? 1 : 0])
            .toList(),
      };

  factory WindProfile.fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => (v as num).toDouble();
    return WindProfile(
      timestampMs: j['t'] as int,
      ascentRateFtPerMin: d(j['ar']),
      lat: j['lat'] == null ? null : d(j['lat']),
      lon: j['lon'] == null ? null : d(j['lon']),
      readings: (j['r'] as List)
          .map((e) => Reading(d(e[0]), d(e[1]), d(e[2])))
          .toList(),
      layers: (j['w'] as List)
          .map((e) =>
              WindLayer(d(e[0]), d(e[1]), d(e[2]), lowElevation: e[3] == 1))
          .toList(),
    );
  }
}
