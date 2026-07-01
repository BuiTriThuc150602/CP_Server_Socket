import 'package:flutter/material.dart';
import 'package:socket_server/core/ui/placeholder_module.dart';

class TcpLabScreen extends StatelessWidget {
  const TcpLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderModule(
      title: 'TCP Socket Lab',
      bullets: [
        'TCP client/server modes',
        'Free text, JSON, and hex send modes',
        'Realtime receive console',
        'Newline and raw framing options',
      ],
    );
  }
}
