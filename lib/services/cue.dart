import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Operator cues so the observer can keep eyes on the balloon. Haptics + the
/// system click always fire; an optional spoken "3-2-1-mark" countdown is
/// enabled via [voice] (Settings).
class Cue {
  static final FlutterTts _tts = FlutterTts();
  static bool voice = false;

  static void warn() {
    HapticFeedback.selectionClick();
  }

  static void count(int n) {
    HapticFeedback.selectionClick();
    if (voice) _say('$n');
  }

  static void read() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
    if (voice) _say('mark');
  }

  static Future<void> _say(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // TTS unavailable on this platform/device — haptics still cover it.
    }
  }
}
