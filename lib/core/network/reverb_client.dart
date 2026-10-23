import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import '../storage/session_storage.dart';

/// Callback listener untuk event realtime Pusher/Reverb
typedef ReverbEventListener = void Function(Map<String, dynamic> data);

class ReverbClient {
  static final ReverbClient instance = ReverbClient._internal();
  ReverbClient._internal();

  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _isDisposed = false;

  final Map<String, List<ReverbEventListener>> _eventListeners = {};
  final Set<String> _subscribedChannels = {};

  bool get isConnected => _isConnected;

  /// Inisialisasi koneksi websocket ke Laravel Reverb
  Future<void> connect() async {
    final appKey = AppConfig.instance.reverbAppKey;
    final host = AppConfig.instance.reverbHost;
    final port = AppConfig.instance.reverbPort;

    // Jika Reverb app key kosong (misal mode standalone atau offline), jangan buang error/spam
    if (appKey.isEmpty) {
      debugPrint('[ReverbClient] REVERB_APP_KEY belum disetel. Melewati koneksi realtime.');
      return;
    }

    if (_isConnected || _isDisposed) return;

    try {
      final scheme = port == 443 ? 'wss' : 'ws';
      final uri = Uri.parse('$scheme://$host:$port/app/$appKey?protocol=7&client=js&version=8.4.0-reverb&flash=false');

      _channel = WebSocketChannel.connect(uri);
      await _channel?.ready;

      _isConnected = true;
      _startPing();

      _channel?.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      debugPrint('[ReverbClient] Terhubung ke Reverb ($scheme://$host:$port)');

      // Resubscribe channel jika sebelumnya terputus
      for (final chan in _subscribedChannels) {
        _sendSubscribe(chan);
      }
    } catch (e) {
      debugPrint('[ReverbClient] Gagal terhubung ke Reverb: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is! Map<String, dynamic>) return;

      final event = decoded['event']?.toString() ?? '';
      final dataStr = decoded['data'];

      Map<String, dynamic> data = {};
      if (dataStr is Map<String, dynamic>) {
        data = dataStr;
      } else if (dataStr is String && dataStr.isNotEmpty) {
        try {
          final parsed = jsonDecode(dataStr);
          if (parsed is Map<String, dynamic>) data = parsed;
        } catch (_) {}
      }

      if (event == 'pusher:ping') {
        _send({'event': 'pusher:pong', 'data': {}});
        return;
      }

      // Distribusikan ke listener yang terdaftar
      final listeners = _eventListeners[event];
      if (listeners != null && listeners.isNotEmpty) {
        for (final listener in List.of(listeners)) {
          try {
            listener(data);
          } catch (e) {
            debugPrint('[ReverbClient] Error saat mengeksekusi listener untuk $event: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[ReverbClient] Gagal mem-parse pesan websocket: $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('[ReverbClient] Koneksi Reverb error: $error');
    _cleanup();
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[ReverbClient] Koneksi Reverb terputus (onDone)');
    _cleanup();
    _scheduleReconnect();
  }

  void _cleanup() {
    _isConnected = false;
    _pingTimer?.cancel();
    _pingTimer = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        _send({'event': 'pusher:ping', 'data': {}});
      }
    });
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        connect();
      }
    });
  }

  void _send(Map<String, dynamic> payload) {
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (e) {
      debugPrint('[ReverbClient] Gagal mengirim payload: $e');
    }
  }

  /// Berlangganan public channel (misal: cafe-orders, table-updates)
  void subscribe(String channelName) {
    _subscribedChannels.add(channelName);
    if (_isConnected) {
      _sendSubscribe(channelName);
    }
  }

  void _sendSubscribe(String channelName) {
    _send({
      'event': 'pusher:subscribe',
      'data': {
        'channel': channelName,
      },
    });
  }

  /// Berhenti berlangganan channel
  void unsubscribe(String channelName) {
    _subscribedChannels.remove(channelName);
    if (_isConnected) {
      _send({
        'event': 'pusher:unsubscribe',
        'data': {
          'channel': channelName,
        },
      });
    }
  }

  /// Daftarkan callback listener untuk nama event tertentu
  void on(String eventName, ReverbEventListener listener) {
    _eventListeners.putIfAbsent(eventName, () => []).add(listener);
  }

  /// Hapus listener
  void off(String eventName, [ReverbEventListener? listener]) {
    if (listener == null) {
      _eventListeners.remove(eventName);
    } else {
      _eventListeners[eventName]?.remove(listener);
    }
  }

  /// Helper untuk subscribe channel pesanan cabang aktif
  void subscribeBranchOrders({required void Function(Map<String, dynamic>) onNewOrder}) {
    final locationId = SessionStorage.instance.getLocationId();
    if (locationId == null || locationId.isEmpty) return;

    final channelName = 'cafe-orders.$locationId';
    subscribe(channelName);
    on('OrderCreated', onNewOrder);
    on('OrderUpdated', onNewOrder);
  }

  void disconnect() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _cleanup();
  }
}
