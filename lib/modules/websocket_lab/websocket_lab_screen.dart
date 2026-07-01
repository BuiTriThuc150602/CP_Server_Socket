import 'package:flutter/material.dart';
import 'package:socket_server/core/ui/placeholder_module.dart';

class WebSocketLabScreen extends StatelessWidget {
  const WebSocketLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderModule(
      title: 'WebSocket Lab',
      bullets: [
        'Connect to ws:// and wss:// endpoints',
        'Send and receive message console',
        'Headers and auth presets later',
      ],
    );
  }
}
