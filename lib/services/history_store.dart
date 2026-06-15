import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/wind_profile.dart';

/// Persists saved [WindProfile]s as a JSON string list, newest first, capped.
class HistoryStore {
  static const _k = 'history';
  static const _cap = 50;

  static Future<List<WindProfile>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_k) ?? const [];
    final list = raw
        .map((s) => WindProfile.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
    return list;
  }

  static Future<void> add(WindProfile profile) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_k) ?? <String>[];
    raw.add(jsonEncode(profile.toJson()));
    if (raw.length > _cap) raw.removeRange(0, raw.length - _cap);
    await p.setStringList(_k, raw);
  }

  static Future<void> delete(int timestampMs) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_k) ?? <String>[];
    raw.removeWhere((s) =>
        (jsonDecode(s) as Map<String, dynamic>)['t'] == timestampMs);
    await p.setStringList(_k, raw);
  }
}
