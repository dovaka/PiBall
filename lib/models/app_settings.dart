enum UnitSystem { imperial, metric }

/// User-tunable parameters. Defaults match the original PiBall hard-coded
/// values so behaviour is unchanged out of the box.
class AppSettings {
  /// Balloon ascent rate in feet per minute. The original hard-coded 300.
  /// Stored canonically in ft/min regardless of the display [units].
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

  /// Display units for height/speed.
  final UnitSystem units;

  /// Speak a "3-2-1-mark" countdown in addition to the haptic cues.
  final bool voiceCues;

  const AppSettings({
    this.ascentRateFtPerMin = 300,
    this.readIntervalSec = 20,
    this.preToneMs = 1000,
    this.averaging = 0.9,
    this.declinationDeg = 0,
    this.units = UnitSystem.imperial,
    this.voiceCues = false,
  });

  AppSettings copyWith({
    double? ascentRateFtPerMin,
    int? readIntervalSec,
    int? preToneMs,
    double? averaging,
    double? declinationDeg,
    UnitSystem? units,
    bool? voiceCues,
  }) {
    return AppSettings(
      ascentRateFtPerMin: ascentRateFtPerMin ?? this.ascentRateFtPerMin,
      readIntervalSec: readIntervalSec ?? this.readIntervalSec,
      preToneMs: preToneMs ?? this.preToneMs,
      averaging: averaging ?? this.averaging,
      declinationDeg: declinationDeg ?? this.declinationDeg,
      units: units ?? this.units,
      voiceCues: voiceCues ?? this.voiceCues,
    );
  }
}
