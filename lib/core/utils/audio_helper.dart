import 'package:flutter/services.dart';

class AudioHelper {
  static void tapFeedback() {
    HapticFeedback.lightImpact();
  }

  static void actionFeedback() {
    HapticFeedback.mediumImpact();
  }

  static void successFeedback() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void errorFeedback() {
    HapticFeedback.vibrate();
    SystemSound.play(SystemSoundType.alert);
  }
}
