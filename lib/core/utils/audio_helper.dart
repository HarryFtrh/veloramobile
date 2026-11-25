import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../storage/session_storage.dart';

class AudioHelper {
  static const MethodChannel _audioChannel = MethodChannel('com.velora.mobile/audio');
  static FlutterTts? _tts;
  static bool _ttsInitialized = false;

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

  /// Mengatur agar layar tablet/HP tetap menyala (Wakelock) untuk KDS & Kasir (Android + iOS)
  static Future<void> setKeepScreenOn(bool enabled, {bool saveLocal = true}) async {
    if (saveLocal) {
      await SessionStorage.instance.setKeepScreenOnEnabled(enabled);
    }
    try {
      await WakelockPlus.toggle(enable: enabled);
    } catch (_) {
      if (!kIsWeb && Platform.isAndroid) {
        try {
          await _audioChannel.invokeMethod<bool>('setKeepScreenOn', {'enabled': enabled});
        } catch (_) {}
      }
    }
  }

  /// Terapkan status Wakelock sesuai pengaturan yang tersimpan di perangkat
  static Future<void> syncKeepScreenOnFromPrefs() async {
    final enabled = SessionStorage.instance.getKeepScreenOnEnabled();
    await setKeepScreenOn(enabled, saveLocal: false);
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

  /// Panggilan suara Bahasa Indonesia (Text-to-Speech) untuk Antrean Apotek & KDS (Android + iOS)
  static Future<void> speak(String text, {bool force = false}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    if (!isSoundEnabled && !force) return;
    try {
      _tts ??= FlutterTts();
      if (!_ttsInitialized) {
        _ttsInitialized = true;
        await _tts!.setLanguage('id-ID');
        await _tts!.setSpeechRate(0.5);
      }
      await _tts!.speak(clean);
    } catch (_) {
      if (!kIsWeb && Platform.isAndroid) {
        try {
          await _audioChannel.invokeMethod<bool>('speak', {'text': clean});
        } catch (_) {}
      }
    }
  }

  static Future<void> _playNativeChime(String type) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _audioChannel.invokeMethod<bool>('playChime', {'type': type});
    } catch (_) {}
  }
}
