import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluxlab/core/models/socket_console_entry.dart';
import 'package:fluxlab/core/socket/tcp_server_engine.dart';
import 'package:fluxlab/core/ui/module_workbench.dart';
import 'package:fluxlab/core/utils/payload_codec.dart';
import 'package:fluxlab/modules/websocket_lab/services/websocket_client_engine.dart';

enum BridgeTarget { consoleOnly, websocket }

enum BridgeTransform { none, appendNewline, textToHex, hexToText }

class ProtocolBridgeScreen extends StatefulWidget {
  const ProtocolBridgeScreen({super.key});

  @override
  State<ProtocolBridgeScreen> createState() => _ProtocolBridgeScreenState();
}

class _ProtocolBridgeScreenState extends State<ProtocolBridgeScreen> {
  final _tcpSource = TcpServerEngine();
  final _webSocketTarget = WebSocketClientEngine();
  final _host = TextEditingController(text: '127.0.0.1');
  final _port = TextEditingController(text: '9100');
  final _wsUrl = TextEditingController(text: 'ws://127.0.0.1:8080');
  final List<SocketConsoleEntry> _console = [];
  final _consoleDeduper = SocketConsoleDeduper();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  BridgeTarget _target = BridgeTarget.consoleOnly;
  BridgeTransform _transform = BridgeTransform.none;
  TcpServerState _sourceState = TcpServerState.stopped;
  WebSocketClientState _targetState = WebSocketClientState.disconnected;
  int _inputMessages = 0;
  int _outputMessages = 0;
  int _routeErrors = 0;
  DateTime? _lastMessageAt;

