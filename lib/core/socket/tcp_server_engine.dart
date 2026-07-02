import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fluxlab/core/logging/logger_service.dart';
import 'package:fluxlab/core/utils/payload_codec.dart';

enum TcpServerState { stopped, starting, running, stopping, error }

enum TcpClientStatus { connected, disconnected, error }

class TcpClientSession {
  const TcpClientSession({
    required this.id,
    required this.remoteAddress,
    required this.remotePort,
    required this.connectedAt,
    required this.status,
    this.lastMessageAt,
  });

  final String id;
  final String remoteAddress;
  final int remotePort;
  final DateTime connectedAt;
  final DateTime? lastMessageAt;
  final TcpClientStatus status;

  TcpClientSession copyWith({
    DateTime? lastMessageAt,
    TcpClientStatus? status,
  }) {
    return TcpClientSession(
      id: id,
      remoteAddress: remoteAddress,
      remotePort: remotePort,
      connectedAt: connectedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      status: status ?? this.status,
    );
  }
}

class TcpSocketMessage {
  const TcpSocketMessage({
    required this.sessionId,
    required this.text,
    required this.timestamp,
    required this.direction,
    this.bytes,
  });

  final String sessionId;
  final String text;
  final DateTime timestamp;
  final TcpMessageDirection direction;
  final List<int>? bytes;
}

enum TcpMessageDirection { incoming, outgoing }

class TcpServerEngine {
  TcpServerEngine({LoggerService? logger})
    : _logger = logger ?? LoggerService.instance;

  final LoggerService _logger;
  final Map<String, Socket> _clientSockets = {};
  final Map<String, TcpClientSession> _sessions = {};
  final Map<String, StreamSubscription<List<int>>> _clientSubscriptions = {};

  ServerSocket? _serverSocket;
  StreamSubscription<Socket>? _serverSubscription;
  TcpServerState _state = TcpServerState.stopped;

  final _stateController = StreamController<TcpServerState>.broadcast();
  final _clientsController =
      StreamController<List<TcpClientSession>>.broadcast();
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

  Future<void> start({
    required String host,
    required int port,
    bool shared = false,
  }) async {
    if (_state == TcpServerState.running || _state == TcpServerState.starting) {
      return;
    }
    _validateEndpoint(host, port);
    _setState(TcpServerState.starting);
    try {
      _serverSocket = await ServerSocket.bind(host, port, shared: shared);
      _serverSubscription = _serverSocket!.listen(
        _handleClient,
        onError: _handleServerError,
        onDone: () => _logger.socket('Server listener closed'),
      );
      _setState(TcpServerState.running);
      await _logger.socket('Server started at $host:$port');
    } catch (error, stackTrace) {
      _setState(TcpServerState.error);
      final friendlyError = _friendlyBindError(host, port, error);
      final stateError = StateError(friendlyError);
      _errorController.add(stateError);
      await _logger.error(
        'Server start failed at $host:$port',
        error,
        stackTrace,
      );
      throw stateError;
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
    await sendToSessions(
      _clientSockets.keys.toList(),
      text,
      appendNewline: appendNewline,
    );
  }

  Future<void> sendBytesToAll(List<int> bytes) async {
    await sendBytesToSessions(_clientSockets.keys.toList(), bytes);
  }

  Future<void> sendToSessions(
    Iterable<String> sessionIds,
    String text, {
    bool appendNewline = false,
  }) async {
    final payload = appendNewline && !text.endsWith('\n') ? '$text\n' : text;
    await sendBytesToSessions(sessionIds, utf8.encode(payload));
  }

  Future<void> sendBytesToSessions(
    Iterable<String> sessionIds,
    List<int> bytes,
  ) async {
    for (final sessionId in sessionIds) {
      final socket = _clientSockets[sessionId];
      if (socket == null) {
        continue;
      }
      try {
        socket.add(bytes);
        await socket.flush().timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
        final preview = PayloadCodec.previewBytes(bytes);
        final message = TcpSocketMessage(
          sessionId: sessionId,
          text: preview,
          timestamp: DateTime.now(),
          direction: TcpMessageDirection.outgoing,
          bytes: List<int>.unmodifiable(bytes),
        );
        _outgoingController.add(message);
        await _logger.socket('Outgoing [$sessionId]: ${message.text}');
      } catch (error, stackTrace) {
        _errorController.add(error);
        await _logger.error('Send failed for $sessionId', error, stackTrace);
        await _removeClient(sessionId, TcpClientStatus.error);
      }
    }
  }

  Future<void> closeSessions(Iterable<String> sessionIds) async {
    for (final sessionId in sessionIds.toList()) {
      await _removeClient(sessionId, TcpClientStatus.disconnected);
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
    final session = TcpClientSession(
      id: id,
      remoteAddress: socket.remoteAddress.address,
      remotePort: socket.remotePort,
      connectedAt: now,
      status: TcpClientStatus.connected,
    );

    _clientSockets[id] = socket;
    _sessions[id] = session;
    _emitClients();
    unawaited(_logger.socket('Client connected [$id]'));

    _clientSubscriptions[id] = socket.listen(
      (bytes) {
        final text = utf8.decode(bytes, allowMalformed: true);
        _sessions[id] = _sessions[id]!.copyWith(lastMessageAt: DateTime.now());
        _emitClients();
        final message = TcpSocketMessage(
          sessionId: id,
          text: text,
          timestamp: DateTime.now(),
          direction: TcpMessageDirection.incoming,
          bytes: List<int>.unmodifiable(bytes),
        );
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

  void _validateEndpoint(String host, int port) {
    if (host.trim().isEmpty) {
      throw ArgumentError('Invalid host: bind host cannot be empty.');
    }
    if (port < 1 || port > 65535) {
      throw ArgumentError('Invalid port: $port. Use a value from 1 to 65535.');
    }
  }

  String _friendlyBindError(String host, int port, Object error) {
    if (error is SocketException) {
      final message = error.message.toLowerCase();
      if (message.contains('address already in use') ||
          message.contains('only one usage') ||
          error.osError?.errorCode == 10048 ||
          error.osError?.errorCode == 98) {
        return 'Address already in use: $host:$port. Stop the other server or choose another port.';
      }
      if (message.contains('permission') ||
          message.contains('access is denied') ||
          error.osError?.errorCode == 10013 ||
          error.osError?.errorCode == 13) {
        return 'Permission denied while binding $host:$port. Try another port or run with suitable permissions.';
      }
      if (message.contains('failed host lookup') ||
          message.contains('address not available') ||
          error.osError?.errorCode == 10049 ||
          error.osError?.errorCode == 99) {
        return 'Invalid or unavailable bind host: $host.';
      }
    }
    return 'Could not bind TCP server at $host:$port: $error';
  }
}
