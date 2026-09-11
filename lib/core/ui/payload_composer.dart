import 'package:flutter/material.dart';
import 'package:fluxlab/core/utils/payload_codec.dart';

class PayloadComposer extends StatefulWidget {
  const PayloadComposer({
    super.key,
    required this.onSend,
    this.initialText = '',
    this.allowFraming = true,
  });

  final ValueChanged<PayloadCodecResult> onSend;
  final String initialText;
  final bool allowFraming;

  @override
  State<PayloadComposer> createState() => _PayloadComposerState();
}

class _PayloadComposerState extends State<PayloadComposer> {
  late final TextEditingController _controller;
  PayloadMode _mode = PayloadMode.text;
  PayloadFraming _framing = PayloadFraming.raw;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<PayloadMode>(
              value: _mode,
              onChanged: (value) => setState(() => _mode = value ?? _mode),
              items: const [
                DropdownMenuItem(value: PayloadMode.text, child: Text('Text')),
                DropdownMenuItem(value: PayloadMode.json, child: Text('JSON')),
                DropdownMenuItem(value: PayloadMode.hex, child: Text('HEX')),
                DropdownMenuItem(
                  value: PayloadMode.base64,
                  child: Text('Base64'),
                ),
              ],
            ),
            if (widget.allowFraming)
              DropdownButton<PayloadFraming>(
                value: _framing,
                onChanged:
                    (value) => setState(() => _framing = value ?? _framing),
                items: const [
                  DropdownMenuItem(
                    value: PayloadFraming.raw,
                    child: Text('Raw'),
                  ),
                  DropdownMenuItem(
                    value: PayloadFraming.newline,
                    child: Text('LF'),
                  ),
                  DropdownMenuItem(
                    value: PayloadFraming.crlf,
                    child: Text('CRLF'),
                  ),
                ],
              ),
            FilledButton.icon(
              onPressed: _send,
              icon: const Icon(Icons.send),
              label: const Text('Send'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          minLines: 4,
          maxLines: 8,
          style: const TextStyle(fontFamily: 'monospace'),
          decoration: const InputDecoration(hintText: 'Payload'),
        ),
      ],
    );
  }

  void _send() {
    try {
      final result = PayloadCodec.encode(
        _controller.text,
        _mode,
        widget.allowFraming ? _framing : PayloadFraming.raw,
      );
      setState(() => _error = null);
      widget.onSend(result);
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }
}
