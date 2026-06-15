import 'package:flutter_test/flutter_test.dart';
import 'package:piball/models/reading.dart';
import 'package:piball/services/orientation_service.dart';
import 'package:piball/services/wind_calculator.dart';

void main() {
  group('computeWinds', () {
    test('returns one layer fewer than readings', () {
      // The sample track from the original PiBall source (300 ft/min).
      final raw = const [
        Reading(0, 0, 0),
        Reading(60, 230.3, 9.5),
        Reading(120, 225.4, 10.1),
        Reading(180, 223, 11.6),
        Reading(240, 223.8, 13.2),
        Reading(300, 225.1, 14.6),
      ];
      final res = computeWinds(raw, 300);
      expect(res.length, raw.length - 1);
      // Heights climb monotonically; speeds/headings are finite.
      for (final w in res) {
        expect(w.heightFt.isFinite, isTrue);
        expect(w.speedKts.isFinite, isTrue);
        expect(w.headingDeg, inInclusiveRange(0, 360));
      }
    });

    test('reports wind FROM (meteorological convention)', () {
      // Balloon drifts due north over time -> a south wind (~180° from).
      final raw = [
        const Reading(0, 0, 0),
        // Straight up then increasingly north-displaced as it rises.
        const Reading(60, 0, 80),
        const Reading(120, 0, 70),
      ];
      final res = computeWinds(raw, 300);
      // Moving toward the north => wind from the south.
      expect(res.last.headingDeg, closeTo(180, 1));
    });

    test('ascent rate scales heights linearly', () {
      final raw = const [Reading(0, 0, 0), Reading(60, 90, 45)];
      final a = computeWinds(raw, 300).first.heightFt;
      final b = computeWinds(raw, 600).first.heightFt;
      expect(b, closeTo(a * 2, 1e-6));
    });

    test('fewer than two readings yields nothing', () {
      expect(computeWinds(const [Reading(0, 0, 0)], 300), isEmpty);
    });

    test('flags layers from low-elevation sightings', () {
      final low = computeWinds(
          const [Reading(0, 0, 0), Reading(60, 90, 3)], 300);
      expect(low.single.lowElevation, isTrue);

      final ok = computeWinds(
          const [Reading(0, 0, 0), Reading(60, 90, 45)], 300);
      expect(ok.single.lowElevation, isFalse);
    });

    test('low elevation does not produce infinite speed', () {
      final res = computeWinds(
          const [Reading(0, 0, 0), Reading(60, 90, 0)], 300);
      expect(res.single.speedKts.isFinite, isTrue);
    });
  });

  group('smoothAngleDeg', () {
    // Angular distance to 0°, treating 0 and 360 as equal.
    double distToZero(double a) {
      a %= 360;
      return a > 180 ? 360 - a : a;
    }

    test('wraps correctly across 0/360', () {
      // Midpoint of 359° and 1° is 0°, not the naive 180°.
      expect(distToZero(smoothAngleDeg(359, 1, 0.5)), closeTo(0, 0.5));
    });

    test('blends within range', () {
      expect(smoothAngleDeg(10, 20, 0.5), closeTo(15, 0.5));
    });
  });

  group('isFieldPlausible', () {
    test('accepts Earth-like field, rejects interference', () {
      expect(isFieldPlausible(45), isTrue);
      expect(isFieldPlausible(5), isFalse);
      expect(isFieldPlausible(120), isFalse);
    });
  });

  group('computeAzEl', () {
    test('phone flat, facing north reads ~0° azimuth, ~0° elevation', () {
      // Lying flat: gravity on -Z. Magnetic field pointing north (+Y) with
      // a downward dip component (northern hemisphere) on -Z.
      final azEl = computeAzEl([0, 0, -9.81], [0, 20, -40], 0);
      expect(azEl, isNotNull);
      expect(azEl!.azimuth, closeTo(0, 1));
      expect(azEl.elevation.abs(), lessThan(1));
    });

    test('declination is added to the bearing', () {
      final azEl = computeAzEl([0, 0, -9.81], [0, 20, -40], 10);
      expect(azEl!.azimuth, closeTo(10, 1));
    });

    test('degenerate vectors return null', () {
      expect(computeAzEl([0, 0, 0], [0, 0, 0], 0), isNull);
    });
  });
}
