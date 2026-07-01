import 'package:flutter/material.dart';
import 'package:socket_server/core/ui/placeholder_module.dart';

class PayloadStudioScreen extends StatelessWidget {
  const PayloadStudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderModule(
      title: 'Payload Studio / Converter',
      bullets: [
        'JSON formatting and validation',
        'Text, UTF-8, and HEX conversion',
        'Reusable payload snippets',
      ],
    );
  }
}
