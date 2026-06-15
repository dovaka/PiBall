import 'package:share_plus/share_plus.dart';

import '../models/wind_profile.dart';
import 'units.dart';

/// Renders a [WindProfile] as CSV text (results + raw observations).
String profileToCsv(WindProfile w, Units u) {
  final b = StringBuffer();
  final dt = DateTime.fromMillisecondsSinceEpoch(w.timestampMs);
  b.writeln('PiBall winds-aloft profile');
  b.writeln('Time,${dt.toIso8601String()}');
  b.writeln('Ascent rate (ft/min),${w.ascentRateFtPerMin.toStringAsFixed(0)}');
  if (w.lat != null && w.lon != null) {
    b.writeln('Location,${w.lat!.toStringAsFixed(5)},${w.lon!.toStringAsFixed(5)}');
  }
  b.writeln('');
  b.writeln(
      'Height (${u.heightUnit}),Wind from (deg true),Speed (${u.speedUnit}),Reliable');
  for (final l in w.layers) {
    b.writeln('${u.height(l.heightFt).toStringAsFixed(0)},'
        '${l.headingDeg.toStringAsFixed(0)},'
        '${u.speed(l.speedKts).toStringAsFixed(u.isMetric ? 1 : 0)},'
        '${l.lowElevation ? 'low-el' : 'yes'}');
  }
  b.writeln('');
  b.writeln('Observations');
  b.writeln('#,Time (s),Az (deg true),El (deg)');
  for (var i = 0; i < w.readings.length; i++) {
    final r = w.readings[i];
    b.writeln('${i + 1},${r.time.toStringAsFixed(0)},'
        '${r.az.toStringAsFixed(1)},${r.el.toStringAsFixed(1)}');
  }
  return b.toString();
}

/// Opens the platform share sheet with the profile as CSV text.
Future<void> shareProfile(WindProfile w, Units u) async {
  await SharePlus.instance.share(
    ShareParams(
      text: profileToCsv(w, u),
      subject: 'PiBall winds-aloft profile',
    ),
  );
}
