import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class AzEl {
  final double azimuth;
  final double elevation;
  final double fieldUT;

  const AzEl(this.azimuth, this.elevation, this.fieldUT);
}

bool isFieldPlausible(double ut) => ut >= 20 && ut <= 70;

double smoothAngleDeg(double prevDeg, double curDeg, double weightPrev) {
  final pr = prevDeg * pi / 180.0;
  final cu = curDeg * pi / 180.0;
  final x = weightPrev * cos(pr) + (1 - weightPrev) * cos(cu);
  final y = weightPrev * sin(pr) + (1 - weightPrev) * sin(cu);
  var deg = atan2(y, x) * 180.0 / pi;
  if (deg < 0) deg += 360;
  return deg;
}

AzEl? computeAzEl(List<double> accel, List<double> mag, double declinationDeg) {
  final ax = accel[0], ay = accel[1], az = accel[2];
  final ex = mag[0], ey = mag[1], ez = mag[2];

  var hx = ey * az - ez * ay;
  var hy = ez * ax - ex * az;
  var hz = ex * ay - ey * ax;
  final normH = sqrt(hx * hx + hy * hy + hz * hz);
  if (normH < 0.1) return null;
  final invH = 1.0 / normH;
  hx *= invH;
  hy *= invH;
  hz *= invH;

  final normA = sqrt(ax * ax + ay * ay + az * az);
  if (normA == 0) return null;
  final invA = 1.0 / normA;
  final aax = ax * invA, aay = ay * invA;

  final my = (az * invA) * hx - aax * hz;

  final azimuthRad = atan2(hy, my);
  final pitchRad = asin(-aay.clamp(-1.0, 1.0));

  var azDeg = azimuthRad * 180.0 / pi;
  if (azDeg < 0) azDeg += 360;
  azDeg = (azDeg + declinationDeg) % 360;
  if (azDeg < 0) azDeg += 360;

  final elDeg = -pitchRad * 180.0 / pi;

  final fieldUT = sqrt(ex * ex + ey * ey + ez * ez);
  return AzEl(azDeg, elDeg, fieldUT);
}

class OrientationService {
  double declinationDeg;

  OrientationService({this.declinationDeg = 0});

  List<double>? _accel;
  List<double>? _mag;
  AzEl? _latest;

  final _controller = StreamController<AzEl>.broadcast();
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  AzEl? get latest => _latest;
  Stream<AzEl> get stream => _controller.stream;

  void start() {
    _accSub = accelerometerEventStream().listen((e) {
      _accel = [e.x, e.y, e.z];
      _emit();
    });
    _magSub = magnetometerEventStream().listen((e) {
      _mag = [e.x, e.y, e.z];
      _emit();
    });
  }

  void _emit() {
    final a = _accel, m = _mag;
    if (a == null || m == null) return;
    final r = computeAzEl(a, m, declinationDeg);
    if (r == null) return;
    _latest = r;
    if (!_controller.isClosed) _controller.add(r);
  }

  Future<void> dispose() async {
    await _accSub?.cancel();
    await _magSub?.cancel();
    await _controller.close();
  }
}
