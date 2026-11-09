import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../storage/session_storage.dart';

class AudioHelper {
  static const MethodChannel _audioChannel = MethodChannel('com.velora.mobile/audio');
  static final FlutterTts _tts = FlutterTts();
  static bool _ttsConfigured = false;

  /// Status aktif dari konfigurasi API / preferensi pengaturan perangkat
  static bool soundEnabledFromApi = true;

  static bool get isSoundEnabled =>
      SessionStorage.instance.getSoundNotificationEnabled(fallback: soundEnabledFromApi);

  static void setSoundEnabled(bool enabled, {bool saveLocal = false}) {
    soundEnabledFromApi = enabled;
    if (saveLocal) {
      SessionStorage.instance.setSoundNotificationEnabled(enabled);
    }
  }

  /// Mengatur agar layar tablet/HP tetap menyala (Wakelock) untuk KDS & Kasir
  static Future<void> setKeepScreenOn(bool enabled, {bool saveLocal = true}) async {
    if (saveLocal) {
      await SessionStorage.instance.setKeepScreenOnEnabled(enabled);
    }
    try {
      await WakelockPlus.toggle(enable: enabled);
    } catch (_) {}
    try {
      await _audioChannel.invokeMethod<bool>('setKeepScreenOn', {'enabled': enabled});
    } catch (_) {}
  }

  /// Terapkan status Wakelock sesuai pengaturan yang tersimpan di perangkat
  static Future<void> syncKeepScreenOnFromPrefs() async {
    final enabled = SessionStorage.instance.getKeepScreenOnEnabled();
    try {
      await WakelockPlus.toggle(enable: enabled);
    } catch (_) {}
    try {
      await _audioChannel.invokeMethod<bool>('setKeepScreenOn', {'enabled': enabled});
    } catch (_) {}
  }

  static void tapFeedback() {
    HapticFeedback.lightImpact();
  }

  static void actionFeedback() {
    HapticFeedback.mediumImpact();
  }

  static void successFeedback({bool force = false}) {
    HapticFeedback.heavyImpact();
    if (isSoundEnabled || force) {
      SystemSound.play(SystemSoundType.click);
      _playNativeChime('success');
    }
  }

  static void orderChime({bool force = false}) {
    HapticFeedback.heavyImpact();
    if (isSoundEnabled || force) {
      SystemSound.play(SystemSoundType.alert);
      _playNativeChime('order');
    }
  }

  static void errorFeedback({bool force = false}) {
    HapticFeedback.vibrate();
    if (isSoundEnabled || force) {
      SystemSound.play(SystemSoundType.alert);
      _playNativeChime('error');
    }
  }

  /// Panggilan suara Bahasa Indonesia (Text-to-Speech) untuk Antrean Apotek & KDS
  static Future<void> speak(String text, {bool force = false}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    if (!isSoundEnabled && !force) return;
    try {
      if (!_ttsConfigured) {
        await _tts.setLanguage('id-ID');
        await _tts.setSpeechRate(0.48);
        await _tts.setPitch(1.0);
        _ttsConfigured = true;
      }
      await _tts.speak(clean);
      return;
    } catch (_) {}
    try {
      await _audioChannel.invokeMethod<bool>('speak', {'text': clean});
    } catch (_) {}
  }

  static Future<void> _playNativeChime(String type) async {
    try {
      await _audioChannel.invokeMethod<bool>('playChime', {'type': type});
    } catch (_) {}
  }
}
