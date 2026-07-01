import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:socket_server/core/models/socket_console_entry.dart';
import 'package:socket_server/core/ui/module_workbench.dart';
import 'package:socket_server/core/utils/payload_codec.dart';
import 'package:socket_server/modules/serial_lab/services/serial_port_engine.dart';

class SerialLabScreen extends StatefulWidget {
  const SerialLabScreen({super.key});

  @override
  State<SerialLabScreen> createState() => _SerialLabScreenState();
}

class _SerialLabScreenState extends State<SerialLabScreen> {
  final _engine = SerialPortEngine();
  final _payload = TextEditingController();
  final List<SocketConsoleEntry> _console = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  List<String> _ports = const [];
  String? _selectedPort;
  int _baudRate = 9600;
  int _dataBits = 8;
  int _stopBits = 1;
  int _parity = SerialPortParity.none;
  PayloadMode _payloadMode = PayloadMode.text;
  PayloadFraming _framing = PayloadFraming.raw;
  SerialEngineState _state = SerialEngineState.closed;
  int _rxBytes = 0;
  int _txBytes = 0;

  @override
  void initState() {
    super.initState();
    _subscriptions.addAll([
      _engine.states.listen((state) => setState(() => _state = state)),
      _engine.incoming.listen((bytes) {
        _rxBytes += bytes.length;
        _addConsole(SocketConsoleEntry(timestamp: DateTime.now(), kind: SocketConsoleKind.incoming, text: PayloadCodec.previewBytes(bytes), bytes: bytes));
      }),
      _engine.outgoing.listen((bytes) {
        _txBytes += bytes.length;
        _addConsole(SocketConsoleEntry(timestamp: DateTime.now(), kind: SocketConsoleKind.outgoing, text: 'Sent ${bytes.length} bytes\n${PayloadCodec.previewBytes(bytes)}', bytes: bytes));
      }),
      _engine.errors.listen((error) => _addError(error)),
    ]);
    _refreshPorts();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_engine.dispose());
    _payload.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final open = _state == SerialEngineState.open;
    return ModuleWorkbench(
      header: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Port Selection
              SizedBox(
                width: constraints.maxWidth < 720 ? 220 : 180,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_selectedPort),
                  initialValue: _ports.contains(_selectedPort) ? _selectedPort : null,
                  hint: const Text('Select Port'),
                  isDense: true,
                  isExpanded: true,
                  items: [for (final port in _ports) DropdownMenuItem(value: port, child: Text(port, overflow: TextOverflow.ellipsis))],
                  onChanged: open ? null : (value) => setState(() => _selectedPort = value),
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(tooltip: 'Refresh ports', onPressed: _refreshPorts, icon: const Icon(Icons.refresh, size: 20)),
              PopupMenuButton<int>(
                tooltip: 'Serial presets',
                onSelected: open ? null : _applyPreset,
                itemBuilder: (context) => const [PopupMenuItem(value: 9600, child: Text('9600 8N1')), PopupMenuItem(value: 19200, child: Text('19200 8N1')), PopupMenuItem(value: 38400, child: Text('38400 8N1')), PopupMenuItem(value: 115200, child: Text('115200 8N1'))],
                child: const Chip(label: Text('Presets'), avatar: Icon(Icons.tune, size: 16), visualDensity: VisualDensity.compact),
              ),
              // Settings
              SizedBox(width: 128, child: _numberDropdown('Baud', _baudRate, [9600, 19200, 38400, 57600, 115200], open, (v) => setState(() => _baudRate = v))),
              SizedBox(width: 96, child: _numberDropdown('Bits', _dataBits, [7, 8], open, (v) => setState(() => _dataBits = v))),
              SizedBox(width: 96, child: _numberDropdown('Stop', _stopBits, [1, 2], open, (v) => setState(() => _stopBits = v))),
              SizedBox(
                width: 118,
                child: DropdownButtonFormField<int>(
                  initialValue: _parity,
                  isDense: true,
                  isExpanded: true,
                  items: const [DropdownMenuItem(value: SerialPortParity.none, child: Text('None')), DropdownMenuItem(value: SerialPortParity.odd, child: Text('Odd')), DropdownMenuItem(value: SerialPortParity.even, child: Text('Even'))],
                  onChanged: open ? null : (value) => setState(() => _parity = value ?? _parity),
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                ),
              ),
              // Connect
              FilledButton.icon(onPressed: open ? _engine.close : _open, icon: Icon(open ? Icons.close : Icons.usb, size: 18), label: Text(open ? 'Close' : 'Open')),
              SizedBox(width: 112, child: _payloadModeDropdown()),
              SizedBox(width: 112, child: _framingDropdown()),
              FilledButton.icon(onPressed: open ? _send : null, icon: const Icon(Icons.send, size: 18), label: const Text('Send')),
              OutlinedButton.icon(onPressed: _clearCounters, icon: const Icon(Icons.refresh, size: 18), label: Text('RX $_rxBytes / TX $_txBytes')),
              Chip(avatar: Icon(open ? Icons.check_circle : Icons.cancel, size: 16, color: open ? Colors.green : Colors.red), label: Text(_state.name, style: const TextStyle(fontSize: 12)), visualDensity: VisualDensity.compact),
            ],
          );
        },
      ),
      // Payload Composer
      body: Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payload Composer', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _payload,
                  minLines: 10,
                  maxLines: 20,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: InputDecoration(hintText: _payloadMode == PayloadMode.hex ? '48 65 6C 6C 6F' : 'ASCII/Text payload', filled: true, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.all(12)),
                ),
              ),
            ],
          ),
        ),
      ),
      consoleEntries: _console,
      onClearConsole: () => setState(_console.clear),
    );
  }

  Widget _numberDropdown(String label, int value, List<int> values, bool disabled, ValueChanged<int> onChanged) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isDense: true,
      isExpanded: true,
      items: [for (final item in values) DropdownMenuItem(value: item, child: Text('$label $item', overflow: TextOverflow.ellipsis))],
      onChanged: disabled ? null : (v) => onChanged(v ?? values.first),
      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
    );
  }

  Widget _payloadModeDropdown() {
    return DropdownButtonFormField<PayloadMode>(
      initialValue: _payloadMode,
      isDense: true,
      isExpanded: true,
      items: const [DropdownMenuItem(value: PayloadMode.text, child: Text('Text')), DropdownMenuItem(value: PayloadMode.hex, child: Text('HEX'))],
      onChanged: (value) => setState(() => _payloadMode = value ?? _payloadMode),
      decoration: const InputDecoration(labelText: 'Mode', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
    );
  }

  Widget _framingDropdown() {
    return DropdownButtonFormField<PayloadFraming>(
      initialValue: _framing,
      isDense: true,
      isExpanded: true,
      items: const [DropdownMenuItem(value: PayloadFraming.raw, child: Text('None')), DropdownMenuItem(value: PayloadFraming.newline, child: Text('LF')), DropdownMenuItem(value: PayloadFraming.crlf, child: Text('CRLF'))],
      onChanged: (value) => setState(() => _framing = value ?? _framing),
      decoration: const InputDecoration(labelText: 'Append', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
    );
  }

  void _refreshPorts() {
    final ports = _engine.availablePorts();
    setState(() {
      _ports = ports;
      _selectedPort ??= ports.isEmpty ? null : ports.first;
    });
  }

  Future<void> _open() async {
    final port = _selectedPort;
    if (port == null) {
      _addError('No serial port selected.');
      return;
    }
    try {
      await _engine.open(name: port, baudRate: _baudRate, dataBits: _dataBits, stopBits: _stopBits, parity: _parity);
    } catch (error) {
      _addError(error);
    }
  }

  void _send() {
    try {
      final payload = PayloadCodec.encode(_payload.text, _payloadMode, _framing);
      _engine.sendBytes(payload.bytes);
    } catch (error) {
      _addError(error);
    }
  }

  void _applyPreset(int baudRate) {
    setState(() {
      _baudRate = baudRate;
      _dataBits = 8;
      _stopBits = 1;
      _parity = SerialPortParity.none;
    });
  }

  void _clearCounters() {
    setState(() {
      _rxBytes = 0;
      _txBytes = 0;
    });
  }

  void _addError(Object error) {
    _addConsole(SocketConsoleEntry(timestamp: DateTime.now(), kind: SocketConsoleKind.error, text: error.toString()));
  }

  void _addConsole(SocketConsoleEntry entry) {
    setState(() {
      _console.insert(0, entry);
      if (_console.length > 500) {
        _console.removeRange(500, _console.length);
      }
    });
  }
}
