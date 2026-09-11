import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:fluxlab/app/app_settings_controller.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';

enum _TerminalMode { pty, runner }

class InteractiveTerminalPanel extends StatefulWidget {
  const InteractiveTerminalPanel({super.key});

  @override
  State<InteractiveTerminalPanel> createState() =>
      _InteractiveTerminalPanelState();
}

class _InteractiveTerminalPanelState extends State<InteractiveTerminalPanel> {
  late final Terminal _terminal;
  late final TerminalController _terminalController;
  late final FocusNode _terminalFocusNode;
  late final FocusNode _commandFocusNode;
  late final TextEditingController _commandController;
  late final List<_ShellSpec> _ptyShells;
  late final List<_RunnerShellSpec> _runnerShells;
  late _ShellSpec _selectedPtyShell;
  late _RunnerShellSpec _selectedRunnerShell;

  final _transcript = StringBuffer();
  final _history = <String>[];
  final _runnerSubscriptions = <StreamSubscription<List<int>>>[];

  Pty? _pty;
  Process? _runnerProcess;
  _ShellSpec? _pendingFallback;
  _TerminalMode _mode = _TerminalMode.pty;
  String _workingDirectory = Directory.current.path;
  int _historyIndex = 0;
  int _rows = 25;
  int _columns = 80;
  bool _settingsLoaded = false;
  bool _starting = false;
  bool _warningVisible = true;
  bool _failedDuringStartup = false;
  bool _ptyNoShellHintShown = false;
  bool _terminalFocused = false;

  StreamSubscription<Uint8List>? _ptyOutputSubscription;

  bool get _ptyRunning => _pty != null;
  bool get _runnerRunning => _runnerProcess != null;

