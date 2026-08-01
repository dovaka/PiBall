enum UnitSystem { imperial, metric }

class AppSettings {

  final double ascentRateFtPerMin;

  final int readIntervalSec;

  final int preToneMs;

  final double averaging;

  final double declinationDeg;

  final UnitSystem units;

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
