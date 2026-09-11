import 'package:flutter/material.dart';
import 'package:fluxlab/core/models/socket_console_entry.dart';
import 'package:fluxlab/core/ui/socket_console_panel.dart';
import 'package:fluxlab/modules/carparking/services/carparking_controller.dart';

class CarParkingConsolePanel extends StatelessWidget {
  const CarParkingConsolePanel({super.key, required this.controller});

  final CarParkingController controller;

  @override
  Widget build(BuildContext context) {
    return SocketConsolePanel(
      initiallyExpanded: false,
      entries: [
        for (final entry in controller.console)
          SocketConsoleEntry(
            timestamp: entry.timestamp,
            kind: switch (entry.kind) {
              ConsoleEntryKind.incoming => SocketConsoleKind.incoming,
              ConsoleEntryKind.outgoing => SocketConsoleKind.outgoing,
              ConsoleEntryKind.error => SocketConsoleKind.error,
              ConsoleEntryKind.info => SocketConsoleKind.info,
            },
            text: entry.text,
            source: entry.sessionId,
          ),
      ],
      onClear: controller.clearConsole,
    );
  }
}
