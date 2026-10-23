import 'dart:io';
import 'package:flutter/foundation.dart';

/// Layanan keamanan runtime tingkat lanjut untuk melindungi aplikasi dari:
/// 1. Reverse Engineering & Dynamic Instrumentation (Frida, Xposed, Cydia Substrate)
/// 2. Rooting & Privilege Escalation (Magisk, SuperSU, su binaries)
/// 3. Debugger Tampering pada kompilasi Release
class AntiTamperService {
  AntiTamperService._();
  static final AntiTamperService instance = AntiTamperService._();

  /// Jalur biner root & su yang umum ditemukan pada perangkat yang dimodifikasi
  static const List<String> _knownRootPaths = [
    '/system/app/Superuser.apk',
    '/sbin/su',
    '/system/bin/su',
    '/system/xbin/su',
    '/data/local/xbin/su',
    '/data/local/bin/su',
    '/system/sd/xbin/su',
    '/system/bin/failsafe/su',
    '/data/local/su',
    '/su/bin/su',
    '/magisk/.core/bin/su',
  ];

  /// Kata kunci injeksi memori Frida dan hooking framework pada /proc/self/maps
  static const List<String> _hookKeywords = [
    'frida',
    'frida-agent',
    'frida-gadget',
    'xposed',
    'substrate',
  ];

  /// Memeriksa apakah perangkat terindikasi root (Android)
  bool isDeviceRooted() {
    if (kIsWeb || !Platform.isAndroid) return false;

    try {
      // 1. Cek keberadaan file su / superuser
      for (final path in _knownRootPaths) {
        if (File(path).existsSync()) {
          return true;
        }
      }

      // 2. Cek build tags test-keys (ROM kustom tidak resmi)
      final buildTags = Platform.environment['BUILD_TAGS'] ?? '';
      if (buildTags.contains('test-keys')) {
        return true;
      }
    } catch (_) {
      // Terisolasi oleh sandbox OS normal
    }

    return false;
  }

  /// Memeriksa apakah ada Frida server aktif atau pustaka hook yang disuntikkan ke memori
  Future<bool> isFridaDetected() async {
    if (kIsWeb || !Platform.isAndroid) return false;

    // 1. Cek port default Frida server (27042) di localhost
    try {
      final socket = await Socket.connect(
        '127.0.0.1',
        27042,
        timeout: const Duration(milliseconds: 250),
      );
      await socket.close();
      return true; // Berhasil terhubung ke Frida server
    } catch (_) {
      // Port tertutup (aman)
    }

    // 2. Cek memori proses melalui /proc/self/maps untuk mendeteksi injeksi frida-gadget
    try {
      final mapsFile = File('/proc/self/maps');
      if (mapsFile.existsSync()) {
        final content = mapsFile.readAsStringSync().toLowerCase();
        for (final kw in _hookKeywords) {
          if (content.contains(kw)) {
            return true;
          }
        }
      }
    } catch (_) {
      // Sandbox access restriction
    }

    return false;
  }

  /// Memeriksa apakah aplikasi berjalan di lingkungan debugger aktif pada mode release
  bool isDebugTampering() {
    var isAssertEnabled = false;
    assert(() {
      isAssertEnabled = true;
      return true;
    }());

    // Jika mode rilis tetapi assertions dipaksa aktif oleh attacker/tamper
    if (kReleaseMode && isAssertEnabled) {
      return true;
    }

    return false;
  }

  /// Memverifikasi integritas lingkungan runtime secara menyeluruh
  Future<SecurityCheckResult> verifyRuntimeIntegrity() async {
    final rooted = isDeviceRooted();
    final fridaDetected = await isFridaDetected();
    final debugTampered = isDebugTampering();

    final isSecure = !rooted && !fridaDetected && !debugTampered;

    return SecurityCheckResult(
      isSecure: isSecure,
      isRooted: rooted,
      isFridaDetected: fridaDetected,
      isDebugTampered: debugTampered,
    );
  }
}

class SecurityCheckResult {
  final bool isSecure;
  final bool isRooted;
  final bool isFridaDetected;
  final bool isDebugTampered;

  const SecurityCheckResult({
    required this.isSecure,
    required this.isRooted,
    required this.isFridaDetected,
    required this.isDebugTampered,
  });

  @override
  String toString() {
    return 'SecurityCheckResult(isSecure: $isSecure, isRooted: $isRooted, isFridaDetected: $isFridaDetected, isDebugTampered: $isDebugTampered)';
  }
}
