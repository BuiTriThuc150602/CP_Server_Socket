import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_server/modules/carparking/services/carparking_controller.dart';
import 'package:socket_server/modules/carparking/ui/widgets/carparking_console_panel.dart';
import 'package:socket_server/modules/carparking/ui/widgets/carparking_device_summary.dart';
import 'package:socket_server/modules/carparking/ui/widgets/carparking_scenario_toolbar.dart';
import 'package:socket_server/modules/carparking/ui/widgets/carparking_server_toolbar.dart';
import 'package:socket_server/modules/carparking/ui/widgets/carparking_signal_list.dart';

class CarParkingModuleScreen extends StatelessWidget {
  const CarParkingModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) => CarParkingController()..initialize(), child: const _CarParkingModuleBody());
  }
}

class _CarParkingModuleBody extends StatefulWidget {
  const _CarParkingModuleBody();

  @override
  State<_CarParkingModuleBody> createState() => _CarParkingModuleBodyState();
}

class _CarParkingModuleBodyState extends State<_CarParkingModuleBody> {
  final Set<String> _selectedRows = {};

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CarParkingController>();
    if (!controller.initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        CarParkingServerToolbar(controller: controller),
        if (controller.warning != null) _Banner(text: controller.warning!, color: Colors.amber),
        if (controller.serverError != null) _Banner(text: controller.serverError!, color: Colors.red),
        // Compact device summary under the server bar
        CarParkingDeviceSummary(controller: controller),
        Expanded(
          child: Column(children: [CarParkingScenarioToolbar(controller: controller, selectedRows: _selectedRows), Expanded(child: CarParkingSignalList(controller: controller, selectedRows: _selectedRows, onSelectionChanged: () => setState(() {}))), CarParkingConsolePanel(controller: controller)]),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});

  final String text;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.18),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: [Icon(Icons.warning_amber, color: color.shade700, size: 16), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 12)))]),
    );
  }
}
