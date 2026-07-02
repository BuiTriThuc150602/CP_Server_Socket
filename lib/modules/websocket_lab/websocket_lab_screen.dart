import 'dart:async';

import 'package:flutter/material.dart';
import 'package:socket_server/core/models/socket_console_entry.dart';
import 'package:socket_server/core/ui/module_workbench.dart';
import 'package:socket_server/core/ui/payload_composer.dart';
import 'package:socket_server/modules/websocket_lab/services/websocket_client_engine.dart';

class WebSocketLabScreen extends StatefulWidget {
  const WebSocketLabScreen({super.key});

  @override
  State<WebSocketLabScreen> createState() => _WebSocketLabScreenState();
}

class _WebSocketLabScreenState extends State<WebSocketLabScreen> {
  final _engine = WebSocketClientEngine();
  final _url = TextEditingController(text: 'ws://127.0.0.1:8080');
  final List<SocketConsoleEntry> _console = [];
  final _consoleDeduper = SocketConsoleDeduper();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  WebSocketClientState _state = WebSocketClientState.disconnected;

  @override
  void initState() {
    super.initState();
    _subscriptions.addAll([
      _engine.states.listen((state) => setState(() => _state = state)),
      _engine.incoming.listen(
        (text) => _addConsole(
          SocketConsoleEntry(
            timestamp: DateTime.now(),
            kind: SocketConsoleKind.incoming,
            text: text,
          ),
        ),
      ),
      _engine.outgoing.listen(
        (text) => _addConsole(
          SocketConsoleEntry(
            timestamp: DateTime.now(),
            kind: SocketConsoleKind.outgoing,
            text: text,
          ),
        ),
      ),
      _engine.errors.listen((error) => _addError(error)),
    ]);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_engine.dispose());
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = _state == WebSocketClientState.connected;
    return ModuleWorkbench(
      header: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                controller: _url,
                decoration: const InputDecoration(
                  labelText: 'WebSocket URL',
                  isDense: true,
                  prefixIcon: Icon(Icons.link, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: connected ? _engine.disconnect : _connect,
              icon: Icon(connected ? Icons.link_off : Icons.link, size: 18),
              label: Text(connected ? 'Disconnect' : 'Connect'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _connect,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reconnect'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: connected ? () => _engine.send('ping') : null,
              icon: const Icon(Icons.network_ping, size: 18),
              label: const Text('Ping'),
            ),
            const SizedBox(width: 12),
            Chip(
              avatar: Icon(
                connected ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: connected ? Colors.green : Colors.red,
              ),
              label: Text(_state.name, style: const TextStyle(fontSize: 12)),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final composer = Card(
            margin: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payload Composer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PayloadComposer(
                    allowFraming: false,
                    onSend: (payload) {
                      try {
                        _engine.send(payload.text);
                      } catch (error) {
                        _addError(error);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
          if (constraints.maxWidth < 840) {
            return ListView(children: [composer]);
          }
          return Row(
            children: [
              Expanded(child: composer),
              const VerticalDivider(width: 1),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(12),
                  child: const SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: _WebSocketHelp(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      consoleEntries: _console,
      onClearConsole: () => setState(_console.clear),
    );
  }

  Future<void> _connect() async {
    try {
      await _engine.connect(_url.text.trim());
    } catch (error) {
      _addError(error);
    }
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

class _WebSocketHelp extends StatelessWidget {
  const _WebSocketHelp();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WebSocket Lab',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        const Text(
          'Connect to ws:// or wss:// endpoints, send text/JSON payloads, and inspect realtime messages.',
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.link, size: 20),
          title: const Text('Connect', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            'Establish WebSocket connection',
            style: TextStyle(fontSize: 12),
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          leading: const Icon(Icons.network_ping, size: 20),
          title: const Text('Ping', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            'Send ping to keep connection alive',
            style: TextStyle(fontSize: 12),
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          leading: const Icon(Icons.send, size: 20),
          title: const Text('Send Payload', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            'Send custom text or JSON',
            style: TextStyle(fontSize: 12),
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
