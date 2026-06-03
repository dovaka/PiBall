/// User-tunable parameters. Defaults match the original PiBall hard-coded
/// values so behaviour is unchanged out of the box.
class AppSettings {
  /// Balloon ascent rate in feet per minute. The original hard-coded 300.
  final double ascentRateFtPerMin;

  /// Seconds between sightings.
  final int readIntervalSec;

  /// How long before each sighting the warning cue fires, in milliseconds.
  final int preToneMs;

  /// Exponential-smoothing weight on the previous value (0 = no smoothing,
  /// 0.9 = heavy smoothing). Must stay in [0, 1).
  final double averaging;

  /// Magnetic declination in degrees, East positive. Added to the magnetic
  /// azimuth to produce a true-north bearing.
  final double declinationDeg;

  const AppSettings({
    this.ascentRateFtPerMin = 300,
    this.readIntervalSec = 20,
    this.preToneMs = 1000,
    this.averaging = 0.9,
    this.declinationDeg = 0,
  });

  AppSettings copyWith({
    double? ascentRateFtPerMin,
    int? readIntervalSec,
    int? preToneMs,
    double? averaging,
    double? declinationDeg,
  }) {
    return AppSettings(
      ascentRateFtPerMin: ascentRateFtPerMin ?? this.ascentRateFtPerMin,
      readIntervalSec: readIntervalSec ?? this.readIntervalSec,
      preToneMs: preToneMs ?? this.preToneMs,
      averaging: averaging ?? this.averaging,
      declinationDeg: declinationDeg ?? this.declinationDeg,
    );
  }
}
