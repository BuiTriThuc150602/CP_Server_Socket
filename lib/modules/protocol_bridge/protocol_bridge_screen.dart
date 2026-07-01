import 'package:flutter/material.dart';
import 'package:socket_server/core/ui/placeholder_module.dart';

class ProtocolBridgeScreen extends StatelessWidget {
  const ProtocolBridgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderModule(
      title: 'Protocol Bridge',
      bullets: [
        'TCP to Serial',
        'TCP to WebSocket',
        'Serial to WebSocket',
        'Routing, transform, and logging rules later',
      ],
    );
  }
}
