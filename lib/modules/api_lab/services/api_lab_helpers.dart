part of '../api_lab_screen.dart';

class _ResolvedRequest {
  const _ResolvedRequest({
    required this.url,
    required this.queryParameters,
    required this.headers,
    required this.data,
  });

  final String url;
  final Map<String, String> queryParameters;
  final Map<String, String> headers;
  final Object? data;
}

const Object _notSet = Object();

List<ApiKeyValue> _defaultRequestHeaders() {
  return const [
    ApiKeyValue(
      key: 'Accept',
      value: 'application/json',
      enabled: true,
      description: 'Default JSON response preference.',
    ),
    ApiKeyValue(
      key: 'Content-Type',
      value: 'application/json',
      enabled: false,
      description: 'Enable for JSON request bodies.',
    ),
    ApiKeyValue(
      key: 'Authorization',
      value: 'Bearer {{token}}',
      enabled: false,
      description: 'Enable and define token in an environment.',
    ),
    ApiKeyValue(
      key: 'User-Agent',
      value: 'FluxLab/{{appVersion}}',
      enabled: false,
      description: 'Identify FluxLab requests.',
    ),
    ApiKeyValue(
      key: 'X-Request-Id',
      value: r'{{$uuid}}',
      enabled: false,
      description: 'Unique request correlation ID.',
    ),
    ApiKeyValue(
      key: 'Cache-Control',
      value: 'no-cache',
      enabled: false,
      description: 'Bypass cached responses.',
    ),
  ];
}

Color _methodColor(String method) {
  return switch (method.toUpperCase()) {
    'GET' => const Color(0xFF059669),
    'POST' => const Color(0xFF2563EB),
    'PUT' => const Color(0xFFD97706),
    'PATCH' => const Color(0xFF7C3AED),
    'DELETE' => const Color(0xFFDC2626),
    _ => const Color(0xFF475569),
  };
}

Color _statusColor(int? statusCode) {
  if (statusCode == null) return const Color(0xFFDC2626);
  if (statusCode >= 200 && statusCode < 300) return const Color(0xFF059669);
  if (statusCode >= 300 && statusCode < 400) return const Color(0xFF2563EB);
  if (statusCode >= 400 && statusCode < 500) return const Color(0xFFD97706);
  return const Color(0xFFDC2626);
}

String _previewText(String text) {
  final pretty = _prettyJson(text);
  if (pretty.length <= 12000) return pretty;
  return '${pretty.substring(0, 12000)}\n\n...preview truncated...';
}

List<List<String>> _parseCsv(String text) {
  final rows = <List<String>>[];
  final current = <String>[];
  final cell = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    final next = i + 1 < text.length ? text[i + 1] : '';
    if (char == '"' && inQuotes && next == '"') {
      cell.write('"');
      i++;
    } else if (char == '"') {
      inQuotes = !inQuotes;
    } else if (char == ',' && !inQuotes) {
      current.add(cell.toString());
      cell.clear();
    } else if ((char == '\n' || char == '\r') && !inQuotes) {
      if (char == '\r' && next == '\n') i++;
      current.add(cell.toString());
      cell.clear();
      if (current.any((value) => value.trim().isNotEmpty)) {
        rows.add([...current]);
      }
      current.clear();
    } else {
      cell.write(char);
    }
  }
  current.add(cell.toString());
  if (current.any((value) => value.trim().isNotEmpty)) rows.add(current);
  return rows;
}

String _shellQuote(String value) {
  return "'${value.replaceAll("'", r"'\''")}'";
}

List<String> _splitCommandLine(String input) {
  final tokens = <String>[];
  final current = StringBuffer();
  String? quote;
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if ((char == '"' || char == "'") && quote == null) {
      quote = char;
    } else if (char == quote) {
      quote = null;
    } else if (char.trim().isEmpty && quote == null) {
      if (current.isNotEmpty) {
        tokens.add(current.toString());
        current.clear();
      }
    } else if (char == '\\' && i + 1 < input.length) {
      current.write(input[++i]);
    } else {
      current.write(char);
    }
  }
  if (current.isNotEmpty) tokens.add(current.toString());
  return tokens;
}

String _newId(String prefix) {
  return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';
}

int _intValue(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _nullableInt(Object? value) {
  if (value == null) return null;
  return _intValue(value, 0);
}

ApiBodyType _bodyType(Object? value) {
  return ApiBodyType.values
          .where((type) => type.name == value?.toString())
          .firstOrNull ??
      ApiBodyType.none;
}

List<Map<String, dynamic>> _maps(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<ApiKeyValue> _keyValues(Object? value) {
  return _maps(value).map(ApiKeyValue.fromJson).toList();
}

Map<String, List<String>> _headersMap(Object? value) {
  final map = _map(value);
  return {
    for (final entry in map.entries)
      entry.key:
          (entry.value is List
              ? (entry.value as List).map((item) => item.toString()).toList()
              : [entry.value.toString()]),
  };
}

String _responseText(Object? data) {
  if (data == null) return '';
  if (data is String) return data;
  try {
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data.toString();
  }
}

String _prettyJson(String text) {
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(text));
  } catch (_) {
    return text;
  }
}

String _uuidLike() {
  final random = Random();
  String hex(int length) =>
      List.generate(length, (_) => random.nextInt(16).toRadixString(16)).join();
  return '${hex(8)}-${hex(4)}-${hex(4)}-${hex(4)}-${hex(12)}';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
