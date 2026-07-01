import 'package:flutter/material.dart';
import 'package:socket_server/modules/carparking/models/carparking_models.dart';
import 'package:socket_server/modules/carparking/services/carparking_controller.dart';
import 'package:socket_server/modules/carparking/ui/widgets/carparking_device_manager_sheet.dart';

class CarParkingDeviceSummary extends StatelessWidget {
  const CarParkingDeviceSummary({super.key, required this.controller});

  final CarParkingController controller;

  @override
  Widget build(BuildContext context) {
    final device = controller.devices.firstWhere((item) => item.id == controller.workspace.defaultDeviceProfileId, orElse: () => controller.devices.first);
    final summary = [device.protocolType, if (device.deviceIp.isNotEmpty) device.deviceIp, if (device.comName.isNotEmpty) device.comName, if (device.deviceId.isNotEmpty) device.deviceId].join(' • ');

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;
          return Row(
            children: [
              Icon(Icons.local_parking, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: device.label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      if (summary.isNotEmpty) ...[const TextSpan(text: '  '), TextSpan(text: summary, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)))],
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (!isNarrow) Text('${controller.devices.length} device${controller.devices.length == 1 ? '' : 's'}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, textStyle: const TextStyle(fontSize: 12)),
                onPressed: () => showCarParkingDeviceManager(context, controller),
                icon: const Icon(Icons.devices, size: 14),
                label: const Text('Devices'),
              ),
              const SizedBox(width: 6),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, textStyle: const TextStyle(fontSize: 12)),
                onPressed: () => _quickSetup(context, device),
                icon: const Icon(Icons.bolt, size: 14),
                label: const Text('Quick setup'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _quickSetup(BuildContext context, CarParkingDeviceProfile device) {
    controller.updateDevice(
      device.copyWith(
        label: device.label.isEmpty ? 'Local TCP Device' : device.label,
        deviceId: device.deviceId.isEmpty ? 'DEVICE_001' : device.deviceId,
        deviceIp: device.deviceIp.isEmpty ? '127.0.0.1' : device.deviceIp,
        devicePort: device.devicePort.isEmpty ? '1234' : device.devicePort,
        protocolType: 'TCP',
        enabled: true,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Applied local TCP quick setup.')));
  }
}
