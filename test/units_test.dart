import 'package:flutter_test/flutter_test.dart';
import 'package:piball/models/app_settings.dart';
import 'package:piball/services/units.dart';

void main() {
  group('Units', () {
    const imperial = Units(UnitSystem.imperial);
    const metric = Units(UnitSystem.metric);

    test('imperial passes values through', () {
      expect(imperial.height(1000), 1000);
      expect(imperial.speed(20), 20);
      expect(imperial.heightUnit, 'ft');
      expect(imperial.speedUnit, 'kt');
    });

    test('metric converts feet->m and knots->m/s', () {
      expect(metric.height(100), closeTo(30.48, 0.01));
      expect(metric.speed(10), closeTo(5.14, 0.01));
    });

    test('ascent rate round-trips through display units', () {
      final display = metric.ascent(300);
      expect(metric.ascentToFtPerMin(display), closeTo(300, 1e-6));
    });
  });
}
