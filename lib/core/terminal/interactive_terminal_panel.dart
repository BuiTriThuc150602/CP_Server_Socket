import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/flutter.dart';
import 'package:xterm/xterm.dart';

class InteractiveTerminalPanel extends StatefulWidget {
  const InteractiveTerminalPanel({super.key});

  @override
  State<InteractiveTerminalPanel> createState() => _InteractiveTerminalPanelState();
}

class _InteractiveTerminalPanelState extends State<InteractiveTerminalPanel> {
  late final Terminal _terminal;
  late final List<_ShellSpec> _shells;
  late _ShellSpec _selectedShell;

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
    _terminal.write('Socket Testing Tools interactive terminal\r\n');
    _terminal.write('Select a shell and press Start. Commands run on this machine.\r\n');
  }

  @override
  void dispose() {
    unawaited(_stopShell());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              Icon(_running ? Icons.terminal : Icons.terminal_outlined, size: 18, color: _running ? Colors.green : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              SizedBox(
                width: 220,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_ShellSpec>(
                    value: _selectedShell,
                    isExpanded: true,
                    items: [for (final shell in _shells) DropdownMenuItem(value: shell, child: Text(shell.label, overflow: TextOverflow.ellipsis))],
                    onChanged: _running || _starting ? null : (value) => setState(() => _selectedShell = value ?? _selectedShell),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _starting ? null : (_running ? _stopShell : _startShell),
                icon: Icon(_running ? Icons.stop : Icons.play_arrow, size: 16),
                label: Text(_running ? 'Stop' : 'Start'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: _clearTerminal, icon: const Icon(Icons.clear_all, size: 16), label: const Text('Clear')),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: _restartShell, icon: const Icon(Icons.restart_alt, size: 16), label: const Text('Restart')),
              const Spacer(),
              Text(_running ? 'PTY active' : 'PTY stopped', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        if (_warningVisible)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: theme.colorScheme.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(child: Text('Interactive terminal commands run on your local machine. Use carefully.', style: theme.textTheme.bodySmall)),
                IconButton(tooltip: 'Dismiss', visualDensity: VisualDensity.compact, onPressed: () => setState(() => _warningVisible = false), icon: const Icon(Icons.close, size: 16)),
              ],
            ),
          ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(color: theme.brightness == Brightness.dark ? const Color(0xFF0C0C0C) : const Color(0xFF111111)),
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
      _terminal.write('\r\n[Starting ${shell.command} ${shell.arguments.join(' ')}]\r\n');
      final pty = Pty.start(
        shell.command,
        arguments: shell.arguments,
        workingDirectory: Directory.current.path,
        rows: _rows,
        columns: _columns,
      );
      _pty = pty;
      _outputSubscription = pty.output.listen(
        (data) => _terminal.write(utf8.decode(data, allowMalformed: true)),
        onError: (Object error) => _terminal.write('\r\n[PTY output error] $error\r\n'),
        cancelOnError: false,
      );
      unawaited(
        pty.exitCode.then((code) {
          _terminal.write('\r\n[Process exited with code $code]\r\n');
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
      _terminal.write('\r\n[Failed to start shell] $error\r\n');
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
        _terminal.write('\r\n[Failed to stop shell] $error\r\n');
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
  }

  void _writeToPty(String output) {
    final pty = _pty;
    if (pty == null) {
      _terminal.write('\r\n[No shell is running. Press Start first.]\r\n');
      return;
    }
    pty.write(Uint8List.fromList(utf8.encode(output)));
  }

  List<_ShellSpec> _detectShells() {
    if (Platform.isWindows) {
      return const [
        _ShellSpec(label: 'PowerShell', command: 'powershell.exe', arguments: ['-NoLogo']),
        _ShellSpec(label: 'Command Prompt', command: 'cmd.exe'),
        _ShellSpec(label: 'PowerShell Core', command: 'pwsh.exe', arguments: ['-NoLogo']),
      ];
    }
    final shell = Platform.environment['SHELL'];
    return [
      if (shell != null && shell.trim().isNotEmpty) _ShellSpec(label: 'Default shell', command: shell),
      const _ShellSpec(label: 'bash', command: '/bin/bash', arguments: ['-l']),
      const _ShellSpec(label: 'zsh', command: '/bin/zsh', arguments: ['-l']),
      const _ShellSpec(label: 'sh', command: '/bin/sh'),
    ];
  }
}

class _ShellSpec {
  const _ShellSpec({required this.label, required this.command, this.arguments = const []});

  final String label;
  final String command;
  final List<String> arguments;
}
