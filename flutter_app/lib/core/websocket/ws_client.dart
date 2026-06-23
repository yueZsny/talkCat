import 'dart:convert';
import 'dart:async';
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
  bool _isConnected = false;

  WsClient({String? host}) : _host = host ?? 'ws://10.0.2.2:8000/ws';

  /// 事件流
  Stream<WsEvent> get events => _controller.stream;

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 建立连接
  Future<void> connect({Map<String, dynamic>? auth}) async {
    final uri = Uri.parse(_host);
    _channel = WebSocketChannel.connect(uri);
    _isConnected = true;

    _controller.add(const WsEvent(type: WsEventType.connected, data: {}));

    // 发送认证信息
    if (auth != null) {
      send('auth', auth);
    }

    // 监听消息
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
        _controller.add(WsEvent(
          type: WsEventType.error,
          data: {'error': error.toString()},
        ));
        _isConnected = false;
      },
      onDone: () {
        _isConnected = false;
        _controller.add(const WsEvent(type: WsEventType.disconnected, data: {}));
        _stopHeartbeat();
      },
    );

    _startHeartbeat();
  }

  /// 发送消息
  void send(String type, Map<String, dynamic> data) {
    if (_channel == null || !_isConnected) return;
    _channel!.sink.add(jsonEncode({
      'type': type,
      'data': data,
    }));
  }

  /// 发送聊天消息
  void sendMessage(String content) {
    send('message', {'content': content, 'timestamp': DateTime.now().toIso8601String()});
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      send('ping', {});
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
  }

  /// 断开连接
  void disconnect() {
    _stopHeartbeat();
    _channel?.sink.close();
    _isConnected = false;
    _controller.add(const WsEvent(type: WsEventType.disconnected, data: {}));
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
