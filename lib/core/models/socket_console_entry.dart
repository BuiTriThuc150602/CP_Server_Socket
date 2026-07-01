enum SocketConsoleKind { incoming, outgoing, error, info }

class SocketConsoleEntry {
  const SocketConsoleEntry({
    required this.timestamp,
    required this.kind,
    required this.text,
    this.source,
    this.bytes,
  });

  final DateTime timestamp;
  final SocketConsoleKind kind;
  final String text;
  final String? source;
  final List<int>? bytes;
}
