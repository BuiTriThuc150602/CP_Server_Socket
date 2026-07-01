import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_server/modules/carparking/models/carparking_models.dart';
import 'package:socket_server/modules/carparking/services/carparking_controller.dart';

Future<void> showCarParkingDeviceManager(BuildContext context, CarParkingController controller) {
  return showDialog<void>(context: context, builder: (context) => ChangeNotifierProvider.value(value: controller, child: Dialog(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 960, maxHeight: 740), child: const _DeviceManager()))));
}

class _DeviceManager extends StatefulWidget {
  const _DeviceManager();

  @override
  State<_DeviceManager> createState() => _DeviceManagerState();
}

class _DeviceManagerState extends State<_DeviceManager> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CarParkingController>();
    final devices = controller.devices;
    final hasSelection = _selectedIds.isNotEmpty;
    final canDelete = hasSelection && devices.length - _selectedIds.length >= 1;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: Row(
            children: [
              Text('Device Profiles', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (hasSelection) ...[
                Text('${_selectedIds.length} selected', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: canDelete ? () => _deleteSelected(context, controller) : null, icon: const Icon(Icons.delete_outline, size: 16), label: const Text('Delete selected'), style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error)),
                const SizedBox(width: 8),
                TextButton(onPressed: () => setState(() => _selectedIds.clear()), child: const Text('Clear')),
                const SizedBox(width: 8),
              ],
              // Add buttons
              FilledButton.icon(onPressed: () => controller.addDevice(), icon: const Icon(Icons.add, size: 16), label: const Text('Empty')),
              const SizedBox(width: 6),
              _addMenuButton(context, controller),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return _DeviceEditor(
                key: ValueKey(device.id),
                device: device,
                isDefault: device.id == controller.workspace.defaultDeviceProfileId,
                controller: controller,
                selected: _selectedIds.contains(device.id),
                onSelectChanged: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedIds.add(device.id);
                    } else {
                      _selectedIds.remove(device.id);
                    }
                  });
                },
              );
            },
          ),
        ),
        const Divider(height: 1),
        Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.all(10), child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')))),
      ],
    );
  }

  Widget _addMenuButton(BuildContext context, CarParkingController controller) {
    return PopupMenuButton<String>(
      tooltip: 'Add from template',
      child: OutlinedButton.icon(
        onPressed: null, // handled by popup
        icon: const Icon(Icons.arrow_drop_down, size: 16),
        label: const Text('Templates'),
      ),
      onSelected: (value) {
        switch (value) {
          case 'local':
            controller.addDeviceProfile(CarParkingDeviceProfile.defaults().copyWith(id: newCarParkingId('device'), label: 'Local TCP Device', deviceId: 'DEVICE_001', deviceIp: '127.0.0.1', devicePort: '1234', protocolType: 'TCP'));
          case 'serial':
            controller.addDeviceProfile(CarParkingDeviceProfile.defaults().copyWith(id: newCarParkingId('device'), label: 'Serial COM Device', protocolType: 'SERIAL', comName: 'COM1', baudRate: '9600'));
          case 'carparking':
            controller.addDeviceProfile(CarParkingDeviceProfile.defaults().copyWith(id: newCarParkingId('device'), label: 'CarParking Gateway', deviceId: 'CP_GATEWAY_001', deviceName: 'Device Gateway', protocolType: 'TCP'));
        }
      },
      itemBuilder: (context) => const [PopupMenuItem(value: 'local', child: Text('Local TCP default')), PopupMenuItem(value: 'serial', child: Text('Serial / COM template')), PopupMenuItem(value: 'carparking', child: Text('CarParking default'))],
    );
  }

  Future<void> _deleteSelected(BuildContext context, CarParkingController controller) async {
    final ids = List<String>.from(_selectedIds);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete devices?'),
            content: Text(
              'Delete ${ids.length} device profile${ids.length == 1 ? '' : 's'}? '
              'Any signal rows using these devices will be reassigned to the first remaining device.',
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))],
          ),
    );
    if (confirmed == true) {
      for (final id in ids) {
        controller.deleteDevice(id);
      }
      setState(() => _selectedIds.clear());
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DeviceEditor extends StatefulWidget {
  const _DeviceEditor({super.key, required this.device, required this.isDefault, required this.controller, required this.selected, required this.onSelectChanged});

  final CarParkingDeviceProfile device;
  final bool isDefault;
  final CarParkingController controller;
  final bool selected;
  final ValueChanged<bool> onSelectChanged;

  @override
  State<_DeviceEditor> createState() => _DeviceEditorState();
}

class _DeviceEditorState extends State<_DeviceEditor> {
  late CarParkingDeviceProfile _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.device;
  }

  @override
  void didUpdateWidget(covariant _DeviceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync if external update (e.g. another editor changed the same device)
    if (oldWidget.device != widget.device) {
      _draft = widget.device;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: widget.selected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      child: ExpansionTile(
        initiallyExpanded: widget.isDefault,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Checkbox(value: widget.selected, onChanged: (v) => widget.onSelectChanged(v ?? false)), IconButton(tooltip: 'Set default', onPressed: () => widget.controller.setDefaultDevice(_draft.id), icon: Icon(widget.isDefault ? Icons.star : Icons.star_border, size: 20))],
        ),
        title: Text(_draft.label),
        subtitle: Text('${_draft.protocolType}  ${_draft.deviceId}'),
        trailing: Switch(value: _draft.enabled, onChanged: (value) => _update(_draft.copyWith(enabled: value))),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          _section('Basic', [
            _field('Label', _draft.label, (value) => _update(_draft.copyWith(label: value))),
            _field('Device ID', _draft.deviceId, (value) => _update(_draft.copyWith(deviceId: value))),
            _field('Device name', _draft.deviceName, (value) => _update(_draft.copyWith(deviceName: value))),
            _field('Protocol', _draft.protocolType, (value) => _update(_draft.copyWith(protocolType: value))),
          ]),
          _section('TCP', [_field('Device IP', _draft.deviceIp, (value) => _update(_draft.copyWith(deviceIp: value))), _field('Device port', _draft.devicePort, (value) => _update(_draft.copyWith(devicePort: value)))]),
          _section('Serial', [_field('COM name', _draft.comName, (value) => _update(_draft.copyWith(comName: value))), _field('Baud rate', _draft.baudRate, (value) => _update(_draft.copyWith(baudRate: value)))]),
          _section('Metadata', [
            _field('Manufacturer', _draft.manufacturer, (value) => _update(_draft.copyWith(manufacturer: value))),
            _field('Model', _draft.modelName, (value) => _update(_draft.copyWith(modelName: value))),
            _field('Reader formats', _draft.readerCardFormats.join(', '), (value) => _update(_draft.copyWith(readerCardFormats: value.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList()))),
          ]),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(onPressed: () => widget.controller.duplicateDevice(_draft), icon: const Icon(Icons.copy, size: 16), label: const Text('Duplicate')),
              TextButton.icon(style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error), onPressed: () => _confirmDelete(context), icon: const Icon(Icons.delete_outline, size: 16), label: const Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Align(alignment: Alignment.centerLeft, child: Text(title, style: Theme.of(context).textTheme.titleSmall)), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: children), const SizedBox(height: 12)]);
  }

  Widget _field(String label, String value, ValueChanged<String> onChanged) {
    return SizedBox(width: 200, child: TextFormField(key: ValueKey('${widget.device.id}_$label'), initialValue: value, decoration: InputDecoration(labelText: label), onChanged: onChanged));
  }

  void _update(CarParkingDeviceProfile value) {
    setState(() => _draft = value);
    widget.controller.updateDevice(value);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    if (widget.controller.devices.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least one device profile is required.')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete device?'),
            content: Text('Delete "${_draft.label}"? Signal rows using this device will be reassigned.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))],
          ),
    );
    if (confirmed == true) {
      widget.controller.deleteDevice(_draft.id);
    }
  }
}
