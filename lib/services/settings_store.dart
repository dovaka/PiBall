import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// Loads and persists [AppSettings] via shared_preferences.
class SettingsStore {
  static const _kAscent = 'ascentRateFtPerMin';
  static const _kInterval = 'readIntervalSec';
  static const _kPreTone = 'preToneMs';
  static const _kAvg = 'averaging';
  static const _kDecl = 'declinationDeg';
  static const _kUnits = 'units';
  static const _kVoice = 'voiceCues';

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    const d = AppSettings();
    final unitsIndex = p.getInt(_kUnits) ?? d.units.index;
    return AppSettings(
      ascentRateFtPerMin: p.getDouble(_kAscent) ?? d.ascentRateFtPerMin,
      readIntervalSec: p.getInt(_kInterval) ?? d.readIntervalSec,
      preToneMs: p.getInt(_kPreTone) ?? d.preToneMs,
      averaging: p.getDouble(_kAvg) ?? d.averaging,
      declinationDeg: p.getDouble(_kDecl) ?? d.declinationDeg,
      units: UnitSystem.values[unitsIndex.clamp(0, UnitSystem.values.length - 1)],
      voiceCues: p.getBool(_kVoice) ?? d.voiceCues,
    );
  }

  static Future<void> save(AppSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kAscent, s.ascentRateFtPerMin);
    await p.setInt(_kInterval, s.readIntervalSec);
    await p.setInt(_kPreTone, s.preToneMs);
    await p.setDouble(_kAvg, s.averaging);
    await p.setDouble(_kDecl, s.declinationDeg);
    await p.setInt(_kUnits, s.units.index);
    await p.setBool(_kVoice, s.voiceCues);
  }
}
