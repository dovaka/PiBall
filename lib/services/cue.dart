import 'package:flutter/services.dart';

/// Operator cues so the observer can keep eyes on the balloon. A light cue
/// warns that a sighting is coming; a strong cue marks the moment to read.
/// Uses haptics + the system click — no bundled audio, works on iOS/Android.
class Cue {
  static void warn() {
    HapticFeedback.selectionClick();
  }

  static void read() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }
}
