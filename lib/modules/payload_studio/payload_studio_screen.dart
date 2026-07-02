import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testdeck/core/ui/module_workbench.dart';
import 'package:testdeck/core/utils/payload_codec.dart';

class PayloadStudioScreen extends StatefulWidget {
  const PayloadStudioScreen({super.key});

  @override
  State<PayloadStudioScreen> createState() => _PayloadStudioScreenState();
}

class _PayloadStudioScreenState extends State<PayloadStudioScreen> {
  final _input = TextEditingController();
  final _output = TextEditingController();
  Timer? _autoRunDebounce;
  _PayloadOperation? _activeOperation;
  bool _autoRun = true;
  String? _status;

  @override
  void initState() {
    super.initState();
    _input.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    _autoRunDebounce?.cancel();
    _input.removeListener(_handleInputChanged);
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter, control: true):
            _RunPayloadOperationIntent(),
      },
      child: Actions(
        actions: {
          _RunPayloadOperationIntent:
              CallbackAction<_RunPayloadOperationIntent>(
                onInvoke: (_) {
                  _runActiveOperation();
                  return null;
                },
              ),
        },
        child: ModuleWorkbench(
          header: _buildTopBar(),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final editors =
                  constraints.maxWidth < 900
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _editor('Input', _input),
                          const SizedBox(height: 16),
                          _editor('Output', _output, readOnly: true),
                        ],
                      )
                      : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _editor('Input', _input)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _editor('Output', _output, readOnly: true),
                          ),
                        ],
                      );
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (_status != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _status ?? 'Unknown',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  editors,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Snippets
            ActionChip(
              avatar: const Icon(Icons.snippet_folder, size: 18),
              label: const Text('Insert Snippet'),
              onPressed: _showSnippetMenu,
            ),
            const SizedBox(width: 8),

            // JSON Tools
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'pretty') {
                  _selectOperation(_PayloadOperation.jsonPretty);
                }
                if (value == 'minify') {
                  _selectOperation(_PayloadOperation.jsonMinify);
                }
              },
              child: Chip(
                avatar: const Icon(Icons.code, size: 18),
                label: const Text('JSON Tools'),
              ),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'pretty',
                      child: Text('Pretty Print'),
                    ),
                    const PopupMenuItem(value: 'minify', child: Text('Minify')),
                  ],
            ),

            // Encoding Tools
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'text_hex') {
                  _selectOperation(_PayloadOperation.textToHex);
                }
                if (value == 'hex_text') {
                  _selectOperation(_PayloadOperation.hexToText);
                }
                if (value == 'text_b64') {
                  _selectOperation(_PayloadOperation.textToBase64);
                }
                if (value == 'b64_text') {
                  _selectOperation(_PayloadOperation.base64ToText);
                }
              },
              child: Chip(
                avatar: const Icon(Icons.transform, size: 18),
                label: const Text('Encoding'),
              ),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'text_hex',
                      child: Text('Text → HEX'),
                    ),
                    const PopupMenuItem(
                      value: 'hex_text',
                      child: Text('HEX → Text'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'text_b64',
                      child: Text('Text → Base64'),
                    ),
                    const PopupMenuItem(
                      value: 'b64_text',
                      child: Text('Base64 → Text'),
                    ),
                  ],
            ),

            // Number Converter
            PopupMenuButton<String>(
              onSelected: _handleNumberConversion,
              child: Chip(
                avatar: const Icon(Icons.calculate, size: 18),
                label: const Text('Numbers'),
              ),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'hex_dec',
                      child: Text('HEX → DEC'),
                    ),
                    const PopupMenuItem(
                      value: 'dec_hex',
                      child: Text('DEC → HEX'),
                    ),
                    const PopupMenuItem(
                      value: 'bin_dec',
                      child: Text('BIN → DEC'),
                    ),
                    const PopupMenuItem(
                      value: 'dec_bin',
                      child: Text('DEC → BIN'),
                    ),
                    const PopupMenuItem(
                      value: 'hex_bin',
                      child: Text('HEX → BIN'),
                    ),
                    const PopupMenuItem(
                      value: 'bin_hex',
                      child: Text('BIN → HEX'),
                    ),
                  ],
            ),

            PopupMenuButton<String>(
              onSelected: _handleUtility,
              child: Chip(
                avatar: const Icon(Icons.functions, size: 18),
                label: const Text('Utilities'),
              ),
              itemBuilder:
                  (context) => const [
                    PopupMenuItem(
                      value: 'xor',
                      child: Text('XOR checksum from HEX'),
                    ),
                    PopupMenuItem(
                      value: 'lrc',
                      child: Text('LRC checksum from HEX'),
                    ),
                    PopupMenuItem(
                      value: 'byte_length',
                      child: Text('HEX byte length'),
                    ),
                    PopupMenuItem(
                      value: 'utf8_length',
                      child: Text('UTF-8 byte length'),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'unix_seconds',
                      child: Text('Unix seconds'),
                    ),
                    PopupMenuItem(
                      value: 'unix_millis',
                      child: Text('Unix milliseconds'),
                    ),
                    PopupMenuItem(
                      value: 'iso_local',
                      child: Text('ISO local time'),
                    ),
                    PopupMenuItem(
                      value: 'formatted_local',
                      child: Text('Formatted local time'),
                    ),
                  ],
            ),

            const SizedBox(width: 8),
            Chip(
              avatar: const Icon(Icons.bolt, size: 16),
              label: Text(
                _activeOperation?.label ?? 'Choose an operation first',
              ),
              visualDensity: VisualDensity.compact,
            ),
            Tooltip(
              message: 'Run selected operation (Ctrl+Enter)',
              child: FilledButton.icon(
                onPressed:
                    _activeOperation == null ? null : _runActiveOperation,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Run'),
              ),
            ),
            FilterChip(
              label: const Text('Auto-run'),
              selected: _autoRun,
              onSelected: (value) {
                setState(() => _autoRun = value);
                if (value) {
                  _scheduleAutoRun();
                }
              },
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Copy input',
              onPressed:
                  () => Clipboard.setData(ClipboardData(text: _input.text)),
              icon: const Icon(Icons.input),
            ),
            IconButton.outlined(
              tooltip: 'Copy output',
              onPressed:
                  () => Clipboard.setData(ClipboardData(text: _output.text)),
              icon: const Icon(Icons.copy),
            ),
            IconButton.outlined(
              tooltip: 'Swap input/output',
              onPressed: _swapInputOutput,
              icon: const Icon(Icons.swap_horiz),
            ),
            IconButton.outlined(
              tooltip: 'Use output as input',
              onPressed: () {
                setState(() {
                  _input.text = _output.text;
                  _output.text = '';
                  _status = 'Moved output to input.';
                });
              },
              icon: const Icon(Icons.arrow_back),
            ),
            IconButton.outlined(
              tooltip: 'Clear input/output',
              onPressed: _clearEditors,
              icon: const Icon(Icons.clear_all),
            ),
          ],
        );
      },
    );
  }

  Widget _editor(
    String title,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 32,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  if (readOnly)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.content_copy, size: 16),
                      onPressed:
                          () => Clipboard.setData(
                            ClipboardData(text: controller.text),
                          ),
                      tooltip: 'Copy',
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 420,
              child: TextField(
                controller: controller,
                readOnly: readOnly,
                expands: true,
                minLines: null,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor:
                      readOnly ? Theme.of(context).colorScheme.surface : null,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnippetMenu() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Insert Snippet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.wifi),
                  title: const Text('Connect Status'),
                  onTap: () {
                    _input.text = _connectStatusSnippet();
                    _selectOperation(_PayloadOperation.jsonPretty);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.credit_card),
                  title: const Text('Card Log'),
                  onTap: () {
                    _input.text = _cardLogSnippet();
                    _selectOperation(_PayloadOperation.jsonPretty);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.input),
                  title: const Text('IO Status'),
                  onTap: () {
                    _input.text = _ioStatusSnippet();
                    _selectOperation(_PayloadOperation.jsonPretty);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.data_object),
                  title: const Text('Generic JSON'),
                  onTap: () {
                    _input.text = '{"key": "value"}';
                    _selectOperation(_PayloadOperation.jsonPretty);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dns),
                  title: const Text('TCP JSON line'),
                  onTap: () {
                    _input.text =
                        '{"event":"ping","timestamp":${DateTime.now().millisecondsSinceEpoch}}\n';
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('WebSocket JSON message'),
                  onTap: () {
                    _input.text = '{"type":"ping","payload":"hello"}';
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.usb),
                  title: const Text('Serial HEX example'),
                  onTap: () {
                    _input.text = '02 30 31 03';
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _handleNumberConversion(String value) {
    final map = {
      'hex_dec': _PayloadOperation.hexToDecimal,
      'dec_hex': _PayloadOperation.decimalToHex,
      'bin_dec': _PayloadOperation.binaryToDecimal,
      'dec_bin': _PayloadOperation.decimalToBinary,
      'hex_bin': _PayloadOperation.hexToBinary,
      'bin_hex': _PayloadOperation.binaryToHex,
    };
    final operation = map[value];
    if (operation != null) {
      _selectOperation(operation);
    }
  }

  void _handleUtility(String value) {
    final now = DateTime.now();
    switch (value) {
      case 'xor':
        _selectOperation(_PayloadOperation.xorChecksum);
      case 'lrc':
        _selectOperation(_PayloadOperation.lrcChecksum);
      case 'byte_length':
        _selectOperation(_PayloadOperation.hexByteLength);
      case 'utf8_length':
        _selectOperation(_PayloadOperation.utf8ByteLength);
      case 'unix_seconds':
        _output.text = (now.millisecondsSinceEpoch ~/ 1000).toString();
        setState(() => _status = 'Timestamp generated.');
      case 'unix_millis':
        _output.text = now.millisecondsSinceEpoch.toString();
        setState(() => _status = 'Timestamp generated.');
      case 'iso_local':
        _output.text = now.toIso8601String();
        setState(() => _status = 'Timestamp generated.');
      case 'formatted_local':
        _output.text =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        setState(() => _status = 'Timestamp generated.');
    }
  }

  void _handleInputChanged() {
    if (_autoRun) {
      _scheduleAutoRun();
    }
  }

  void _scheduleAutoRun() {
    _autoRunDebounce?.cancel();
    if (_activeOperation == null) {
      return;
    }
    _autoRunDebounce = Timer(
      const Duration(milliseconds: 400),
      _runActiveOperation,
    );
  }

  void _selectOperation(_PayloadOperation operation) {
    setState(() => _activeOperation = operation);
    _runActiveOperation();
  }

  void _runActiveOperation() {
    final operation = _activeOperation;
    if (operation == null) {
      setState(() => _status = 'Choose an operation first.');
      return;
    }
    _guard(() => _output.text = _runOperation(operation));
  }

  String _runOperation(_PayloadOperation operation) {
    return switch (operation) {
      _PayloadOperation.jsonPretty => PayloadCodec.prettyJson(_input.text),
      _PayloadOperation.jsonMinify => PayloadCodec.minifyJson(_input.text),
      _PayloadOperation.textToHex => PayloadCodec.bytesToHex(
        utf8.encode(_input.text),
      ),
      _PayloadOperation.hexToText => utf8.decode(
        PayloadCodec.hexToBytes(_input.text),
        allowMalformed: true,
      ),
      _PayloadOperation.textToBase64 => base64Encode(utf8.encode(_input.text)),
      _PayloadOperation.base64ToText => utf8.decode(
        base64Decode(_input.text),
        allowMalformed: true,
      ),
      _PayloadOperation.hexToDecimal => _convertNumbers(
        _NumericBase.hex,
        _NumericBase.decimal,
      ),
      _PayloadOperation.decimalToHex => _convertNumbers(
        _NumericBase.decimal,
        _NumericBase.hex,
      ),
      _PayloadOperation.binaryToDecimal => _convertNumbers(
        _NumericBase.binary,
        _NumericBase.decimal,
      ),
      _PayloadOperation.decimalToBinary => _convertNumbers(
        _NumericBase.decimal,
        _NumericBase.binary,
      ),
      _PayloadOperation.hexToBinary => _convertNumbers(
        _NumericBase.hex,
        _NumericBase.binary,
      ),
      _PayloadOperation.binaryToHex => _convertNumbers(
        _NumericBase.binary,
        _NumericBase.hex,
      ),
      _PayloadOperation.xorChecksum =>
        PayloadCodec.xorChecksum(
          PayloadCodec.hexToBytes(_input.text),
        ).toRadixString(16).padLeft(2, '0').toUpperCase(),
      _PayloadOperation.lrcChecksum =>
        PayloadCodec.lrcChecksum(
          PayloadCodec.hexToBytes(_input.text),
        ).toRadixString(16).padLeft(2, '0').toUpperCase(),
      _PayloadOperation.hexByteLength =>
        PayloadCodec.hexToBytes(_input.text).length.toString(),
      _PayloadOperation.utf8ByteLength =>
        utf8.encode(_input.text).length.toString(),
    };
  }

  String _convertNumbers(_NumericBase source, _NumericBase target) {
    try {
      final normalized = _normalizeNumericInput(_input.text, source);
      final values = _parseNumericValues(normalized, source);
      setState(() => _status = 'Converted ${values.length} values.');
      return values.map((value) => _formatNumber(value, target)).join(' ');
    } catch (error) {
      throw FormatException(error.toString());
    }
  }

  void _guard(VoidCallback action) {
    try {
      action();
      setState(() => _status = 'Action completed successfully');
    } catch (error) {
      setState(() => _status = error.toString());
    }
  }

  void _swapInputOutput() {
    setState(() {
      final input = _input.text;
      _input.text = _output.text;
      _output.text = input;
      _status = 'Input/output swapped.';
    });
  }

  void _clearEditors() {
    setState(() {
      _input.clear();
      _output.clear();
      _status = 'Cleared.';
    });
  }

  // ... (Keep existing helper methods: _normalizeNumericInput, _connectStatusSnippet, etc.)
  String _normalizeNumericInput(String input, _NumericBase source) {
    final chunks =
        input
            .trim()
            .replaceAll('_', '')
            .replaceAll(RegExp(r'[\r\n\t,;|]+'), ' ')
            .split(RegExp(r'\s+'))
            .where((chunk) => chunk.trim().isNotEmpty)
            .map((chunk) => _normalizeNumericToken(chunk, source))
            .toList();
    if (chunks.isEmpty) {
      throw const FormatException('Input is empty.');
    }
    return chunks.join(' ');
  }

  String _normalizeNumericToken(String token, _NumericBase source) {
    var value = token.trim();
    switch (source) {
      case _NumericBase.hex:
        value =
            value
                .replaceFirst(RegExp(r'^(0x|#)', caseSensitive: false), '')
                .replaceFirst(RegExp(r'h$', caseSensitive: false), '')
                .toUpperCase();
        if (!RegExp(r'^[0-9A-F]+$').hasMatch(value)) {
          throw FormatException('Invalid HEX token: $token');
        }
      case _NumericBase.decimal:
        value = value.replaceFirst(RegExp(r'd$', caseSensitive: false), '');
        if (!RegExp(r'^\d+$').hasMatch(value)) {
          throw FormatException('Invalid decimal token: $token');
        }
      case _NumericBase.binary:
        value = value
            .replaceFirst(RegExp(r'^0b', caseSensitive: false), '')
            .replaceFirst(RegExp(r'b$', caseSensitive: false), '');
        if (!RegExp(r'^[01]+$').hasMatch(value)) {
          throw FormatException('Invalid binary token: $token');
        }
    }
    return value;
  }

  List<BigInt> _parseNumericValues(String normalized, _NumericBase source) {
    return normalized
        .split(' ')
        .map((token) => BigInt.parse(token, radix: source.radix))
        .toList();
  }

  String _formatNumber(BigInt value, _NumericBase target) {
    final converted = value.toRadixString(target.radix);
    return switch (target) {
      _NumericBase.hex =>
        converted.length.isOdd
            ? '0${converted.toUpperCase()}'
            : converted.toUpperCase(),
      _NumericBase.decimal => converted,
      _NumericBase.binary => converted,
    };
  }

  String _connectStatusSnippet() {
    return jsonEncode({
      'eventType': 'connectStatus',
      'data': {
        'connectStatus': 'connected',
        'deviceInfo': {'deviceId': 'DEVICE_001', 'protocolType': 'TCP'},
        'id': 'DEVICE_001',
      },
    });
  }

  String _cardLogSnippet() {
    final now = DateTime.now();
    return jsonEncode({
      'data': {
        'cardInfo': {
          'cardId': 'CARD001',
          'readerIndex': 1,
          'readerName': 'Reader 1',
          'time': now.toString(),
        },
        'deviceInfo': {'deviceId': 'DEVICE_001', 'protocolType': 'TCP'},
        'id': 'DEVICE_001',
      },
      'eventType': 'cardLog',
      'index': 6,
      'timestamp': now.millisecondsSinceEpoch ~/ 1000,
    });
  }

  String _ioStatusSnippet() {
    final now = DateTime.now();
    return jsonEncode({
      'data': {
        'deviceInfo': {'deviceId': 'DEVICE_001', 'protocolType': 'TCP'},
        'inputStatus': List.generate(
          8,
          (i) => {
            'inputIndex': i + 1,
            'inputName': 'Input ${i + 1}',
            'value': i == 0 ? 1 : 0,
          },
        ),
        'relayStatus': List.generate(
          8,
          (i) => {
            'relayIndex': i + 1,
            'relayName': 'Relay ${i + 1}',
            'value': 0,
          },
        ),
        'id': 'DEVICE_001',
      },
      'eventType': 'iOStatus',
      'index': 6,
      'timestamp': now.millisecondsSinceEpoch ~/ 1000,
    });
  }
}

enum _NumericBase {
  hex(16),
  decimal(10),
  binary(2);

  const _NumericBase(this.radix);
  final int radix;
}

class _RunPayloadOperationIntent extends Intent {
  const _RunPayloadOperationIntent();
}

enum _PayloadOperation {
  jsonPretty('JSON pretty'),
  jsonMinify('JSON minify'),
  textToHex('Text -> HEX'),
  hexToText('HEX -> Text'),
  textToBase64('Text -> Base64'),
  base64ToText('Base64 -> Text'),
  hexToDecimal('HEX -> DEC'),
  decimalToHex('DEC -> HEX'),
  binaryToDecimal('BIN -> DEC'),
  decimalToBinary('DEC -> BIN'),
  hexToBinary('HEX -> BIN'),
  binaryToHex('BIN -> HEX'),
  xorChecksum('XOR checksum'),
  lrcChecksum('LRC checksum'),
  hexByteLength('HEX byte length'),
  utf8ByteLength('UTF-8 byte length');

  const _PayloadOperation(this.label);

  final String label;
}
