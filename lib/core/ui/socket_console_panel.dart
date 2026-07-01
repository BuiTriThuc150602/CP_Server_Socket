import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_server/core/models/socket_console_entry.dart';
import 'package:socket_server/core/utils/payload_codec.dart';

class SocketConsolePanel extends StatefulWidget {
  const SocketConsolePanel({super.key, required this.entries, required this.onClear, this.initiallyExpanded = true});

  final List<SocketConsoleEntry> entries;
  final VoidCallback onClear;
  final bool initiallyExpanded;

  @override
  State<SocketConsolePanel> createState() => _SocketConsolePanelState();
}

class _SocketConsolePanelState extends State<SocketConsolePanel> {
  bool _expanded = true;
  double _height = 250.0;
  bool _pretty = false;
  SocketConsoleKind? _filter;
  static const double _minHeight = 36.0;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _coalescedEntries(widget.entries.where((entry) => _filter == null || entry.kind == _filter).toList());

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F3F3);
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFE5E5E5);

    return SizedBox(
      height: _expanded ? _height : _minHeight,
      child: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                height: _minHeight,
                decoration: BoxDecoration(color: headerColor, border: Border(top: BorderSide(color: borderColor), bottom: BorderSide(color: borderColor))),
                child: Row(
                  children: [
                    _buildTab('ALL', null),
                    _buildTab('INCOMING', SocketConsoleKind.incoming),
                    _buildTab('OUTGOING', SocketConsoleKind.outgoing),
                    _buildTab('ERRORS', SocketConsoleKind.error),
                    const Spacer(),
                    // Actions
                    _buildAction(icon: _pretty ? Icons.text_format : Icons.notes, tooltip: _pretty ? 'Raw JSON' : 'Pretty Print', onPressed: () => setState(() => _pretty = !_pretty), active: _pretty),
                    _buildAction(icon: Icons.copy_all, tooltip: 'Copy all', onPressed: () => Clipboard.setData(ClipboardData(text: filtered.map((e) => e.entry.text).join('\n')))),
                    _buildAction(icon: Icons.clear_all, tooltip: 'Clear console', onPressed: widget.onClear),
                    const SizedBox(width: 4),
                    _buildAction(icon: _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, tooltip: _expanded ? 'Collapse panel' : 'Expand panel', onPressed: () => setState(() => _expanded = !_expanded)),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              // Content
              if (_expanded)
                Expanded(
                  child: Container(
                    color: theme.colorScheme.surface,
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final entry = item.entry;
                        final text = _pretty ? _prettyText(entry.text) : entry.text;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(padding: const EdgeInsets.only(top: 2, right: 8), child: Icon(_icon(entry.kind), color: _color(entry.kind), size: 14)),
                              Expanded(child: SelectableText(item.count > 1 ? '$text  x${item.count}' : text, style: TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4, color: theme.colorScheme.onSurface))),
                              if (entry.source != null) Padding(padding: const EdgeInsets.only(left: 8), child: Text(entry.source!, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
                              Text(
                                '  ${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}',
                                style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
          // Drag handle for resizing
          if (_expanded)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 6,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      // Note: delta.dy is negative when dragging up.
                      // Panel is at bottom, so dragging up increases height.
                      _height = (_height - details.delta.dy).clamp(_minHeight, MediaQuery.of(context).size.height * 0.8);
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_ConsoleDisplayEntry> _coalescedEntries(List<SocketConsoleEntry> entries) {
    final result = <_ConsoleDisplayEntry>[];
    for (final entry in entries) {
      if (result.isNotEmpty && result.last.matches(entry)) {
        result[result.length - 1] = result.last.incremented();
      } else {
        result.add(_ConsoleDisplayEntry(entry: entry, count: 1));
      }
    }
    return result;
  }

  Widget _buildTab(String label, SocketConsoleKind? kind) {
    final active = _filter == kind;
    final theme = Theme.of(context);
    final color = active ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return InkWell(
      onTap: () => setState(() => _filter = kind),
      child: Container(
        height: _minHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? theme.colorScheme.primary : Colors.transparent, width: 1.5))),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: color, letterSpacing: 0.3)),
      ),
    );
  }

  Widget _buildAction({required IconData icon, required String tooltip, required VoidCallback onPressed, bool active = false}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(color: active ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(4)),
          child: Icon(icon, size: 16, color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      ),
    );
  }

  String _prettyText(String text) {
    try {
      return PayloadCodec.prettyJson(text);
    } catch (_) {
      return text;
    }
  }

  IconData _icon(SocketConsoleKind kind) {
    return switch (kind) {
      SocketConsoleKind.incoming => Icons.arrow_downward,
      SocketConsoleKind.outgoing => Icons.arrow_upward,
      SocketConsoleKind.error => Icons.close,
      SocketConsoleKind.info => Icons.info_outline,
    };
  }

  Color _color(SocketConsoleKind kind) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (kind) {
      SocketConsoleKind.incoming => isDark ? const Color(0xFF569CD6) : const Color(0xFF005CC5), // Blue
      SocketConsoleKind.outgoing => isDark ? const Color(0xFF4EC9B0) : const Color(0xFF22863A), // Green
      SocketConsoleKind.error => isDark ? const Color(0xFFF14C4C) : const Color(0xFFD73A49), // Red
      SocketConsoleKind.info => isDark ? const Color(0xFFCCCCCC) : const Color(0xFF6A737D), // Gray
    };
  }
}

class _ConsoleDisplayEntry {
  const _ConsoleDisplayEntry({required this.entry, required this.count});

  final SocketConsoleEntry entry;
  final int count;

  bool matches(SocketConsoleEntry other) {
    return entry.kind == other.kind && entry.source == other.source && entry.text == other.text;
  }

  _ConsoleDisplayEntry incremented() {
    return _ConsoleDisplayEntry(entry: entry, count: count + 1);
  }
}
