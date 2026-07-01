import 'dart:convert';

enum PayloadMode { text, json, hex, base64 }

enum PayloadFraming { raw, newline, crlf }

class PayloadCodecResult {
  const PayloadCodecResult({required this.text, required this.bytes});

  final String text;
  final List<int> bytes;
}

class PayloadCodec {
  const PayloadCodec._();

  static PayloadCodecResult encode(
    String input,
    PayloadMode mode,
    PayloadFraming framing,
  ) {
    final normalized = switch (mode) {
      PayloadMode.text => input,
      PayloadMode.json => jsonEncode(jsonDecode(input)),
      PayloadMode.hex => utf8.decode(hexToBytes(input), allowMalformed: true),
      PayloadMode.base64 => utf8.decode(
        base64Decode(input),
        allowMalformed: true,
      ),
    };
    final framed = switch (framing) {
      PayloadFraming.raw => normalized,
      PayloadFraming.newline =>
        normalized.endsWith('\n') ? normalized : '$normalized\n',
      PayloadFraming.crlf =>
        normalized.endsWith('\r\n') ? normalized : '$normalized\r\n',
    };
    return PayloadCodecResult(text: framed, bytes: utf8.encode(framed));
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
      throw const FormatException(
        'HEX input must contain an even number of digits.',
      );
    }
    return [
      for (var i = 0; i < cleaned.length; i += 2)
        int.parse(cleaned.substring(i, i + 2), radix: 16),
    ];
  }

  static String bytesToHex(List<int> bytes) {
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  static int xorChecksum(List<int> bytes) {
    return bytes.fold<int>(0, (value, byte) => value ^ byte);
  }

  static int lrcChecksum(List<int> bytes) {
    final sum = bytes.fold<int>(0, (value, byte) => (value + byte) & 0xFF);
    return ((sum ^ 0xFF) + 1) & 0xFF;
  }
}
