import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

    }
  }
}
