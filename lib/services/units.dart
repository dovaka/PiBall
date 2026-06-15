import '../models/app_settings.dart';

const _ftToM = 0.3048;
const _ktToMps = 0.514444;
const _ftPerMinToMPerMin = 0.3048;

/// Formats canonical (feet / knots) values for display in the chosen unit
/// system.
class Units {
  final UnitSystem system;
  const Units(this.system);

  bool get isMetric => system == UnitSystem.metric;

  String get heightUnit => isMetric ? 'm' : 'ft';
  String get speedUnit => isMetric ? 'm/s' : 'kt';
  String get ascentUnit => isMetric ? 'm/min' : 'ft/min';

  double height(double ft) => isMetric ? ft * _ftToM : ft;
  double speed(double kt) => isMetric ? kt * _ktToMps : kt;
  double ascent(double ftPerMin) =>
      isMetric ? ftPerMin * _ftPerMinToMPerMin : ftPerMin;

  /// Inverse of [ascent]: takes a value the user typed in display units and
  /// returns the canonical ft/min for storage.
  double ascentToFtPerMin(double displayValue) =>
      isMetric ? displayValue / _ftPerMinToMPerMin : displayValue;

  String heightLabel(double ft) =>
      '${height(ft).toStringAsFixed(0)} $heightUnit';
  String speedLabel(double kt) =>
      '${speed(kt).toStringAsFixed(isMetric ? 1 : 0)} $speedUnit';
}
