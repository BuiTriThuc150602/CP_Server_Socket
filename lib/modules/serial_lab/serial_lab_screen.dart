import 'package:flutter/material.dart';
import 'package:socket_server/core/ui/placeholder_module.dart';

class SerialLabScreen extends StatelessWidget {
  const SerialLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderModule(
      title: 'Serial/COM Lab',
      bullets: [
        'List available desktop serial ports',
        'Baud, data bits, parity, and stop-bit controls',
        'ASCII and HEX send/receive console',
        'Platform-specific serial access isolated behind a service',
      ],
    );
  }
}
