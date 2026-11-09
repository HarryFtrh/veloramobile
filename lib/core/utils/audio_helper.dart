import 'package:flutter/services.dart';

class AudioHelper {
  static const MethodChannel _audioChannel = MethodChannel('com.velora.mobile/audio');

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
      _playNativeChime('success');
    }
  }

  static void orderChime({bool force = false}) {
    HapticFeedback.heavyImpact();
    if (soundEnabledFromApi || force) {
      SystemSound.play(SystemSoundType.alert);
      _playNativeChime('order');
    }
  }

  static void errorFeedback({bool force = false}) {
    HapticFeedback.vibrate();
    if (soundEnabledFromApi || force) {
      SystemSound.play(SystemSoundType.alert);
      _playNativeChime('error');
    }
  }

  /// Panggilan suara Bahasa Indonesia (Text-to-Speech) untuk Antrean Apotek & KDS
  static Future<void> speak(String text, {bool force = false}) async {
    if (text.trim().isEmpty) return;
    if (!soundEnabledFromApi && !force) return;
    try {
      await _audioChannel.invokeMethod<bool>('speak', {'text': text.trim()});
    } catch (_) {}
  }

  static Future<void> _playNativeChime(String type) async {
    try {
      await _audioChannel.invokeMethod<bool>('playChime', {'type': type});
    } catch (_) {}
  }
}
