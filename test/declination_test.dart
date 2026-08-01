import 'package:flutter_test/flutter_test.dart';
import 'package:geomag/geomag.dart';

void main() {
  group('GeoMag declination', () {
    test('Seattle reads a sizeable easterly declination', () {
      final r = GeoMag().calculate(47.6, -122.3, 0, DateTime(2026));
      expect(r.dec, greaterThan(10));
      expect(r.dec, lessThan(20));
    });

    test('the bundled model is WMM-2025 era', () {
      final r = GeoMag().calculate(0, 0, 0, DateTime(2026));
      expect(r.dec.isFinite, isTrue);

      expect(r.dec.abs(), lessThan(15));
    });
  });
}
