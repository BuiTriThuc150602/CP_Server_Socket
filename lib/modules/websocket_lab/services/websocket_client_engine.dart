import 'dart:async';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

enum WebSocketClientState { disconnected, connecting, connected, error }

class WebSocketClientEngine {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  WebSocketClientState _state = WebSocketClientState.disconnected;

  final _stateController = StreamController<WebSocketClientState>.broadcast();
  final _incomingController = StreamController<String>.broadcast();
  final _outgoingController = StreamController<String>.broadcast();
  final _errorController = StreamController<Object>.broadcast();

  WebSocketClientState get state => _state;
  Stream<WebSocketClientState> get states => _stateController.stream;
  Stream<String> get incoming => _incomingController.stream;
  Stream<String> get outgoing => _outgoingController.stream;
  Stream<Object> get errors => _errorController.stream;

  Future<void> connect(String url) async {
    await disconnect();
    _setState(WebSocketClientState.connecting);
    try {
      final channel = IOWebSocketChannel.connect(Uri.parse(url));
      _channel = channel;
      _subscription = channel.stream.listen(
        (message) => _incomingController.add(message.toString()),
        onDone: () => _setState(WebSocketClientState.disconnected),
        onError: (Object error) {
          _errorController.add(error);
          _setState(WebSocketClientState.error);
        },
        cancelOnError: true,
      );
      await channel.ready.timeout(const Duration(seconds: 5));
      _setState(WebSocketClientState.connected);
    } catch (error) {
      _errorController.add(error);
      _setState(WebSocketClientState.error);
      rethrow;
    }
  }

  void send(String text) {
    final channel = _channel;
    if (channel == null) {
      throw StateError('WebSocket is not connected.');
    }
    channel.sink.add(text);
    _outgoingController.add(text);
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close(status.normalClosure);
    _channel = null;
    _setState(WebSocketClientState.disconnected);
  }

  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _incomingController.close();
    await _outgoingController.close();
    await _errorController.close();
  }

  void _setState(WebSocketClientState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }
}
