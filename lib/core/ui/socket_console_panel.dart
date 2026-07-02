import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:socket_server/app/app_settings_controller.dart';
import 'package:socket_server/core/models/socket_console_entry.dart';
import 'package:socket_server/core/utils/payload_codec.dart';

enum _ToolTab { console, terminal }

enum _TerminalStreamKind { command, stdout, stderr, info, error }

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
  _ToolTab _tab = _ToolTab.console;

  static const double _minHeight = 36.0;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
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
              Container(
                height: _minHeight,
                decoration: BoxDecoration(color: headerColor, border: Border(top: BorderSide(color: borderColor), bottom: BorderSide(color: borderColor))),
                child: Row(
                  children: [
                    _buildToolTab('CONSOLE', _ToolTab.console),
                    _buildToolTab('TERMINAL', _ToolTab.terminal),
                    if (_tab == _ToolTab.console) ...[const VerticalDivider(width: 1), _buildConsoleFilter('ALL', null), _buildConsoleFilter('INCOMING', SocketConsoleKind.incoming), _buildConsoleFilter('OUTGOING', SocketConsoleKind.outgoing), _buildConsoleFilter('ERRORS', SocketConsoleKind.error)],
                    const Spacer(),
                    if (_tab == _ToolTab.console) ..._consoleActions(),
                    _buildAction(icon: _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, tooltip: _expanded ? 'Collapse panel' : 'Expand panel', onPressed: () => setState(() => _expanded = !_expanded)),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              if (_expanded)
                Expanded(
                  child: switch (_tab) {
                    _ToolTab.console => _ConsoleTab(entries: widget.entries, filter: _filter, pretty: _pretty),
                    _ToolTab.terminal => const _TerminalTab(),
                  },
                ),
            ],
          ),
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

  List<Widget> _consoleActions() {
    final filtered = widget.entries.where((entry) => _filter == null || entry.kind == _filter);
    return [
      _buildAction(icon: _pretty ? Icons.text_format : Icons.notes, tooltip: _pretty ? 'Raw JSON' : 'Pretty Print', onPressed: () => setState(() => _pretty = !_pretty), active: _pretty),
      _buildAction(icon: Icons.copy_all, tooltip: 'Copy all', onPressed: () => Clipboard.setData(ClipboardData(text: filtered.map((entry) => entry.text).join('\n')))),
      _buildAction(icon: Icons.clear_all, tooltip: 'Clear console', onPressed: widget.onClear),
      const SizedBox(width: 4),
    ];
  }

  Widget _buildToolTab(String label, _ToolTab tab) {
    final active = _tab == tab;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _tab = tab),
      child: Container(
        height: _minHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? theme.colorScheme.primary : Colors.transparent, width: 1.5))),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.7), letterSpacing: 0.3)),
      ),
    );
  }

  Widget _buildConsoleFilter(String label, SocketConsoleKind? kind) {
    final active = _filter == kind;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _filter = kind),
      child: Container(
        height: _minHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: active ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.65), letterSpacing: 0.3)),
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
}

class _ConsoleTab extends StatelessWidget {
  const _ConsoleTab({required this.entries, required this.filter, required this.pretty});

  final List<SocketConsoleEntry> entries;
  final SocketConsoleKind? filter;
  final bool pretty;

  @override
  Widget build(BuildContext context) {
    final filtered = _coalescedEntries(entries.where((entry) => filter == null || entry.kind == filter).toList());
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];
          final entry = item.entry;
          final text = pretty ? _prettyText(entry.text) : entry.text;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(top: 2, right: 8), child: Icon(_icon(entry.kind), color: _color(context, entry.kind), size: 14)),
                Expanded(child: SelectableText(item.count > 1 ? '$text  x${item.count}' : text, style: TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4, color: theme.colorScheme.onSurface))),
                if (entry.source != null) Padding(padding: const EdgeInsets.only(left: 8), child: Text(entry.source!, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
                Text('  ${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          );
        },
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

  Color _color(BuildContext context, SocketConsoleKind kind) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (kind) {
      SocketConsoleKind.incoming => isDark ? const Color(0xFF569CD6) : const Color(0xFF005CC5),
      SocketConsoleKind.outgoing => isDark ? const Color(0xFF4EC9B0) : const Color(0xFF22863A),
      SocketConsoleKind.error => isDark ? const Color(0xFFF14C4C) : const Color(0xFFD73A49),
      SocketConsoleKind.info => isDark ? const Color(0xFFCCCCCC) : const Color(0xFF6A737D),
    };
  }
}

