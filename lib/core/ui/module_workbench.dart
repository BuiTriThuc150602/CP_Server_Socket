import 'package:flutter/material.dart';
import 'package:socket_server/core/models/socket_console_entry.dart';
import 'package:socket_server/core/ui/socket_console_panel.dart';

class ModuleWorkbench extends StatelessWidget {
  const ModuleWorkbench({super.key, required this.header, required this.body, this.consoleEntries, this.onClearConsole, this.consoleInitiallyExpanded = true});

  final Widget header;
  final Widget body;
  final List<SocketConsoleEntry>? consoleEntries;
  final VoidCallback? onClearConsole;
  final bool consoleInitiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(children: [_ModuleHeaderBand(child: header), Expanded(child: body), if (consoleEntries != null && onClearConsole != null) SocketConsolePanel(entries: consoleEntries!, onClear: onClearConsole!, initiallyExpanded: consoleInitiallyExpanded)]);
  }
}

class _ModuleHeaderBand extends StatelessWidget {
  const _ModuleHeaderBand({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))), child: child);
  }
}
