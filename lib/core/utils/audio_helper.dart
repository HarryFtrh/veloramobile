import 'package:flutter/services.dart';

class AudioHelper {
  /// Status aktif dari konfigurasi API / preferensi backend
  static bool soundEnabledFromApi = true;

  static void setSoundEnabled(bool enabled) {
    soundEnabledFromApi = enabled;
  }

  static void tapFeedback() {
    HapticFeedback.lightImpact();
  }

  static void actionFeedback() {
    HapticFeedback.mediumImpact();
  }

  static void successFeedback({bool force = false}) {
    HapticFeedback.heavyImpact();
    if (soundEnabledFromApi || force) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  static void orderChime({bool force = false}) {
    HapticFeedback.heavyImpact();
    if (soundEnabledFromApi || force) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  static void errorFeedback({bool force = false}) {
    HapticFeedback.vibrate();
    if (soundEnabledFromApi || force) {
      SystemSound.play(SystemSoundType.alert);
    }
  }
}