class _TerminalTab extends StatefulWidget {
  const _TerminalTab();

  @override
  State<_TerminalTab> createState() => _TerminalTabState();
}

class _TerminalTabState extends State<_TerminalTab> {
  final _commandController = TextEditingController();
  final _commandFocus = FocusNode();
  final _scrollController = ScrollController();
  final List<_TerminalLine> _lines = [];
  final List<String> _history = [];

  Process? _process;
  String _cwd = Directory.current.path;
  String _shell = _defaultShell();
  int _historyIndex = 0;

  static const _maxLines = 1000;

  bool get _running => _process != null;

  @override
  void dispose() {
    _process?.kill();
    _commandController.dispose();
    _commandFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45), border: Border(bottom: BorderSide(color: theme.dividerColor))),
          child: Row(
            children: [
              Expanded(child: Text(_cwd, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
              const SizedBox(width: 8),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _shell,
                  isDense: true,
                  isExpanded: true,
                  items: [for (final shell in _candidateShells()) DropdownMenuItem(value: shell, child: Text(shell))],
                  onChanged: _running ? null : (value) => setState(() => _shell = value ?? _shell),
                  decoration: const InputDecoration(labelText: 'Shell'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(tooltip: 'Copy terminal output', onPressed: _copyOutput, icon: const Icon(Icons.copy_all, size: 18)),
              IconButton(tooltip: 'Clear terminal', onPressed: () => setState(_lines.clear), icon: const Icon(Icons.clear_all, size: 18)),
              IconButton(tooltip: 'Stop running process', onPressed: _running ? _stopProcess : null, icon: const Icon(Icons.stop, size: 18)),
            ],
          ),
        ),
        if (!settings.settings.terminalWarningDismissed) MaterialBanner(leading: const Icon(Icons.warning_amber), content: const Text('Commands run on your local machine. Use carefully.'), actions: [TextButton(onPressed: settings.dismissTerminalWarning, child: const Text('Dismiss'))]),
        Expanded(
          child: Container(
            width: double.infinity,
            color: theme.colorScheme.surface,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _lines.length,
              itemBuilder: (context, index) {
                final line = _lines[index];
                return SelectableText(line.text, style: TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.35, color: _lineColor(context, line.kind)));
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35), border: Border(top: BorderSide(color: theme.dividerColor))),
          child: Row(
            children: [
              Text(Platform.isWindows ? '>' : r'$', style: const TextStyle(fontFamily: 'monospace')),
              const SizedBox(width: 8),
              Expanded(
                child: Focus(
                  onKeyEvent: _handleHistoryKey,
                  child: TextField(
                    focusNode: _commandFocus,
                    controller: _commandController,
                    enabled: !_running,
                    minLines: 1,
                    maxLines: 1,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    decoration: const InputDecoration(hintText: 'Command', isDense: true, border: OutlineInputBorder()),
                    onSubmitted: (_) => _runCommand(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: _running ? null : _runCommand, icon: const Icon(Icons.play_arrow, size: 18), label: const Text('Run')),
            ],
          ),
        ),
      ],
    );
  }

  KeyEventResult _handleHistoryKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _history.isEmpty) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _historyIndex = (_historyIndex - 1).clamp(0, _history.length - 1);
      _setCommandFromHistory();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _historyIndex = (_historyIndex + 1).clamp(0, _history.length);
      if (_historyIndex == _history.length) {
        _commandController.clear();
      } else {
        _setCommandFromHistory();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _setCommandFromHistory() {
    final command = _history[_historyIndex];
    _commandController.value = TextEditingValue(text: command, selection: TextSelection.collapsed(offset: command.length));
  }

  Future<void> _runCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty || _running) {
      return;
    }
    if (_handleBuiltin(command)) {
      _commandController.clear();
      return;
    }

    setState(() {
      _history.add(command);
      _historyIndex = _history.length;
      _addLine('$_prompt $command', _TerminalStreamKind.command);
      _commandController.clear();
    });

    try {
      final process = await Process.start(_shell, _shellArgs(command), workingDirectory: _cwd, runInShell: false);
      setState(() => _process = process);
      unawaited(process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) => _appendLine(line, _TerminalStreamKind.stdout)).asFuture<void>());
      unawaited(process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) => _appendLine(line, _TerminalStreamKind.stderr)).asFuture<void>());
      final exitCode = await process.exitCode;
      if (mounted) {
        setState(() {
          _process = null;
          _addLine('Process exited with code $exitCode', _TerminalStreamKind.info);
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _process = null;
          _addLine('Could not run command with $_shell: $error', _TerminalStreamKind.error);
        });
      }
    }
  }

  bool _handleBuiltin(String command) {
    final lower = command.toLowerCase();
    if (lower == 'pwd') {
      setState(() {
        _history.add(command);
        _historyIndex = _history.length;
        _addLine('$_prompt $command', _TerminalStreamKind.command);
        _addLine(_cwd, _TerminalStreamKind.stdout);
      });
      return true;
    }
    if (lower == 'cd') {
      setState(() {
        _history.add(command);
        _historyIndex = _history.length;
        _addLine('$_prompt $command', _TerminalStreamKind.command);
        _addLine(_cwd, _TerminalStreamKind.stdout);
      });
      return true;
    }
    if (lower.startsWith('cd ')) {
      final target = command.substring(3).trim().replaceAll('"', '');
      final next = _resolvePath(target);
      final directory = Directory(next);
      setState(() {
        _history.add(command);
        _historyIndex = _history.length;
        _addLine('$_prompt $command', _TerminalStreamKind.command);
      });
      if (directory.existsSync()) {
        setState(() => _cwd = directory.resolveSymbolicLinksSync());
      } else {
        setState(() => _addLine('Directory not found: $target', _TerminalStreamKind.error));
      }
      return true;
    }
    return false;
  }

  String _resolvePath(String target) {
    final expanded = target == '~' || target.startsWith('~/') ? '${Platform.environment['HOME'] ?? _cwd}${target.substring(1)}' : target;
    if (_isAbsolutePath(expanded)) {
      return expanded;
    }
    return '$_cwd${Platform.pathSeparator}$expanded';
  }

  bool _isAbsolutePath(String path) {
    if (Platform.isWindows) {
      return RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(path) || path.startsWith(r'\\');
    }
    return path.startsWith('/');
  }

  void _appendLine(String text, _TerminalStreamKind kind) {
    if (!mounted) {
      return;
    }
    setState(() => _addLine(text, kind));
  }

  void _addLine(String text, _TerminalStreamKind kind) {
    _lines.add(_TerminalLine(text: text, kind: kind));
    if (_lines.length > _maxLines) {
      _lines.removeRange(0, _lines.length - _maxLines);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _stopProcess() {
    final process = _process;
    if (process == null) {
      return;
    }
    process.kill();
    setState(() {
      _process = null;
      _addLine('Process stopped.', _TerminalStreamKind.info);
    });
  }

  Future<void> _copyOutput() async {
    await Clipboard.setData(ClipboardData(text: _lines.map((line) => line.text).join('\n')));
  }

  List<String> _shellArgs(String command) {
    final shellName = _shell.toLowerCase();
    if (Platform.isWindows && shellName.endsWith('cmd.exe')) {
      return ['/c', command];
    }
    if (Platform.isWindows && (shellName.endsWith('powershell.exe') || shellName.endsWith('pwsh.exe'))) {
      return ['-NoProfile', '-Command', command];
    }
    return ['-lc', command];
  }

  Color _lineColor(BuildContext context, _TerminalStreamKind kind) {
    final scheme = Theme.of(context).colorScheme;
    return switch (kind) {
      _TerminalStreamKind.command => scheme.primary,
      _TerminalStreamKind.stdout => scheme.onSurface,
      _TerminalStreamKind.stderr || _TerminalStreamKind.error => scheme.error,
      _TerminalStreamKind.info => scheme.onSurfaceVariant,
    };
  }

  String get _prompt => Platform.isWindows ? '$_cwd>' : '$_cwd\$';

  static String _defaultShell() {
    if (Platform.isWindows) {
      return 'powershell.exe';
    }
    if (File('/bin/bash').existsSync()) {
      return '/bin/bash';
    }
    return '/bin/sh';
  }

  static List<String> _candidateShells() {
    if (Platform.isWindows) {
      return const ['powershell.exe', 'cmd.exe', 'pwsh.exe'];
    }
    return ['/bin/bash', '/bin/zsh', '/bin/sh'].where((shell) => File(shell).existsSync()).toList();
  }
}

class _TerminalLine {
  const _TerminalLine({required this.text, required this.kind});

  final String text;
  final _TerminalStreamKind kind;
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
