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

class SocketConsoleDeduper {
  SocketConsoleDeduper({this.window = const Duration(milliseconds: 300)});

  final Duration window;
  SocketConsoleEntry? _lastEntry;

  // Engine/service methods can both emit an error stream and throw to the UI
  // callback. Suppress only the same event inside a tiny window; real repeated
  // socket traffic at normal intervals still remains visible.
  bool shouldSuppress(SocketConsoleEntry entry) {
    final last = _lastEntry;
    _lastEntry = entry;
    if (last == null) {
      return false;
    }
    return entry.kind == last.kind &&
        entry.source == last.source &&
        entry.text == last.text &&
        entry.timestamp.difference(last.timestamp).abs() <= window;
  }
}
