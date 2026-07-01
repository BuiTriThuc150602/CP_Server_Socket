import 'dart:convert';

enum PayloadMode { text, json, hex, base64 }

enum PayloadFraming { raw, newline, crlf }

class PayloadCodecResult {
  const PayloadCodecResult({required this.text, required this.bytes, required this.previewText, required this.mode, required this.framing});

  final String text;
  final List<int> bytes;
  final String previewText;
  final PayloadMode mode;
  final PayloadFraming framing;
}

class PayloadCodec {
  const PayloadCodec._();

  static PayloadCodecResult encode(String input, PayloadMode mode, PayloadFraming framing) {
    final payloadBytes = switch (mode) {
      PayloadMode.text => utf8.encode(input),
      PayloadMode.json => utf8.encode(jsonEncode(jsonDecode(input))),
      PayloadMode.hex => hexToBytes(input),
      PayloadMode.base64 => base64Decode(_normalizeBase64(input)),
    };
    final framedBytes = <int>[
      ...payloadBytes,
      ...switch (framing) {
        PayloadFraming.raw => const <int>[],
        PayloadFraming.newline => const <int>[0x0A],
        PayloadFraming.crlf => const <int>[0x0D, 0x0A],
      },
    ];
    final text = switch (mode) {
      PayloadMode.text || PayloadMode.json => utf8.decode(framedBytes, allowMalformed: true),
      PayloadMode.hex || PayloadMode.base64 => previewBytes(framedBytes),
    };
    return PayloadCodecResult(text: text, bytes: framedBytes, previewText: previewBytes(framedBytes), mode: mode, framing: framing);
  }

  static String prettyJson(String input) {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(input));
  }

  static String minifyJson(String input) {
    return jsonEncode(jsonDecode(input));
  }

  static List<int> hexToBytes(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (cleaned.length.isOdd) {
      throw const FormatException('HEX input must contain an even number of digits.');
    }
    return [for (var i = 0; i < cleaned.length; i += 2) int.parse(cleaned.substring(i, i + 2), radix: 16)];
  }

  static String bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
  }

  static String previewBytes(List<int> bytes, {int maxBytes = 256}) {
    final previewBytes = bytes.length > maxBytes ? bytes.take(maxBytes).toList() : bytes;
    final text = utf8.decode(previewBytes, allowMalformed: true);
    final suffix = bytes.length > maxBytes ? ' ...' : '';
    return '$text$suffix\nHEX ${bytesToHex(previewBytes)}$suffix';
  }

  static int xorChecksum(List<int> bytes) {
    return bytes.fold<int>(0, (value, byte) => value ^ byte);
  }

  static int lrcChecksum(List<int> bytes) {
    final sum = bytes.fold<int>(0, (value, byte) => (value + byte) & 0xFF);
    return ((sum ^ 0xFF) + 1) & 0xFF;
  }

  static String _normalizeBase64(String input) {
    return input.replaceAll(RegExp(r'\s+'), '');
  }
}
