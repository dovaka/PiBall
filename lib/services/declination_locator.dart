import 'package:geolocator/geolocator.dart';
import 'package:geomag/geomag.dart';

class DeclinationResult {
  final double declinationDeg;
  final double latitude;
  final double longitude;

  const DeclinationResult(this.declinationDeg, this.latitude, this.longitude);
}

const _metersToFeet = 3.28084;

/// Gets a GPS fix and computes the magnetic declination there from the bundled
/// World Magnetic Model (WMM-2025, pure Dart — works on iOS/Android/web).
/// Throws a [String] message on failure for the UI to surface.
Future<DeclinationResult> fetchDeclinationFromLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw 'Location services are turned off.';
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw 'Location permission denied.';
  }

  final pos = await Geolocator.getCurrentPosition();
  final result = GeoMag().calculate(
    pos.latitude,
    pos.longitude,
    pos.altitude * _metersToFeet,
    DateTime.now(),
  );
  return DeclinationResult(result.dec, pos.latitude, pos.longitude);
}
