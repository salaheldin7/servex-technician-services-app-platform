import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/app_constants.dart';

final wsClientProvider = Provider<WebSocketClient>((ref) {
  return WebSocketClient();
});

enum WsConnectionState { disconnected, connecting, connected }

class WebSocketClient {
  WebSocketChannel? _channel;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController =
      StreamController<WsConnectionState>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<WsConnectionState> get connectionState => _connectionStateController.stream;

  WsConnectionState _currentState = WsConnectionState.disconnected;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isDisposed = false;

  WsConnectionState get currentState => _currentState;

  Future<void> connect() async {
    if (_currentState == WsConnectionState.connected ||
        _currentState == WsConnectionState.connecting) {
      return;
    }

    _setConnectionState(WsConnectionState.connecting);

    try {
      final token = await _storage.read(key: AppConstants.accessTokenKey);
      if (token == null) {
        _setConnectionState(WsConnectionState.disconnected);
        return;
      }

      final uri = Uri.parse('${ApiConstants.wsUrl}?token=$token');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;

      _setConnectionState(WsConnectionState.connected);
      _reconnectAttempts = 0;

      _startHeartbeat();

      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as Map<String, dynamic>;
            _messageController.add(message);
          } catch (e) {
            print('[WS] Error parsing message: $e');
          }
        },
        onDone: () {
          _setConnectionState(WsConnectionState.disconnected);
          _stopHeartbeat();
          _scheduleReconnect();
        },
        onError: (error) {
          print('[WS] Error: $error');
          _setConnectionState(WsConnectionState.disconnected);
          _stopHeartbeat();
          _scheduleReconnect();
        },
      );
    } catch (e) {
      print('[WS] Connection error: $e');
      _setConnectionState(WsConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void send(String event, Map<String, dynamic> data) {
    if (_currentState != WsConnectionState.connected || _channel == null) {
      print('[WS] Cannot send, not connected');
      return;
    }

    final message = jsonEncode({
      'event': event,
      'data': data,
    });

    _channel!.sink.add(message);
  }

  void sendLocation(double lat, double lng) {
    send('technician_location', {
      'latitude': lat,
      'longitude': lng,
    });
  }

  void sendChatMessage(String bookingId, String message) {
    send('chat_message', {
      'booking_id': bookingId,
      'message': message,
    });
  }

  Stream<Map<String, dynamic>> on(String event) {
    return messages.where((msg) => msg['event'] == event);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_currentState == WsConnectionState.connected) {
        send('ping', {});
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    if (_reconnectAttempts >= AppConstants.maxWsReconnectAttempts) {
      print('[WS] Max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    final delay = Duration(
      seconds: AppConstants.wsReconnectDelay.inSeconds * _reconnectAttempts,
    );

    print('[WS] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed) connect();
    });
  }

  void _setConnectionState(WsConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    await _channel?.sink.close();
    _channel = null;
    _setConnectionState(WsConnectionState.disconnected);
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _messageController.close();
    _connectionStateController.close();
  }
}
