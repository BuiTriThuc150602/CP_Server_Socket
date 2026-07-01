import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum TcpClientConnectionState { disconnected, connecting, connected, error }

class TcpClientEngine {
  Socket? _socket;
  StreamSubscription<List<int>>? _subscription;
  TcpClientConnectionState _state = TcpClientConnectionState.disconnected;

  final _stateController =
      StreamController<TcpClientConnectionState>.broadcast();
  final _incomingController = StreamController<String>.broadcast();
  final _outgoingController = StreamController<String>.broadcast();
  final _errorController = StreamController<Object>.broadcast();

  TcpClientConnectionState get state => _state;
  Stream<TcpClientConnectionState> get states => _stateController.stream;
  Stream<String> get incoming => _incomingController.stream;
  Stream<String> get outgoing => _outgoingController.stream;
  Stream<Object> get errors => _errorController.stream;

  Future<void> connect(String host, int port) async {
    await disconnect();
    _setState(TcpClientConnectionState.connecting);
    try {
      _socket = await Socket.connect(host, port);
      _subscription = _socket!.listen(
        (bytes) =>
            _incomingController.add(utf8.decode(bytes, allowMalformed: true)),
        onDone: () => _setState(TcpClientConnectionState.disconnected),
        onError: (Object error) {
          _errorController.add(error);
          _setState(TcpClientConnectionState.error);
        },
        cancelOnError: true,
      );
      _setState(TcpClientConnectionState.connected);
    } catch (error) {
      _errorController.add(error);
      _setState(TcpClientConnectionState.error);
      rethrow;
    }
  }

  Future<void> send(String text) async {
    final socket = _socket;
    if (socket == null) {
      throw StateError('TCP client is not connected.');
    }
    socket.write(text);
    await socket.flush().timeout(const Duration(seconds: 2), onTimeout: () {});
    _outgoingController.add(text);
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    _socket?.destroy();
    _socket = null;
    _setState(TcpClientConnectionState.disconnected);
  }

  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _incomingController.close();
    await _outgoingController.close();
    await _errorController.close();
  }

  void _setState(TcpClientConnectionState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }
}
