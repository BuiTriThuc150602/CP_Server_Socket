import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:provider/provider.dart';
import 'package:socket_server/app/app_settings_controller.dart';
import 'package:xterm/xterm.dart';

class InteractiveTerminalPanel extends StatefulWidget {
  const InteractiveTerminalPanel({super.key});

  @override
  State<InteractiveTerminalPanel> createState() =>
      _InteractiveTerminalPanelState();
}

class _InteractiveTerminalPanelState extends State<InteractiveTerminalPanel> {
  late final Terminal _terminal;
  late final List<_ShellSpec> _shells;
  late _ShellSpec _selectedShell;
  final _transcript = StringBuffer();

  Pty? _pty;
  StreamSubscription<Uint8List>? _outputSubscription;
  bool _starting = false;
  bool _warningVisible = true;
  int _rows = 25;
  int _columns = 80;

  bool get _running => _pty != null;

  @override
  void initState() {
    super.initState();
    _shells = _detectShells();
    _selectedShell = _shells.first;
    _terminal = Terminal(
      maxLines: 3000,
      onOutput: _writeToPty,
      onResize: (width, height, pixelWidth, pixelHeight) {
        _columns = width <= 0 ? _columns : width;
        _rows = height <= 0 ? _rows : height;
        _pty?.resize(_rows, _columns);
      },
    );
    _writeTerminal('Socket Testing Tools interactive terminal\r\n');
    _writeTerminal(
      'Select a shell and press Start. Commands run on this machine.\r\n',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final savedShell =
        context.read<AppSettingsController>().settings.terminalShellCommand;
    if (!_running && savedShell.isNotEmpty) {
      _selectedShell = _shells.firstWhere(
        (shell) => shell.command == savedShell,
        orElse: () => _selectedShell,
      );
    }
  }

  @override
  void dispose() {
    unawaited(_stopShell());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<AppSettingsController>();
    return Column(
      children: [
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Icon(
                _running ? Icons.terminal : Icons.terminal_outlined,
                size: 18,
                color:
                    _running
                        ? Colors.green
                        : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 220,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_ShellSpec>(
                    value: _selectedShell,
                    isExpanded: true,
                    items: [
                      for (final shell in _shells)
                        DropdownMenuItem(
                          value: shell,
                          child: Text(
                            shell.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged:
                        _running || _starting
                            ? null
                            : (value) {
                              final shell = value ?? _selectedShell;
                              setState(() => _selectedShell = shell);
                              settings.setTerminalShellCommand(shell.command);
                            },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed:
                    _starting ? null : (_running ? _stopShell : _startShell),
                icon: Icon(_running ? Icons.stop : Icons.play_arrow, size: 16),
                label: Text(_running ? 'Stop' : 'Start'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _copyTerminalOutput,
                icon: const Icon(Icons.copy_all, size: 16),
                label: const Text('Copy'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _clearTerminal,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _restartShell,
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('Restart'),
              ),
              const Spacer(),
              Text(
                _running ? 'PTY active' : 'PTY stopped',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (!settings.settings.terminalWarningDismissed && _warningVisible)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Interactive terminal commands run on your local machine. Use carefully.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() => _warningVisible = false);
                    settings.dismissTerminalWarning();
                  },
                  icon: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  theme.brightness == Brightness.dark
                      ? const Color(0xFF0C0C0C)
                      : const Color(0xFF111111),
            ),
            child: TerminalView(_terminal),
          ),
        ),
      ],
    );
  }

  Future<void> _startShell() async {
    if (_running || _starting) return;
    setState(() => _starting = true);
    try {
      final shell = _selectedShell;
      _writeTerminal(
        '\r\n[Starting ${shell.command} ${shell.arguments.join(' ')}]\r\n',
      );
      final pty = Pty.start(
        shell.command,
        arguments: shell.arguments,
        workingDirectory: Directory.current.path,
        rows: _rows,
        columns: _columns,
      );
      _pty = pty;
      _outputSubscription = pty.output.listen(
        (data) => _writeTerminal(utf8.decode(data, allowMalformed: true)),
        onError:
            (Object error) =>
                _writeTerminal('\r\n[PTY output error] $error\r\n'),
        cancelOnError: false,
      );
      unawaited(
        pty.exitCode.then((code) {
          _writeTerminal('\r\n[Process exited with code $code]\r\n');
          _outputSubscription?.cancel();
          _outputSubscription = null;
          if (mounted) {
            setState(() {
              _pty = null;
              _starting = false;
            });
          } else {
            _pty = null;
            _starting = false;
          }
        }),
      );
      if (mounted) setState(() => _starting = false);
    } catch (error) {
      _writeTerminal('\r\n[Failed to start shell] $error\r\n');
      if (mounted) {
        setState(() {
          _pty = null;
          _starting = false;
        });
      } else {
        _pty = null;
        _starting = false;
      }
    }
  }

  Future<void> _stopShell() async {
    final pty = _pty;
    _pty = null;
    await _outputSubscription?.cancel();
    _outputSubscription = null;
    if (pty != null) {
      try {
        pty.kill();
      } catch (error) {
        _writeTerminal('\r\n[Failed to stop shell] $error\r\n');
      }
    }
    if (mounted) setState(() => _starting = false);
  }

  Future<void> _restartShell() async {
    await _stopShell();
    await _startShell();
  }

  void _clearTerminal() {
    _terminal.write('\x1b[2J\x1b[H');
    _transcript.clear();
  }

  Future<void> _copyTerminalOutput() async {
    await Clipboard.setData(ClipboardData(text: _transcript.toString()));
  }

  void _writeToPty(String output) {
    final pty = _pty;
    if (pty == null) {
      _writeTerminal('\r\n[No shell is running. Press Start first.]\r\n');
      return;
    }
    pty.write(Uint8List.fromList(utf8.encode(output)));
  }

  void _writeTerminal(String text) {
    _terminal.write(text);
    _transcript.write(text);
  }

  List<_ShellSpec> _detectShells() {
    if (Platform.isWindows) {
      return const [
        _ShellSpec(
          label: 'PowerShell',
          command: 'powershell.exe',
          arguments: ['-NoLogo'],
        ),
        _ShellSpec(label: 'Command Prompt', command: 'cmd.exe'),
        _ShellSpec(
          label: 'PowerShell Core',
          command: 'pwsh.exe',
          arguments: ['-NoLogo'],
        ),
      ];
    }
    final shell = Platform.environment['SHELL'];
    return [
      if (shell != null && shell.trim().isNotEmpty)
        _ShellSpec(label: 'Default shell', command: shell),
      const _ShellSpec(label: 'bash', command: '/bin/bash', arguments: ['-l']),
      const _ShellSpec(label: 'zsh', command: '/bin/zsh', arguments: ['-l']),
      const _ShellSpec(label: 'sh', command: '/bin/sh'),
    ];
  }
}

class _ShellSpec {
  const _ShellSpec({
    required this.label,
    required this.command,
    this.arguments = const [],
  });

  final String label;
  final String command;
  final List<String> arguments;

  @override
  bool operator ==(Object other) {
    return other is _ShellSpec &&
        other.label == label &&
        other.command == command &&
        _listEquals(other.arguments, arguments);
  }

  @override
  int get hashCode => Object.hash(label, command, Object.hashAll(arguments));
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
