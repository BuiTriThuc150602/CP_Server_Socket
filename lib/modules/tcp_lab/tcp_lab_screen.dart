import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testdeck/core/models/socket_console_entry.dart';
import 'package:testdeck/core/socket/tcp_client_engine.dart';
import 'package:testdeck/core/socket/tcp_server_engine.dart';
import 'package:testdeck/core/ui/module_workbench.dart';
import 'package:testdeck/core/ui/payload_composer.dart';

class TcpLabScreen extends StatefulWidget {
  const TcpLabScreen({super.key});

  @override
  State<TcpLabScreen> createState() => _TcpLabScreenState();
}

class _TcpLabScreenState extends State<TcpLabScreen> {
  final _server = TcpServerEngine();
  final _client = TcpClientEngine();
  final _serverHost = TextEditingController(text: '127.0.0.1');
  final _serverPort = TextEditingController(text: '9000');
  final _remoteHost = TextEditingController(text: '127.0.0.1');
  final _remotePort = TextEditingController(text: '9000');
  final List<SocketConsoleEntry> _console = [];
  final _consoleDeduper = SocketConsoleDeduper();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  TcpServerState _serverState = TcpServerState.stopped;
  TcpClientConnectionState _clientState = TcpClientConnectionState.disconnected;
  List<TcpClientSession> _clients = const [];
  final Set<String> _selectedClientIds = {};
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _subscriptions.addAll([
      _server.stateStream.listen(
        (state) => setState(() => _serverState = state),
      ),
      _server.clientsStream.listen(
        (clients) => setState(() {
          _clients = clients;
          final liveIds = clients.map((client) => client.id).toSet();
          _selectedClientIds.removeWhere((id) => !liveIds.contains(id));
        }),
      ),
      _server.incomingMessages.listen(
        (message) => _addConsole(
          SocketConsoleEntry(
            timestamp: message.timestamp,
            kind: SocketConsoleKind.incoming,
            text: message.text,
            source: message.sessionId,
          ),
        ),
      ),
      _server.outgoingMessages.listen(
        (message) => _addConsole(
          SocketConsoleEntry(
            timestamp: message.timestamp,
            kind: SocketConsoleKind.outgoing,
            text: message.text,
            source: message.sessionId,
          ),
        ),
      ),
      _server.errors.listen((error) => _addError(error)),
      _client.states.listen((state) => setState(() => _clientState = state)),
      _client.incoming.listen(
        (text) => _addConsole(
          SocketConsoleEntry(
            timestamp: DateTime.now(),
            kind: SocketConsoleKind.incoming,
            text: text,
            source: 'client',
          ),
        ),
      ),
      _client.outgoing.listen(
        (text) => _addConsole(
          SocketConsoleEntry(
            timestamp: DateTime.now(),
            kind: SocketConsoleKind.outgoing,
            text: text,
            source: 'client',
          ),
        ),
      ),
      _client.errors.listen((error) => _addError(error)),
    ]);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_server.dispose());
    unawaited(_client.dispose());
    _serverHost.dispose();
    _serverPort.dispose();
    _remoteHost.dispose();
    _remotePort.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModuleWorkbench(
      header: _header(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 920;
          final main = _tab == 0 ? _serverPanel() : _clientPanel();
          final composer = _composerPanel();
          return narrow
              ? ListView(children: [main, const Divider(height: 1), composer])
              : Row(
                children: [
                  Expanded(child: main),
                  const VerticalDivider(width: 1),
                  Expanded(child: composer),
                ],
              );
        },
      ),
      consoleEntries: _console,
      onClearConsole: () => setState(_console.clear),
      consoleInitiallyExpanded: true,
    );
  }

  Widget _header() {
    final serverRunning = _serverState == TcpServerState.running;
    final clientConnected = _clientState == TcpClientConnectionState.connected;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('Server'),
                icon: Icon(Icons.dns),
              ),
              ButtonSegment(
                value: 1,
                label: Text('Client'),
                icon: Icon(Icons.link),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (value) => setState(() => _tab = value.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 16),
          if (_tab == 0) ...[
            SizedBox(
              width: 180,
              child: TextField(
                controller: _serverHost,
                decoration: const InputDecoration(
                  labelText: 'Bind Host',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: TextField(
                controller: _serverPort,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: serverRunning ? _server.stop : _startServer,
              icon: Icon(
                serverRunning ? Icons.stop : Icons.play_arrow,
                size: 18,
              ),
              label: Text(serverRunning ? 'Stop' : 'Start'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _restartServer,
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('Restart'),
            ),
            const SizedBox(width: 12),
            Chip(
              label: Text('${_clients.length} clients'),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _clients.isEmpty ? null : _copyServerInfo,
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy info'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed:
                  _selectedClientIds.isEmpty ? null : _closeSelectedClients,
              icon: const Icon(Icons.link_off, size: 18),
              label: const Text('Close selected'),
            ),
          ] else ...[
            SizedBox(
              width: 180,
              child: TextField(
                controller: _remoteHost,
                decoration: const InputDecoration(
                  labelText: 'Remote Host',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: TextField(
                controller: _remotePort,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: clientConnected ? _client.disconnect : _connectClient,
              icon: Icon(
                clientConnected ? Icons.link_off : Icons.link,
                size: 18,
              ),
              label: Text(clientConnected ? 'Disconnect' : 'Connect'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _connectClient,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reconnect'),
            ),
          ],
          const SizedBox(width: 12),
          Chip(
            avatar: Icon(
              _tab == 0
                  ? (serverRunning ? Icons.check_circle : Icons.stop_circle)
                  : (clientConnected ? Icons.check_circle : Icons.cancel),
              size: 16,
              color:
                  _tab == 0
                      ? (serverRunning ? Colors.green : Colors.red)
                      : (clientConnected ? Colors.green : Colors.red),
            ),
            label: Text(
              _tab == 0 ? _serverState.name : _clientState.name,
              style: const TextStyle(fontSize: 12),
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _serverPanel() {
    final running = _serverState == TcpServerState.running;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TCP Server',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Chip(
              label: Text(
                running
                    ? 'Listening on ${_serverHost.text}:${_serverPort.text}'
                    : 'Server stopped',
              ),
            ),
            if (_clients.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Connected Clients (${_clients.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ..._clients.map(
                (client) => Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    leading: Checkbox(
                      value: _selectedClientIds.contains(client.id),
                      onChanged:
                          (value) => setState(() {
                            if (value == true) {
                              _selectedClientIds.add(client.id);
                            } else {
                              _selectedClientIds.remove(client.id);
                            }
                          }),
                    ),
                    title: Text(
                      '${client.remoteAddress}:${client.remotePort}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    subtitle: Text(
                      'Connected: ${client.connectedAt.toLocal()}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: IconButton(
                      tooltip: 'Close client',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _server.closeSessions([client.id]),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _clientPanel() {
    final connected = _clientState == TcpClientConnectionState.connected;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TCP Client',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Chip(
              label: Text(
                connected
                    ? 'Connected to ${_remoteHost.text}:${_remotePort.text}'
                    : 'Client disconnected',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composerPanel() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payload Composer',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (_tab == 0) ...[
              const SizedBox(height: 4),
              Text(
                _selectedClientIds.isEmpty
                    ? 'Server send target: all connected clients.'
                    : 'Server send target: ${_selectedClientIds.length} selected client(s).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            PayloadComposer(
              allowFraming: true,
              onSend: (payload) async {
                try {
                  if (_tab == 0) {
                    if (_clients.isEmpty) {
                      _addInfo('No clients connected.');
                      return;
                    }
                    if (_selectedClientIds.isEmpty) {
                      await _server.sendBytesToAll(payload.bytes);
                    } else {
                      await _server.sendBytesToSessions(
                        _selectedClientIds,
                        payload.bytes,
                      );
                    }
                  } else {
                    await _client.sendBytes(payload.bytes);
                  }
                } catch (error) {
                  _addError(error);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startServer() async {
    try {
      await _server.start(
        host: _serverHost.text.trim(),
        port: int.tryParse(_serverPort.text) ?? 9000,
      );
    } catch (error) {
      _addError(error);
    }
  }

  Future<void> _restartServer() async {
    try {
      await _server.restart(
        host: _serverHost.text.trim(),
        port: int.tryParse(_serverPort.text) ?? 9000,
      );
    } catch (error) {
      _addError(error);
    }
  }

  Future<void> _connectClient() async {
    try {
      await _client.connect(
        _remoteHost.text.trim(),
        int.tryParse(_remotePort.text) ?? 9000,
      );
    } catch (error) {
      _addError(error);
    }
  }

  Future<void> _closeSelectedClients() async {
    await _server.closeSessions(_selectedClientIds);
    setState(_selectedClientIds.clear);
  }

  Future<void> _copyServerInfo() async {
    await Clipboard.setData(
      ClipboardData(
        text: '${_serverHost.text.trim()}:${_serverPort.text.trim()}',
      ),
    );
    _addInfo('Connection info copied.');
  }

  void _addInfo(String text) {
    _addConsole(
      SocketConsoleEntry(
        timestamp: DateTime.now(),
        kind: SocketConsoleKind.info,
        text: text,
      ),
    );
  }

  void _addError(Object error) {
    _addConsole(
      SocketConsoleEntry(
        timestamp: DateTime.now(),
        kind: SocketConsoleKind.error,
        text: error.toString(),
      ),
    );
  }

  void _addConsole(SocketConsoleEntry entry) {
    if (_consoleDeduper.shouldSuppress(entry)) {
      return;
    }
    setState(() {
      _console.insert(0, entry);
      if (_console.length > 500) {
        _console.removeRange(500, _console.length);
      }
    });
  }
}
