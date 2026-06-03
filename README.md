# PiBall

A **pilot-balloon ("pibal") theodolite** for your phone. Track a rising balloon
of known ascent rate by eye, record its bearing and elevation at fixed
intervals, and PiBall computes the **winds aloft** — speed and direction at each
altitude layer.

Originally a 2014 Android/Java app by Thomee Wright (Edge Of Creation). This is a
ground-up rewrite in **Flutter** that runs on **iOS, Android, and the web** from
a single codebase, with a modern Material 3 UI.

## How it works

1. Release a balloon inflated to a known free-lift (ascent rate).
2. Tap **Start**. PiBall gives you a lead-in, then cues each sighting with a
   haptic + click — a light warning cue, then a strong "read now" cue.
3. Keep the phone pointed at the balloon at each cue. PiBall samples the fused
   magnetometer + accelerometer orientation (true-north azimuth + elevation).
4. Tap **Stop**, then **Calculate**. You get a per-layer wind table:
   height, direction the wind is *from*, and speed in knots.

## What changed from the original

The orientation math mirrors Android's `getRotationMatrix` / `getOrientation`,
reimplemented in Dart so it behaves the same on iOS. The wind calculation is a
faithful port **plus** the fixes the original needed:

| Issue in original | Fix |
| --- | --- |
| Ascent rate hard-coded to 300 ft/min | Configurable in **Settings** |
| Heading used `atan` (two quadrants only) | Uses `atan2` (all four) |
| Reported "wind to", not "wind from" | Re-enabled the `+180°` convention |
| No true-north correction | **Magnetic declination** setting (East +), or **auto from GPS** via the platform geomagnetic model |
| Dead "Settings" menu item | Real settings screen (rate, interval, cue lead, smoothing, declination), persisted |
| Screen could sleep mid-run | Screen is kept awake while recording (wakelock) |

## Run it

```sh
flutter pub get
flutter run            # pick a device: iOS, Android, or chrome
flutter test           # wind + orientation math unit tests
```

> Sensors don't exist in a desktop browser, so the live readout is inert on web;
> use a physical phone for real observations.

## Layout

```
lib/
  models/      reading, wind_layer, app_settings
  services/    orientation_service (sensor fusion), wind_calculator,
               settings_store, cue
  screens/     home_screen, settings_screen
  theme.dart   Material 3, dark by default (dawn launches)
test/          wind + orientation math
legacy-android/  the original 2014 Java/Gradle app, preserved
```

## Caveats

- Phone magnetometers are far less precise than an optical theodolite — this is a
  rough field tool. Heavy smoothing (Settings) helps.
- Azimuth smoothing is naive across the 0/360° wrap (as in the original).
- Declination can be set by tapping **Use my location** in Settings (needs a GPS
  fix + location permission), or entered manually. The model (WMM-2025) is pure
  Dart, so auto-lookup works on every platform.
