import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// Loads and persists [AppSettings] via shared_preferences.
class SettingsStore {
  static const _kAscent = 'ascentRateFtPerMin';
  static const _kInterval = 'readIntervalSec';
  static const _kPreTone = 'preToneMs';
  static const _kAvg = 'averaging';
  static const _kDecl = 'declinationDeg';

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    const d = AppSettings();
    return AppSettings(
      ascentRateFtPerMin: p.getDouble(_kAscent) ?? d.ascentRateFtPerMin,
      readIntervalSec: p.getInt(_kInterval) ?? d.readIntervalSec,
      preToneMs: p.getInt(_kPreTone) ?? d.preToneMs,
      averaging: p.getDouble(_kAvg) ?? d.averaging,
      declinationDeg: p.getDouble(_kDecl) ?? d.declinationDeg,
    );
  }

  static Future<void> save(AppSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kAscent, s.ascentRateFtPerMin);
    await p.setInt(_kInterval, s.readIntervalSec);
    await p.setInt(_kPreTone, s.preToneMs);
    await p.setDouble(_kAvg, s.averaging);
    await p.setDouble(_kDecl, s.declinationDeg);
  }
}
