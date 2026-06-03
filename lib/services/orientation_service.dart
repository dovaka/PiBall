import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

/// True-north azimuth and elevation angle, in degrees.
class AzEl {
  final double azimuth;
  final double elevation;

  const AzEl(this.azimuth, this.elevation);
}

/// Fuses an accelerometer (gravity) vector and a magnetometer vector into an
/// orientation, mirroring Android's `SensorManager.getRotationMatrix` +
/// `getOrientation`, then converts to a pointing azimuth/elevation.
///
/// [declinationDeg] (East positive) is added to convert the magnetic bearing
/// to true north. Returns null when the vectors are degenerate (e.g. near
/// free-fall or a magnetic anomaly), matching getRotationMatrix returning
/// false.
AzEl? computeAzEl(List<double> accel, List<double> mag, double declinationDeg) {
  final ax = accel[0], ay = accel[1], az = accel[2];
  final ex = mag[0], ey = mag[1], ez = mag[2];

  // H = E x A (East), then normalise.
  var hx = ey * az - ez * ay;
  var hy = ez * ax - ex * az;
  var hz = ex * ay - ey * ax;
  final normH = sqrt(hx * hx + hy * hy + hz * hz);
  if (normH < 0.1) return null; // device is close to free fall or near pole
  final invH = 1.0 / normH;
  hx *= invH;
  hy *= invH;
  hz *= invH;

  final normA = sqrt(ax * ax + ay * ay + az * az);
  if (normA == 0) return null;
  final invA = 1.0 / normA;
  final aax = ax * invA, aay = ay * invA; // gravity, normalised

  // M = A x H (North); getOrientation's azimuth only needs the y-component.
  final my = (az * invA) * hx - aax * hz;

  // Rotation matrix rows: [hx hy hz] [mx my mz] [aax aay aaz].
  // getOrientation: azimuth = atan2(R[1], R[4]); pitch = asin(-R[7]).
  final azimuthRad = atan2(hy, my);
  final pitchRad = asin(-aay.clamp(-1.0, 1.0));

  var azDeg = azimuthRad * 180.0 / pi;
  if (azDeg < 0) azDeg += 360;
  azDeg = (azDeg + declinationDeg) % 360;
  if (azDeg < 0) azDeg += 360;

  // Negate pitch so that pointing up at the balloon reads positive elevation.
  final elDeg = -pitchRad * 180.0 / pi;
  return AzEl(azDeg, elDeg);
}

/// Streams a live [AzEl] by combining the device's accelerometer and
/// magnetometer.
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
