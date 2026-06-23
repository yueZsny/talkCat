import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket 事件类型
enum WsEventType {
  message,
  typing,
  emotion,
  error,
  connected,
  disconnected,
}

/// WebSocket 事件
class WsEvent {
  final WsEventType type;
  final Map<String, dynamic> data;

  const WsEvent({required this.type, required this.data});
}

/// WebSocket 客户端 — 管理与后端的实时连接
class WsClient {
  WebSocketChannel? _channel;
  final StreamController<WsEvent> _controller = StreamController.broadcast();
  final String _host;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;

  /// 连接状态变化回调
  void Function(bool isConnected)? onConnectionChange;

  WsClient({String? host}) : _host = host ?? 'ws://10.0.2.2:8000/ws';

  /// 事件流
  Stream<WsEvent> get events => _controller.stream;

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 建立连接
  Future<void> connect({Map<String, dynamic>? auth}) async {
    await _doConnect(auth);
  }

  Future<void> _doConnect(Map<String, dynamic>? auth) async {
    try {
      final uri = Uri.parse(_host);
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      _reconnectAttempts = 0;
      onConnectionChange?.call(true);

      _controller.add(const WsEvent(type: WsEventType.connected, data: {}));

      if (auth != null) send('auth', auth);

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final type = json['type'] as String? ?? 'message';
            final payload = json['data'] as Map<String, dynamic>? ?? {};
            WsEventType eventType;
            switch (type) {
              case 'message':
                eventType = WsEventType.message;
                break;
              case 'typing':
                eventType = WsEventType.typing;
                break;
              case 'emotion':
                eventType = WsEventType.emotion;
                break;
              default:
                eventType = WsEventType.message;
            }
            _controller.add(WsEvent(type: eventType, data: payload));
          } catch (e) {
            _controller.add(WsEvent(
              type: WsEventType.error,
              data: {'error': e.toString()},
            ));
          }
        },
        onError: (error) {
          _onDisconnect(auth);
        },
        onDone: () {
          _onDisconnect(auth);
        },
      );
      _startHeartbeat();
    } catch (e) {
      _onDisconnect(auth);
    }
  }

  void _onDisconnect(Map<String, dynamic>? auth) {
    _isConnected = false;
    onConnectionChange?.call(false);
    _controller.add(const WsEvent(type: WsEventType.disconnected, data: {}));
    _stopHeartbeat();
    _tryReconnect(auth);
  }

  void _tryReconnect(Map<String, dynamic>? auth) {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    _reconnectTimer = Timer(delay, () {
      print('[WS] 尝试重连 ($_reconnectAttempts/$_maxReconnectAttempts)...');
      _doConnect(auth);
    });
  }

  void send(String type, Map<String, dynamic> data) {
    if (_channel == null || !_isConnected) return;
    _channel!.sink.add(jsonEncode({'type': type, 'data': data}));
  }

  void sendMessage(String content) {
    send('message', {'content': content, 'timestamp': DateTime.now().toIso8601String()});
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) => send('ping', {}));
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _channel?.sink.close();
    _isConnected = false;
    onConnectionChange?.call(false);
    _controller.add(const WsEvent(type: WsEventType.disconnected, data: {}));
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}

/// 后端配置 — 根据平台自动选择地址
class BackendConfig {
  /// Android 模拟器用 10.0.2.2, 其他平台用 localhost
  static String get defaultHost {
    if (kIsWeb) {
      return 'localhost';  // Web 端同源
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';  // Android 模拟器 → 宿主机
    }
    return 'localhost';    // iOS 模拟器 / 真机
  }

  static String apiBaseUrl({String? customHost}) {
    final host = customHost ?? defaultHost;
    return 'http://$host:8000/api/v1';
  }

  static String wsUrl({String? customHost}) {
    final host = customHost ?? defaultHost;
    return 'ws://$host:8000/ws';
  }
}
