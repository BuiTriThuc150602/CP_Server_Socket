import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:socket_server/core/logging/logger_service.dart';

enum TcpServerState { stopped, starting, running, stopping, error }

enum TcpClientStatus { connected, disconnected, error }

class TcpClientSession {
  const TcpClientSession({required this.id, required this.remoteAddress, required this.remotePort, required this.connectedAt, required this.status, this.lastMessageAt});

  final String id;
  final String remoteAddress;
  final int remotePort;
  final DateTime connectedAt;
  final DateTime? lastMessageAt;
  final TcpClientStatus status;

  TcpClientSession copyWith({DateTime? lastMessageAt, TcpClientStatus? status}) {
    return TcpClientSession(id: id, remoteAddress: remoteAddress, remotePort: remotePort, connectedAt: connectedAt, lastMessageAt: lastMessageAt ?? this.lastMessageAt, status: status ?? this.status);
  }
}

class TcpSocketMessage {
  const TcpSocketMessage({required this.sessionId, required this.text, required this.timestamp, required this.direction});

  final String sessionId;
  final String text;
  final DateTime timestamp;
  final TcpMessageDirection direction;
}

enum TcpMessageDirection { incoming, outgoing }

class TcpServerEngine {
  TcpServerEngine({LoggerService? logger}) : _logger = logger ?? LoggerService.instance;

  final LoggerService _logger;
  final Map<String, Socket> _clientSockets = {};
  final Map<String, TcpClientSession> _sessions = {};
  final Map<String, StreamSubscription<List<int>>> _clientSubscriptions = {};

  ServerSocket? _serverSocket;
  StreamSubscription<Socket>? _serverSubscription;
  TcpServerState _state = TcpServerState.stopped;

  final _stateController = StreamController<TcpServerState>.broadcast();
  final _clientsController = StreamController<List<TcpClientSession>>.broadcast();
  final _incomingController = StreamController<TcpSocketMessage>.broadcast();
  final _outgoingController = StreamController<TcpSocketMessage>.broadcast();
  final _errorController = StreamController<Object>.broadcast();

  TcpServerState get state => _state;

  List<TcpClientSession> get clients => List.unmodifiable(_sessions.values);

  Stream<TcpServerState> get stateStream => _stateController.stream;

  Stream<List<TcpClientSession>> get clientsStream => _clientsController.stream;

  Stream<TcpSocketMessage> get incomingMessages => _incomingController.stream;

  Stream<TcpSocketMessage> get outgoingMessages => _outgoingController.stream;

  Stream<Object> get errors => _errorController.stream;

  Future<void> start({required String host, required int port}) async {
    if (_state == TcpServerState.running || _state == TcpServerState.starting) {
      return;
    }
    _setState(TcpServerState.starting);
    try {
      _serverSocket = await ServerSocket.bind(host, port, shared: true);
      _serverSubscription = _serverSocket!.listen(_handleClient, onError: _handleServerError, onDone: () => _logger.socket('Server listener closed'));
      _setState(TcpServerState.running);
      await _logger.socket('Server started at $host:$port');
    } catch (error, stackTrace) {
      _setState(TcpServerState.error);
      _errorController.add(error);
      await _logger.error('Server start failed at $host:$port', error, stackTrace);
      rethrow;
    }
  }

  Future<void> restart({required String host, required int port}) async {
    await stop();
    await start(host: host, port: port);
  }

  Future<void> stop() async {
    if (_state == TcpServerState.stopped || _state == TcpServerState.stopping) {
      return;
    }
    _setState(TcpServerState.stopping);

    await _serverSubscription?.cancel();
    _serverSubscription = null;
    await _serverSocket?.close();
    _serverSocket = null;

    for (final subscription in _clientSubscriptions.values) {
      await subscription.cancel();
    }
    _clientSubscriptions.clear();

    for (final socket in _clientSockets.values) {
      socket.destroy();
    }
    _clientSockets.clear();
    _sessions.clear();
    _emitClients();

    _setState(TcpServerState.stopped);
    await _logger.socket('Server stopped');
  }

  Future<void> sendToAll(String text, {bool appendNewline = false}) async {
    await sendToSessions(_clientSockets.keys.toList(), text, appendNewline: appendNewline);
  }

  Future<void> sendToSessions(Iterable<String> sessionIds, String text, {bool appendNewline = false}) async {
    final payload = appendNewline && !text.endsWith('\n') ? '$text\n' : text;
    for (final sessionId in sessionIds) {
      final socket = _clientSockets[sessionId];
      if (socket == null) {
        continue;
      }
      try {
        socket.write(payload);
        await socket.flush().timeout(const Duration(seconds: 2), onTimeout: () {});
        final message = TcpSocketMessage(sessionId: sessionId, text: payload.trimRight(), timestamp: DateTime.now(), direction: TcpMessageDirection.outgoing);
        _outgoingController.add(message);
        await _logger.socket('Outgoing [$sessionId]: ${message.text}');
      } catch (error, stackTrace) {
        _errorController.add(error);
        await _logger.error('Send failed for $sessionId', error, stackTrace);
        await _removeClient(sessionId, TcpClientStatus.error);
      }
    }
  }

  Future<void> dispose() async {
    await stop();
    await _stateController.close();
    await _clientsController.close();
    await _incomingController.close();
    await _outgoingController.close();
    await _errorController.close();
  }

  void _handleClient(Socket socket) {
    final now = DateTime.now();
    final id =
        '${socket.remoteAddress.address}:${socket.remotePort}:'
        '${now.microsecondsSinceEpoch}';
    final session = TcpClientSession(id: id, remoteAddress: socket.remoteAddress.address, remotePort: socket.remotePort, connectedAt: now, status: TcpClientStatus.connected);

    _clientSockets[id] = socket;
    _sessions[id] = session;
    _emitClients();
    unawaited(_logger.socket('Client connected [$id]'));

    _clientSubscriptions[id] = socket.listen(
      (bytes) {
        final text = utf8.decode(bytes, allowMalformed: true);
        _sessions[id] = _sessions[id]!.copyWith(lastMessageAt: DateTime.now());
        _emitClients();
        final message = TcpSocketMessage(sessionId: id, text: text, timestamp: DateTime.now(), direction: TcpMessageDirection.incoming);
        _incomingController.add(message);
        unawaited(_logger.socket('Incoming [$id]: $text'));
      },
      onDone: () => unawaited(_removeClient(id, TcpClientStatus.disconnected)),
      onError: (Object error, StackTrace stackTrace) {
        _errorController.add(error);
        unawaited(_logger.error('Client error [$id]', error, stackTrace));
        unawaited(_removeClient(id, TcpClientStatus.error));
      },
      cancelOnError: true,
    );
  }

  void _handleServerError(Object error, StackTrace stackTrace) {
    _errorController.add(error);
    unawaited(_logger.error('Server listener error', error, stackTrace));
  }

  Future<void> _removeClient(String id, TcpClientStatus status) async {
    await _clientSubscriptions.remove(id)?.cancel();
    _clientSockets.remove(id)?.destroy();
    _sessions.remove(id);
    _emitClients();
    await _logger.socket('Client $status [$id]');
  }

  void _setState(TcpServerState state) {
    _state = state;
    _stateController.add(state);
  }

  void _emitClients() {
    _clientsController.add(clients);
  }
}
