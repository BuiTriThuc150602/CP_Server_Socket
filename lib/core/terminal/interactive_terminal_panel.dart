import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:provider/provider.dart';
import 'package:testdeck/app/app_settings_controller.dart';
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
  bool _failedDuringStartup = false;
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
    _writeTerminal('TestDeck interactive terminal\r\n');
    _writeTerminal(
      'Select a shell and press Start. Commands run on this machine.\r\n',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final savedShell =
        context.read<AppSettingsController>().settings.terminalShellCommand;
    final savedLaunchMode =
        context.read<AppSettingsController>().settings.terminalShellLaunchMode;
    if (!_running && savedShell.isNotEmpty) {
      _selectedShell = _shells.firstWhere(
        (shell) =>
            shell.command == savedShell &&
            (savedLaunchMode.isEmpty ||
                shell.launchMode.name == savedLaunchMode),
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
                              settings.setTerminalShellCommand(
                                shell.command,
                                launchMode: shell.launchMode.name,
                              );
                            },
                  ),
                ),
              ),
              if (_selectedShell.helpText.isNotEmpty) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: _selectedShell.helpText,
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed:
                    _starting ? null : (_running ? _stopShell : _startShell),
                icon: Icon(_running ? Icons.stop : Icons.play_arrow, size: 16),
                label: Text(_running ? 'Stop' : 'Start'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _copyPlainTerminalOutput,
                icon: const Icon(Icons.copy_all, size: 16),
                label: const Text('Copy plain'),
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

  Future<void> _startShell({
    _ShellSpec? shellOverride,
    bool allowFallback = true,
  }) async {
    if (_running || _starting) return;
    setState(() => _starting = true);
    try {
      final shell = shellOverride ?? _selectedShell;
      _failedDuringStartup = false;
      _writeTerminal(
        '\r\n[Starting ${shell.label}: ${shell.launchCommand} ${shell.launchArguments.join(' ')}]\r\n',
      );
      final pty = Pty.start(
        shell.launchCommand,
        arguments: shell.launchArguments,
        workingDirectory: Directory.current.path,
        rows: _rows,
        columns: _columns,
      );
      _pty = pty;
      final startupWatch = Timer(const Duration(seconds: 2), () {
        if (mounted && identical(_pty, pty)) {
          setState(() => _starting = false);
        } else {
          _starting = false;
        }
      });
      _outputSubscription = pty.output.listen(
        (data) {
          final text = utf8.decode(data, allowMalformed: true);
          if (text.contains('8009001d') ||
              text.contains('Loading managed Windows PowerShell failed')) {
            _failedDuringStartup = true;
            _writeTerminal(
              '\r\n[Windows PowerShell failed to initialize in PTY. Falling back to CMD or PowerShell via CMD wrapper.]\r\n',
            );
          }
          _writeTerminal(text);
        },
        onError:
            (Object error) =>
                _writeTerminal('\r\n[PTY output error] $error\r\n'),
        cancelOnError: false,
      );
      unawaited(
        pty.exitCode.then((code) {
          startupWatch.cancel();
          final canFallback =
              allowFallback &&
              identical(_pty, pty) &&
              shell.fallback != null &&
              (_starting || _failedDuringStartup);
          _writeTerminal('\r\n[Process exited with code $code]\r\n');
          _outputSubscription?.cancel();
          _outputSubscription = null;
          if (identical(_pty, pty)) {
            _pty = null;
          }
          _starting = false;
          if (canFallback) {
            _writeTerminal(
              '[Direct shell failed during startup. Trying ${shell.fallback!.label}.]\r\n',
            );
            unawaited(
              _startShell(shellOverride: shell.fallback, allowFallback: false),
            );
            return;
          }
          if (mounted) setState(() {});
        }),
      );
    } catch (error) {
      final shell = shellOverride ?? _selectedShell;
      _writeTerminal('\r\n[Failed to start ${shell.label}] $error\r\n');
      if (mounted) {
        setState(() {
          _pty = null;
          _starting = false;
        });
      } else {
        _pty = null;
        _starting = false;
      }
      if (allowFallback && shell.fallback != null) {
        _writeTerminal('[Trying ${shell.fallback!.label}.]\r\n');
        await _startShell(shellOverride: shell.fallback, allowFallback: false);
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

  Future<void> _copyPlainTerminalOutput() async {
    await Clipboard.setData(
      ClipboardData(text: _stripAnsi(_transcript.toString())),
    );
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
      final shells = <_ShellSpec>[
        const _ShellSpec(
          label: 'Command Prompt',
          command: 'cmd.exe',
          launchMode: _ShellLaunchMode.direct,
        ),
      ];
      final windowsPowerShell = _windowsPowerShellPath();
      final windowsPowerShellWrapper = _ShellSpec(
        label: 'Windows PowerShell via CMD wrapper',
        command: windowsPowerShell,
        arguments: const [
          '-NoLogo',
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
        ],
        launchMode: _ShellLaunchMode.cmdWrapper,
        helpText: 'Use this if direct Windows PowerShell fails in PTY.',
      );
      shells.add(
        _ShellSpec(
          label: 'Windows PowerShell direct',
          command: windowsPowerShell,
          arguments: const [
            '-NoLogo',
            '-NoProfile',
            '-ExecutionPolicy',
            'Bypass',
            '-NoExit',
          ],
          launchMode: _ShellLaunchMode.direct,
          helpText: 'If this fails, use CMD wrapper mode.',
          fallback: windowsPowerShellWrapper,
        ),
      );
      shells.add(windowsPowerShellWrapper);

      final pwsh = _findExecutable('pwsh', const [
        r'C:\Program Files\PowerShell\7\pwsh.exe',
      ]);
      if (pwsh != null) {
        final pwshWrapper = _ShellSpec(
          label: 'PowerShell Core via CMD wrapper',
          command: pwsh,
          arguments: const ['-NoLogo', '-NoProfile', '-NoExit'],
          launchMode: _ShellLaunchMode.cmdWrapper,
          helpText: 'Use this if direct PowerShell Core fails in PTY.',
        );
        shells
          ..add(
            _ShellSpec(
              label: 'PowerShell Core direct',
              command: pwsh,
              arguments: const ['-NoLogo', '-NoProfile', '-NoExit'],
              launchMode: _ShellLaunchMode.direct,
              helpText: 'If this fails, use CMD wrapper mode.',
              fallback: pwshWrapper,
            ),
          )
          ..add(pwshWrapper);
      }
      return shells;
    }
    final shell = Platform.environment['SHELL'];
    return [
      if (shell != null && shell.trim().isNotEmpty)
        _ShellSpec(
          label: 'Default shell',
          command: shell,
          launchMode: _ShellLaunchMode.direct,
        ),
      const _ShellSpec(
        label: 'bash',
        command: '/bin/bash',
        arguments: ['-l'],
        launchMode: _ShellLaunchMode.direct,
      ),
      const _ShellSpec(
        label: 'zsh',
        command: '/bin/zsh',
        arguments: ['-l'],
        launchMode: _ShellLaunchMode.direct,
      ),
      const _ShellSpec(
        label: 'sh',
        command: '/bin/sh',
        launchMode: _ShellLaunchMode.direct,
      ),
    ];
  }

  String _windowsPowerShellPath() {
    const absolute =
        r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe';
    return File(absolute).existsSync() ? absolute : 'powershell.exe';
  }

  String? _findExecutable(String executable, List<String> commonPaths) {
    for (final path in commonPaths) {
      if (File(path).existsSync()) return path;
    }
    try {
      final result = Process.runSync('where.exe', [executable]);
      if (result.exitCode == 0) {
        final first =
            result.stdout
                .toString()
                .split(RegExp(r'\r?\n'))
                .map((line) => line.trim())
                .where((line) => line.isNotEmpty)
                .firstOrNull;
        if (first != null) return first;
      }
    } catch (_) {
      // Keep the terminal UI alive even if shell probing is unavailable.
    }
    return null;
  }
}

enum _ShellLaunchMode { direct, cmdWrapper }

class _ShellSpec {
  const _ShellSpec({
    required this.label,
    required this.command,
    required this.launchMode,
    this.arguments = const [],
    this.helpText = '',
    this.fallback,
  });

  final String label;
  final String command;
  final _ShellLaunchMode launchMode;
  final List<String> arguments;
  final String helpText;
  final _ShellSpec? fallback;

  String get launchCommand {
    return switch (launchMode) {
      _ShellLaunchMode.direct => command,
      _ShellLaunchMode.cmdWrapper => 'cmd.exe',
    };
  }

  List<String> get launchArguments {
    return switch (launchMode) {
      _ShellLaunchMode.direct => arguments,
      _ShellLaunchMode.cmdWrapper => ['/K', _cmdLine(command, arguments)],
    };
  }

  @override
  bool operator ==(Object other) {
    return other is _ShellSpec &&
        other.label == label &&
        other.command == command &&
        other.launchMode == launchMode &&
        _listEquals(other.arguments, arguments);
  }

  @override
  int get hashCode =>
      Object.hash(label, command, launchMode, Object.hashAll(arguments));
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

String _cmdLine(String command, List<String> arguments) {
  final executable = command.contains(' ') ? '"$command"' : command;
  return ([executable, ...arguments]).join(' ');
}

String _stripAnsi(String input) {
  return input.replaceAll(RegExp(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])'), '');
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