  @override
  void initState() {
    super.initState();
    _ptyShells = _detectPtyShells();
    _runnerShells = _detectRunnerShells();
    _selectedPtyShell = _ptyShells.firstWhere(
      (shell) => shell.isRecommended,
      orElse: () => _ptyShells.first,
    );
    _selectedRunnerShell = _runnerShells.firstWhere(
      (shell) => shell.isRecommended,
      orElse: () => _runnerShells.first,
    );
    _terminalController = TerminalController();
    _terminalFocusNode = FocusNode(debugLabel: 'FluxLab PTY terminal');
    _terminalFocusNode.addListener(() {
      if (mounted) {
        setState(() => _terminalFocused = _terminalFocusNode.hasFocus);
      }
    });
    _commandFocusNode = FocusNode(debugLabel: 'FluxLab command runner');
    _commandController = TextEditingController();
    _terminal = Terminal(
      maxLines: 4000,
      onOutput: _writeToPty,
      onResize: (width, height, pixelWidth, pixelHeight) {
        _columns = width <= 0 ? _columns : width;
        _rows = height <= 0 ? _rows : height;
        _pty?.resize(_rows, _columns);
      },
    );
    _writeTerminal('FluxLab terminal\r\n');
    _writeTerminal(
      'PTY is best for CMD. Runner mode can execute PowerShell/pwsh commands without PTY input capture.\r\n',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_settingsLoaded) return;
    _settingsLoaded = true;
    final settings = context.read<AppSettingsController>().settings;
    _mode =
        settings.terminalMode == 'runner'
            ? _TerminalMode.runner
            : _TerminalMode.pty;
    if (settings.terminalShellId.isNotEmpty) {
      _selectedPtyShell = _ptyShells.firstWhere(
        (shell) => shell.id == settings.terminalShellId,
        orElse: () => _selectedPtyShell,
      );
      _selectedRunnerShell = _runnerShells.firstWhere(
        (shell) => shell.id == settings.terminalShellId,
        orElse: () => _selectedRunnerShell,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_mode == _TerminalMode.pty) {
        _terminalFocusNode.requestFocus();
      } else {
        _commandFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    unawaited(_stopPtyShell());
    unawaited(_stopRunnerProcess());
    _terminalController.dispose();
    _terminalFocusNode.dispose();
    _commandFocusNode.dispose();
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<AppSettingsController>();
    return Column(
      children: [
        _toolbar(theme, settings),
        if (!settings.settings.terminalWarningDismissed && _warningVisible)
          _warningBanner(theme, settings),
        Expanded(child: _terminalSurface(theme)),
        if (_mode == _TerminalMode.runner) _runnerInput(theme),
      ],
    );
  }

  Widget _toolbar(ThemeData theme, AppSettingsController settings) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          SegmentedButton<_TerminalMode>(
            segments: const [
              ButtonSegment(value: _TerminalMode.pty, label: Text('PTY')),
              ButtonSegment(value: _TerminalMode.runner, label: Text('Runner')),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            onSelectionChanged:
                (_ptyRunning || _runnerRunning)
                    ? null
                    : (value) {
                      final next = value.first;
                      setState(() => _mode = next);
                      settings.setTerminalMode(next.name);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        if (next == _TerminalMode.pty) {
                          _terminalFocusNode.requestFocus();
                        } else {
                          _commandFocusNode.requestFocus();
                        }
                      });
                    },
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 250,
            child:
                _mode == _TerminalMode.pty
                    ? _ptyShellDropdown(settings)
                    : _runnerShellDropdown(settings),
          ),
          const SizedBox(width: 6),
          _shellHelpIcon(theme),
          const SizedBox(width: 8),
          if (_mode == _TerminalMode.pty) ...[
            FilledButton.icon(
              onPressed:
                  _starting
                      ? null
                      : (_ptyRunning ? _stopPtyShell : _startPtyShell),
              icon: Icon(_ptyRunning ? Icons.stop : Icons.play_arrow, size: 16),
              label: Text(_ptyRunning ? 'Stop' : 'Start'),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: _restartPtyShell,
              icon: const Icon(Icons.restart_alt, size: 16),
              label: const Text('Restart'),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: _runnerRunning ? null : _runCurrentCommand,
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Run'),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: _runnerRunning ? _stopRunnerProcess : null,
              icon: const Icon(Icons.stop, size: 16),
              label: const Text('Stop'),
            ),
          ],
          if (_pendingFallback != null) ...[
            const SizedBox(width: 6),
            FilledButton.tonalIcon(
              onPressed:
                  _ptyRunning || _starting
                      ? null
                      : () {
                        final fallback = _pendingFallback;
                        if (fallback == null) return;
                        setState(() {
                          _selectedPtyShell = fallback;
                          _pendingFallback = null;
                        });
                        _startPtyShell(shellOverride: fallback);
                      },
              icon: const Icon(Icons.subdirectory_arrow_right, size: 16),
              label: const Text('Start fallback'),
            ),
          ],
          const SizedBox(width: 6),
          OutlinedButton.icon(
            onPressed: _copyRawTerminalOutput,
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Raw'),
          ),
          const SizedBox(width: 6),
          OutlinedButton.icon(
            onPressed: _copyPlainTerminalOutput,
            icon: const Icon(Icons.copy_all, size: 16),
            label: const Text('Plain'),
          ),
          const SizedBox(width: 6),
          OutlinedButton.icon(
            onPressed: _clearTerminal,
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _mode == _TerminalMode.runner
                  ? _workingDirectory
                  : (_ptyRunning ? 'PTY active' : 'PTY stopped'),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: _mode == _TerminalMode.runner ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ptyShellDropdown(AppSettingsController settings) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<_ShellSpec>(
        value: _selectedPtyShell,
        isExpanded: true,
        items: [
          for (final shell in _ptyShells)
            DropdownMenuItem(
              value: shell,
              child: Text(shell.label, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged:
            _ptyRunning || _starting
                ? null
                : (value) {
                  final shell = value ?? _selectedPtyShell;
                  setState(() => _selectedPtyShell = shell);
                  settings.setTerminalShellCommand(
                    shell.command,
                    shellId: shell.id,
                    launchMode: shell.launchMode.name,
                  );
                },
      ),
    );
  }

  Widget _runnerShellDropdown(AppSettingsController settings) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<_RunnerShellSpec>(
        value: _selectedRunnerShell,
        isExpanded: true,
        items: [
          for (final shell in _runnerShells)
            DropdownMenuItem(
              value: shell,
              child: Text(shell.label, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged:
            _runnerRunning
                ? null
                : (value) {
                  final shell = value ?? _selectedRunnerShell;
                  setState(() => _selectedRunnerShell = shell);
                  settings.setTerminalShellCommand(
                    shell.command,
                    shellId: shell.id,
                    launchMode: 'runner',
                  );
                },
      ),
    );
  }

  Widget _shellHelpIcon(ThemeData theme) {
    final message =
        _mode == _TerminalMode.pty
            ? _selectedPtyShell.helpText
            : _selectedRunnerShell.helpText;
    if (message.isEmpty) return const SizedBox.shrink();
    return Tooltip(
      message: message,
      child: Icon(
        Icons.info_outline,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _warningBanner(ThemeData theme, AppSettingsController settings) {
    return Container(
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
              'Terminal commands run on your local machine. Runner mode is recommended when PTY input is unreliable.',
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
    );
  }

  Widget _terminalSurface(ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? const Color(0xFF0C0C0C)
                : const Color(0xFF111111),
        border: Border.all(
          color:
              _mode == _TerminalMode.pty && _terminalFocused
                  ? theme.colorScheme.primary
                  : Colors.transparent,
        ),
      ),
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _terminalFocusNode.requestFocus,
            child: TerminalView(
              _terminal,
              controller: _terminalController,
              focusNode: _terminalFocusNode,
              autofocus: true,
              alwaysShowCursor: true,
              hardwareKeyboardOnly: Platform.isWindows,
              onTapUp: (_, _) => _terminalFocusNode.requestFocus(),
            ),
          ),
          if (_mode == _TerminalMode.pty && !_terminalFocused)
            Positioned(
              right: 10,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.88),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    'Click terminal to type',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _runnerInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Focus(
        focusNode: _commandFocusNode,
        onKeyEvent: _handleCommandKeyEvent,
        child: TextField(
          controller: _commandController,
          minLines: 1,
          maxLines: 3,
          enabled: !_runnerRunning,
          textInputAction: TextInputAction.none,
          style: const TextStyle(fontFamily: 'monospace'),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.keyboard_command_key, size: 16),
            hintText:
                Platform.isWindows
                    ? 'Run command, e.g. dir or Get-ChildItem'
                    : 'Run command, e.g. ls -la',
            suffixIcon: IconButton(
              tooltip: 'Run command',
              onPressed: _runnerRunning ? null : _runCurrentCommand,
              icon: const Icon(Icons.play_arrow, size: 18),
            ),
          ),
          onSubmitted: (_) {
            if (!_runnerRunning) _runCurrentCommand();
          },
        ),
      ),
    );
  }

  KeyEventResult _handleCommandKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (HardwareKeyboard.instance.isControlPressed &&
        key == LogicalKeyboardKey.keyC) {
      if (_runnerRunning) {
        unawaited(_stopRunnerProcess());
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _showHistory(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _showHistory(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      if (!_runnerRunning) _runCurrentCommand();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _startPtyShell({
    _ShellSpec? shellOverride,
    bool allowFallback = true,
  }) async {
    if (_ptyRunning || _starting) return;
    setState(() => _starting = true);
    try {
      final shell = shellOverride ?? _selectedPtyShell;
      _failedDuringStartup = false;
      _pendingFallback = null;
      _ptyNoShellHintShown = false;
      _writeTerminal(
        '\r\n[PTY start ${shell.label}: ${shell.launchCommand} ${shell.launchArguments.join(' ')}]\r\n',
      );
      final pty = Pty.start(
        shell.launchCommand,
        arguments: shell.launchArguments,
        workingDirectory: _workingDirectory,
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
      _ptyOutputSubscription = pty.output.listen(
        (data) {
          final text = utf8.decode(data, allowMalformed: true);
          if (text.contains('8009001d') ||
              text.contains('Loading managed Windows PowerShell failed')) {
            _failedDuringStartup = true;
            _writeTerminal(
              '\r\n[Windows PowerShell cannot initialize in PTY mode on this machine. Use Command Runner or CMD.]\r\n',
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
          final shell = shellOverride ?? _selectedPtyShell;
          final directFailed =
              identical(_pty, pty) && (_starting || _failedDuringStartup);
          _writeTerminal('\r\n[PTY exited with code $code]\r\n');
          _ptyOutputSubscription?.cancel();
          _ptyOutputSubscription = null;
          if (identical(_pty, pty)) _pty = null;
          _starting = false;
          if (directFailed && shell.id.contains('pwsh')) {
            _writeTerminal(
              '[PowerShell Core failed in PTY mode. Use Command Runner mode.]\r\n',
            );
          }
          if (allowFallback && directFailed && shell.fallback != null) {
            _pendingFallback = shell.fallback;
          }
          if (mounted) setState(() {});
        }),
      );
    } catch (error) {
      final shell = shellOverride ?? _selectedPtyShell;
      _writeTerminal('\r\n[Failed to start PTY ${shell.label}] $error\r\n');
      if (shell.id.contains('pwsh')) {
        _writeTerminal(
          '[PowerShell Core failed in PTY mode. Use Command Runner mode.]\r\n',
        );
      }
      if (mounted) {
        setState(() {
          _pty = null;
          _starting = false;
          _pendingFallback = allowFallback ? shell.fallback : null;
        });
      } else {
        _pty = null;
        _starting = false;
      }
    }
  }

  Future<void> _stopPtyShell() async {
    final pty = _pty;
    _pty = null;
    await _ptyOutputSubscription?.cancel();
    _ptyOutputSubscription = null;
    if (pty != null) {
      try {
        pty.kill();
      } catch (error) {
        _writeTerminal('\r\n[Failed to stop PTY] $error\r\n');
      }
    }
    if (mounted) setState(() => _starting = false);
  }

  Future<void> _restartPtyShell() async {
    await _stopPtyShell();
    await _startPtyShell();
  }

  Future<void> _runCurrentCommand() async {
    final command = _commandController.text.trimRight();
    if (command.trim().isEmpty || _runnerRunning) return;
    _commandController.clear();
    _history.add(command);
    _historyIndex = _history.length;
    if (await _handleRunnerBuiltIn(command)) {
      return;
    }
    await _runCommand(command);
  }

  Future<void> _runCommand(String command) async {
    final launch = _selectedRunnerShell.launch(command);
    _writeTerminal(
      '\r\n${_ansiCyan()}runner:${_ansiReset()} $_workingDirectory\r\n> $command\r\n',
    );
    try {
      final process = await Process.start(
        launch.command,
        launch.arguments,
        workingDirectory: _workingDirectory,
        runInShell: false,
      );
      setState(() => _runnerProcess = process);
      _runnerSubscriptions
        ..add(
          process.stdout.listen(
            (data) => _writeTerminal(utf8.decode(data, allowMalformed: true)),
          ),
        )
        ..add(
          process.stderr.listen(
            (data) => _writeTerminal(utf8.decode(data, allowMalformed: true)),
          ),
        );
      final code = await process.exitCode;
      await _clearRunnerSubscriptions();
      if (identical(_runnerProcess, process)) {
        _runnerProcess = null;
      }
      _writeTerminal('\r\n[Runner exited with code $code]\r\n');
      if (mounted) setState(() {});
    } catch (error) {
      _runnerProcess = null;
      await _clearRunnerSubscriptions();
      _writeTerminal('\r\n[Runner failed] $error\r\n');
      if (mounted) setState(() {});
    }
  }

  Future<bool> _handleRunnerBuiltIn(String command) async {
    final trimmed = command.trim();
    final lower = trimmed.toLowerCase();
    if (lower == 'pwd' || lower == 'cd') {
      _writeTerminal('\r\n$_workingDirectory\r\n');
      return true;
    }
    if (lower == 'cls' || lower == 'clear') {
      _clearTerminal();
      return true;
    }
    if (lower.startsWith('cd ')) {
      var path = trimmed.substring(3).trim();
      if (path.startsWith('/d ', 0)) {
        path = path.substring(3).trim();
      }
      path = _unquote(path);
      final target =
          _isAbsolutePath(path)
              ? Directory(path)
              : Directory('$_workingDirectory${Platform.pathSeparator}$path');
      if (await target.exists()) {
        _workingDirectory = target.resolveSymbolicLinksSync();
        _writeTerminal('\r\n$_workingDirectory\r\n');
        if (mounted) setState(() {});
      } else {
        _writeTerminal('\r\n[Directory not found] $path\r\n');
      }
      return true;
    }
    return false;
  }

  Future<void> _stopRunnerProcess() async {
    final process = _runnerProcess;
    _runnerProcess = null;
    if (process != null) {
      _writeTerminal('\r\n[Stopping runner process]\r\n');
      process.kill();
    }
    await _clearRunnerSubscriptions();
    if (mounted) setState(() {});
  }

  Future<void> _clearRunnerSubscriptions() async {
    for (final subscription in _runnerSubscriptions) {
      await subscription.cancel();
    }
    _runnerSubscriptions.clear();
  }

  void _showHistory(int delta) {
    if (_history.isEmpty) return;
    _historyIndex = (_historyIndex + delta).clamp(0, _history.length - 1);
    _commandController.text = _history[_historyIndex];
    _commandController.selection = TextSelection.collapsed(
      offset: _commandController.text.length,
    );
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

  Future<void> _copyRawTerminalOutput() async {
    await Clipboard.setData(ClipboardData(text: _transcript.toString()));
  }

  void _writeToPty(String output) {
    final pty = _pty;
    if (pty == null) {
      if (!_ptyNoShellHintShown) {
        _ptyNoShellHintShown = true;
        _writeTerminal(
          '\r\n[No PTY shell is running. Press Start or switch to Runner mode.]\r\n',
        );
      }
      return;
    }
    pty.write(Uint8List.fromList(utf8.encode(output)));
  }

  void _writeTerminal(String text) {
    _terminal.write(text);
    _transcript.write(text);
  }

  List<_ShellSpec> _detectPtyShells() {
    if (Platform.isWindows) {
      final shells = <_ShellSpec>[
        const _ShellSpec(
          id: 'win_cmd',
          label: 'Command Prompt',
          command: 'cmd.exe',
          launchMode: _ShellLaunchMode.direct,
          isRecommended: true,
        ),
      ];
      final powershell = _windowsPowerShellPath();
      final powershellWrapper = _ShellSpec(
        id: 'win_powershell_cmd_wrapper',
        label: 'Windows PowerShell via CMD wrapper',
        command: powershell,
        arguments: const [
          '-NoLogo',
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-NoExit',
        ],
        launchMode: _ShellLaunchMode.cmdWrapper,
        helpText:
            'Advanced fallback. Runner mode is recommended for PowerShell.',
      );
      shells
        ..add(
          _ShellSpec(
            id: 'win_powershell_direct',
            label: 'Windows PowerShell direct (experimental)',
            command: powershell,
            arguments: const [
              '-NoLogo',
              '-NoProfile',
              '-ExecutionPolicy',
              'Bypass',
              '-NoExit',
            ],
            launchMode: _ShellLaunchMode.direct,
            helpText: 'Experimental in PTY. Use Runner mode if this fails.',
            fallback: powershellWrapper,
          ),
        )
        ..add(powershellWrapper);
      final pwsh = _findExecutable('pwsh', const [
        r'C:\Program Files\PowerShell\7\pwsh.exe',
      ]);
      if (pwsh != null) {
        shells.add(
          _ShellSpec(
            id: 'win_pwsh_direct',
            label: 'PowerShell Core direct (experimental)',
            command: pwsh,
            arguments: const ['-NoLogo', '-NoProfile', '-NoExit'],
            launchMode: _ShellLaunchMode.direct,
            helpText: 'Experimental in PTY. Use Runner mode if this fails.',
          ),
        );
      }
      return shells;
    }
    final shell = Platform.environment['SHELL'];
    return [
      if (shell != null && shell.trim().isNotEmpty)
        _ShellSpec(
          id: 'posix_default',
          label: 'Default shell',
          command: shell,
          launchMode: _ShellLaunchMode.direct,
          isRecommended: true,
        ),
      const _ShellSpec(
        id: 'posix_bash',
        label: 'bash',
        command: '/bin/bash',
        arguments: ['-l'],
        launchMode: _ShellLaunchMode.direct,
      ),
      const _ShellSpec(
        id: 'posix_zsh',
        label: 'zsh',
        command: '/bin/zsh',
        arguments: ['-l'],
        launchMode: _ShellLaunchMode.direct,
      ),
      const _ShellSpec(
        id: 'posix_sh',
        label: 'sh',
        command: '/bin/sh',
        launchMode: _ShellLaunchMode.direct,
      ),
    ];
  }

  List<_RunnerShellSpec> _detectRunnerShells() {
    if (Platform.isWindows) {
      final powershell = _windowsPowerShellPath();
      final shells = <_RunnerShellSpec>[
        const _RunnerShellSpec(
          id: 'runner_cmd',
          label: 'CMD runner',
          command: 'cmd.exe',
          type: _RunnerShellType.cmd,
          isRecommended: true,
          helpText: 'Runs commands through cmd.exe /C.',
        ),
        _RunnerShellSpec(
          id: 'runner_powershell',
          label: 'Windows PowerShell runner',
          command: powershell,
          type: _RunnerShellType.windowsPowerShell,
          helpText: 'Runs commands through PowerShell -Command without PTY.',
        ),
      ];
      final pwsh = _findExecutable('pwsh', const [
        r'C:\Program Files\PowerShell\7\pwsh.exe',
      ]);
      if (pwsh != null) {
        shells.add(
          _RunnerShellSpec(
            id: 'runner_pwsh',
            label: 'PowerShell Core runner',
            command: pwsh,
            type: _RunnerShellType.pwsh,
            helpText: 'Runs commands through pwsh -Command without PTY.',
          ),
        );
      }
      return shells;
    }
    final shell = Platform.environment['SHELL'];
    return [
      _RunnerShellSpec(
        id: 'runner_posix_default',
        label: shell == null ? 'sh runner' : 'Default shell runner',
        command: shell?.trim().isNotEmpty == true ? shell! : '/bin/sh',
        type: _RunnerShellType.posix,
        isRecommended: true,
        helpText: 'Runs commands through shell -lc.',
      ),
      const _RunnerShellSpec(
        id: 'runner_sh',
        label: 'sh runner',
        command: '/bin/sh',
        type: _RunnerShellType.posix,
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
        return result.stdout
            .toString()
            .split(RegExp(r'\r?\n'))
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .firstOrNull;
      }
    } catch (_) {
      // Shell probing should never break the terminal UI.
    }
    return null;
  }
}

enum _ShellLaunchMode { direct, cmdWrapper }

class _ShellSpec {
  const _ShellSpec({
    required this.id,
    required this.label,
    required this.command,
    required this.launchMode,
    this.arguments = const [],
    this.helpText = '',
    this.isRecommended = false,
    this.fallback,
  });

  final String id;
  final String label;
  final String command;
  final _ShellLaunchMode launchMode;
  final List<String> arguments;
  final String helpText;
  final bool isRecommended;
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
        other.id == id &&
        other.command == command &&
        other.launchMode == launchMode &&
        _listEquals(other.arguments, arguments);
  }

  @override
  int get hashCode =>
      Object.hash(id, command, launchMode, Object.hashAll(arguments));
}

enum _RunnerShellType { cmd, windowsPowerShell, pwsh, posix }

class _RunnerShellSpec {
  const _RunnerShellSpec({
    required this.id,
    required this.label,
    required this.command,
    required this.type,
    this.helpText = '',
    this.isRecommended = false,
  });

  final String id;
  final String label;
  final String command;
  final _RunnerShellType type;
  final String helpText;
  final bool isRecommended;

  _CommandLaunch launch(String userCommand) {
    return switch (type) {
      _RunnerShellType.cmd => _CommandLaunch(command, ['/C', userCommand]),
      _RunnerShellType.windowsPowerShell => _CommandLaunch(command, [
        '-NoLogo',
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        userCommand,
      ]),
      _RunnerShellType.pwsh => _CommandLaunch(command, [
        '-NoLogo',
        '-NoProfile',
        '-Command',
        userCommand,
      ]),
      _RunnerShellType.posix => _CommandLaunch(command, ['-lc', userCommand]),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is _RunnerShellSpec &&
        other.id == id &&
        other.command == command &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(id, command, type);
}

class _CommandLaunch {
  const _CommandLaunch(this.command, this.arguments);

  final String command;
  final List<String> arguments;
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
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

String _ansiCyan() => '\x1b[36m';
String _ansiReset() => '\x1b[0m';

String _unquote(String input) {
  if (input.length >= 2) {
    final first = input[0];
    final last = input[input.length - 1];
    if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
      return input.substring(1, input.length - 1);
    }
  }
  return input;
}

bool _isAbsolutePath(String path) {
  if (path.startsWith('/') || path.startsWith(r'\')) return true;
  return RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(path);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