  @override
  void initState() {
    super.initState();
    _subscriptions.addAll([
      _tcpSource.stateStream.listen(
        (state) => setState(() => _sourceState = state),
      ),
      _tcpSource.incomingMessages.listen(_handleSourceMessage),
      _tcpSource.errors.listen((error) => _addError(error)),
      _webSocketTarget.states.listen(
        (state) => setState(() => _targetState = state),
      ),
      _webSocketTarget.incoming.listen(
        (text) => _addConsole(
          SocketConsoleEntry(
            timestamp: DateTime.now(),
            kind: SocketConsoleKind.incoming,
            text: text,
            source: 'ws target',
          ),
        ),
      ),
      _webSocketTarget.errors.listen((error) => _addError(error)),
    ]);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_tcpSource.dispose());
    unawaited(_webSocketTarget.dispose());
    _host.dispose();
    _port.dispose();
    _wsUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = _sourceState == TcpServerState.running;
    return ModuleWorkbench(
      header: _header(running),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source Card
              Expanded(child: _buildSourceCard(running)),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Icon(
                  Icons.arrow_forward,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              // Target Card
              Expanded(child: _buildTargetCard(running)),
            ],
          ),
        ],
      ),
      consoleEntries: _console,
      onClearConsole: () => setState(_console.clear),
    );
  }

  Widget _header(bool running) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Chip(
            label: Text('Source: TCP Server'),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 160,
            child: TextField(
              controller: _host,
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
              controller: _port,
              decoration: const InputDecoration(
                labelText: 'Port',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<BridgeTarget>(
            value: _target,
            underline: const SizedBox.shrink(),
            isDense: true,
            items: const [
              DropdownMenuItem(
                value: BridgeTarget.consoleOnly,
                child: Text('Console'),
              ),
              DropdownMenuItem(
                value: BridgeTarget.websocket,
                child: Text('WebSocket'),
              ),
            ],
            onChanged:
                running
                    ? null
                    : (value) => setState(() => _target = value ?? _target),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<BridgeTransform>(
              initialValue: _transform,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'Transform',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: BridgeTransform.none,
                  child: Text('Raw'),
                ),
                DropdownMenuItem(
                  value: BridgeTransform.appendNewline,
                  child: Text('Append LF'),
                ),
                DropdownMenuItem(
                  value: BridgeTransform.textToHex,
                  child: Text('Text -> HEX'),
                ),
                DropdownMenuItem(
                  value: BridgeTransform.hexToText,
                  child: Text('HEX -> Text'),
                ),
              ],
              onChanged:
                  (value) => setState(() => _transform = value ?? _transform),
            ),
          ),
          if (_target == BridgeTarget.websocket) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 280,
              child: TextField(
                controller: _wsUrl,
                decoration: const InputDecoration(
                  labelText: 'WebSocket URL',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _connectTarget,
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Connect Target'),
            ),
          ],
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: running ? _stop : _start,
            icon: Icon(running ? Icons.stop : Icons.play_arrow, size: 18),
            label: Text(running ? 'Stop Route' : 'Start Route'),
          ),
          const SizedBox(width: 12),
          Chip(
            label: Text('Source ${_sourceState.name}'),
            visualDensity: VisualDensity.compact,
          ),
          if (_target == BridgeTarget.websocket) ...[
            const SizedBox(width: 8),
            Chip(
              label: Text('Target ${_targetState.name}'),
              visualDensity: VisualDensity.compact,
            ),
          ],
          const SizedBox(width: 8),
          Chip(
            label: Text(running ? 'Route active' : 'Route inactive'),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text(
              'In $_inputMessages / Out $_outputMessages / Err $_routeErrors',
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard(bool running) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.input, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Source: TCP Server',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Chip(
                  avatar: Icon(
                    running ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: running ? Colors.green : Colors.red,
                  ),
                  label: Text(
                    _sourceState.name,
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              running
                  ? 'Listening on ${_host.text}:${_port.text}'
                  : 'Route source is stopped.',
            ),
            const SizedBox(height: 8),
            Text(
              'MVP source: TCP Server only. Avoid binding this route back to itself.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetCard(bool running) {
    return Card(
      color:
          _target == BridgeTarget.websocket
              ? null
              : Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.output, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Target',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _target == BridgeTarget.consoleOnly ? 'Console' : 'WebSocket',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Transform: ${_transform.name}'),
            const SizedBox(height: 8),
            Text(
              'Last message: ${_lastMessageAt?.toLocal().toString() ?? '-'}',
            ),
            if (_target == BridgeTarget.websocket) ...[
              const SizedBox(height: 20),
              Text(_wsUrl.text),
              const SizedBox(height: 12),
              Chip(
                avatar: Icon(
                  _targetState == WebSocketClientState.connected
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 16,
                  color:
                      _targetState == WebSocketClientState.connected
                          ? Colors.green
                          : Colors.red,
                ),
                label: Text(
                  _targetState.name,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _start() async {
    try {
      if (_target == BridgeTarget.websocket &&
          _targetState != WebSocketClientState.connected) {
        await _connectTarget();
      }
      await _tcpSource.start(
        host: _host.text.trim(),
        port: int.tryParse(_port.text) ?? 9100,
      );
      _addInfo('Bridge route started.');
    } catch (error) {
      _addError(error);
    }
  }

  Future<void> _stop() async {
    await _tcpSource.stop();
    _addInfo('Bridge route stopped.');
  }

  Future<void> _connectTarget() async {
    try {
      await _webSocketTarget.connect(_wsUrl.text.trim());
    } catch (error) {
      _addError(error);
    }
  }

  void _handleSourceMessage(TcpSocketMessage message) {
    try {
      final transformed = _applyTransform(message.text);
      setState(() {
        _inputMessages++;
        _lastMessageAt = DateTime.now();
      });
      _addConsole(
        SocketConsoleEntry(
          timestamp: DateTime.now(),
          kind: SocketConsoleKind.incoming,
          text: 'Raw incoming\n${message.text}',
          source: 'tcp source',
        ),
      );
      if (_target == BridgeTarget.consoleOnly) {
        _outputMessages++;
        _addConsole(
          SocketConsoleEntry(
            timestamp: DateTime.now(),
            kind: SocketConsoleKind.outgoing,
            text: 'Transformed output\n$transformed',
            source: 'console',
          ),
        );
        return;
      }
      if (_target == BridgeTarget.websocket &&
          _targetState == WebSocketClientState.connected) {
        _webSocketTarget.send(transformed);
        _outputMessages++;
        _addConsole(
          SocketConsoleEntry(
            timestamp: DateTime.now(),
            kind: SocketConsoleKind.outgoing,
            text: transformed,
            source: 'ws target',
          ),
        );
      } else {
        _addInfo(
          'WebSocket target is not connected. Message was not forwarded.',
        );
      }
    } catch (error) {
      _addError(error);
    }
  }

  String _applyTransform(String text) {
    return switch (_transform) {
      BridgeTransform.none => text,
      BridgeTransform.appendNewline => text.endsWith('\n') ? text : '$text\n',
      BridgeTransform.textToHex => PayloadCodec.bytesToHex(utf8.encode(text)),
      BridgeTransform.hexToText => utf8.decode(
        PayloadCodec.hexToBytes(text),
        allowMalformed: true,
      ),
    };
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
    _routeErrors++;
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
