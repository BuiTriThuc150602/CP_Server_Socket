import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fluxlab/core/utils/payload_codec.dart';

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

  Future<void> connect(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await disconnect();
    _setState(TcpClientConnectionState.connecting);
    try {
      _validateEndpoint(host, port);
      _socket = await Socket.connect(host, port).timeout(
        timeout,
        onTimeout:
            () =>
                throw TimeoutException(
                  'TCP connect timeout after ${timeout.inSeconds}s: $host:$port',
                ),
      );
      _subscription = _socket!.listen(
        (bytes) =>
            _incomingController.add(utf8.decode(bytes, allowMalformed: true)),
        onDone: () {
          _socket = null;
          _setState(TcpClientConnectionState.disconnected);
        },
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
    await sendBytes(utf8.encode(text));
  }

  Future<void> sendBytes(List<int> bytes) async {
    final socket = _socket;
    if (socket == null) {
      throw StateError('TCP client is not connected.');
    }
    socket.add(bytes);
    await socket.flush().timeout(const Duration(seconds: 2), onTimeout: () {});
    _outgoingController.add(PayloadCodec.previewBytes(bytes));
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      try {
        await socket.close().timeout(const Duration(seconds: 1));
      } catch (_) {
        socket.destroy();
      }
    }
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

  void _validateEndpoint(String host, int port) {
    if (host.trim().isEmpty) {
      throw ArgumentError('Invalid host: remote host cannot be empty.');
    }
    if (port < 1 || port > 65535) {
      throw ArgumentError('Invalid port: $port. Use a value from 1 to 65535.');
    }
  }
}
