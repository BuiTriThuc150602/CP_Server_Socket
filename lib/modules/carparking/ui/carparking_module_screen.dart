import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:socket_server/core/socket/tcp_server_engine.dart';
import 'package:socket_server/core/ui/status_badge.dart';
import 'package:socket_server/modules/carparking/models/carparking_models.dart';
import 'package:socket_server/modules/carparking/services/carparking_controller.dart';
import 'package:socket_server/modules/carparking/services/carparking_payload_factory.dart';
import 'package:socket_server/modules/carparking/services/carparking_scenario_runner.dart';

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
        _StatusBar(controller: controller),
        if (controller.warning != null) _WarningBanner(message: controller.warning!, color: Colors.amber),
        if (controller.serverError != null) _WarningBanner(message: controller.serverError!, color: Colors.red),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 340, child: _DevicePanel(controller: controller)),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    _ScenarioBar(controller: controller, selectedRows: _selectedRows),
                    const Divider(height: 1),
                    Expanded(child: _SignalTable(controller: controller, selectedRows: _selectedRows, onSelectionChanged: () => setState(() {}))),
                    SizedBox(height: 260, child: _MessageConsole(controller: controller)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatefulWidget {
  const _StatusBar({required this.controller});

  final CarParkingController controller;

  @override
  State<_StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<_StatusBar> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: widget.controller.server.bindHost);
    _portController = TextEditingController(text: widget.controller.server.port.toString());
  }

  @override
  void didUpdateWidget(covariant _StatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final server = widget.controller.server;
    if (_hostController.text != server.bindHost) {
      _hostController.text = server.bindHost;
    }
    if (_portController.text != server.port.toString()) {
      _portController.text = server.port.toString();
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final running = controller.serverState == TcpServerState.running;
    final busy = controller.serverState == TcpServerState.starting || controller.serverState == TcpServerState.stopping;
    final statusColor = running ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          StatusBadge(label: running ? 'Running' : controller.serverState.name, color: statusColor, icon: running ? Icons.check_circle : Icons.stop_circle),
          const SizedBox(width: 12),
          SizedBox(width: 180, child: TextField(controller: _hostController, decoration: const InputDecoration(labelText: 'Bind host', isDense: true, border: OutlineInputBorder()), onChanged: (value) => controller.updateServer(controller.server.copyWith(bindHost: value.trim())))),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Port', isDense: true, border: OutlineInputBorder()),
              onChanged: (value) {
                final port = int.tryParse(value);
                if (port != null && port > 0 && port <= 65535) {
                  controller.updateServer(controller.server.copyWith(port: port));
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed:
                busy
                    ? null
                    : running
                    ? controller.stopServer
                    : controller.startServer,
            icon: Icon(running ? Icons.stop : Icons.play_arrow),
            label: Text(running ? 'Stop' : 'Start'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(onPressed: busy ? null : () => controller.applyServerAndRestart(controller.server), icon: const Icon(Icons.restart_alt), label: const Text('Restart')),
          const Spacer(),
          StatusBadge(label: 'Clients ${controller.clients.length}', color: Colors.blue, icon: Icons.people),
          const SizedBox(width: 8),
          StatusBadge(label: controller.server.heartbeatEnabled ? 'Heartbeat ${controller.server.heartbeatIntervalSeconds}s' : 'Heartbeat off', color: controller.server.heartbeatEnabled ? Colors.teal : Colors.grey, icon: Icons.monitor_heart_outlined),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message, required this.color});

  final String message;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [Icon(Icons.warning_amber_rounded, color: color.shade800), const SizedBox(width: 8), Expanded(child: Text(message, style: TextStyle(color: color.shade900, fontWeight: FontWeight.w600)))]),
    );
  }
}

class _DevicePanel extends StatelessWidget {
  const _DevicePanel({required this.controller});

  final CarParkingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [Expanded(child: Text('Device Profiles', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))), IconButton(tooltip: 'Add device', onPressed: controller.addDevice, icon: const Icon(Icons.add))]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: controller.devices.length,
            itemBuilder: (context, index) {
              final device = controller.devices[index];
              return _DeviceEditor(
                key: ValueKey(device.id),
                device: device,
                isDefault: device.id == controller.workspace.defaultDeviceProfileId,
                onChanged: controller.updateDevice,
                onDefault: () => controller.setDefaultDevice(device.id),
                onDuplicate: () => controller.duplicateDevice(device),
                onDelete: () => controller.deleteDevice(device.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DeviceEditor extends StatelessWidget {
  const _DeviceEditor({super.key, required this.device, required this.isDefault, required this.onChanged, required this.onDefault, required this.onDuplicate, required this.onDelete});

  final CarParkingDeviceProfile device;
  final bool isDefault;
  final ValueChanged<CarParkingDeviceProfile> onChanged;
  final VoidCallback onDefault;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: TextFormField(key: ValueKey('${device.id}_label'), initialValue: device.label, decoration: const InputDecoration(labelText: 'Label', isDense: true), onChanged: (value) => onChanged(device.copyWith(label: value)))),
                IconButton(tooltip: 'Default device', onPressed: onDefault, icon: Icon(isDefault ? Icons.star : Icons.star_border, color: isDefault ? Colors.amber.shade700 : null)),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'duplicate') {
                      onDuplicate();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [PopupMenuItem(value: 'duplicate', child: Text('Duplicate')), PopupMenuItem(value: 'delete', child: Text('Delete'))],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _TwoFields(first: _FieldSpec(label: 'Device ID', value: device.deviceId, onChanged: (value) => onChanged(device.copyWith(deviceId: value))), second: _FieldSpec(label: 'Device name', value: device.deviceName, onChanged: (value) => onChanged(device.copyWith(deviceName: value)))),
            _TwoFields(first: _FieldSpec(label: 'Device IP', value: device.deviceIp, onChanged: (value) => onChanged(device.copyWith(deviceIp: value))), second: _FieldSpec(label: 'Device port', value: device.devicePort, onChanged: (value) => onChanged(device.copyWith(devicePort: value)))),
            _TwoFields(first: _FieldSpec(label: 'Manufacturer', value: device.manufacturer, onChanged: (value) => onChanged(device.copyWith(manufacturer: value))), second: _FieldSpec(label: 'Model', value: device.modelName, onChanged: (value) => onChanged(device.copyWith(modelName: value)))),
            Row(children: [Checkbox(value: device.enabled, onChanged: (value) => onChanged(device.copyWith(enabled: value ?? true))), const Text('Enabled'), const Spacer(), Text(device.protocolType)]),
          ],
        ),
      ),
    );
  }
}

class _FieldSpec {
  const _FieldSpec({required this.label, required this.value, required this.onChanged});

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
}

class _TwoFields extends StatelessWidget {
  const _TwoFields({required this.first, required this.second});

  final _FieldSpec first;
  final _FieldSpec second;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Expanded(child: _SmallField(spec: first)), const SizedBox(width: 8), Expanded(child: _SmallField(spec: second))]));
  }
}

class _SmallField extends StatelessWidget {
  const _SmallField({required this.spec});

  final _FieldSpec spec;

  @override
  Widget build(BuildContext context) {
    return TextFormField(key: ValueKey('${spec.label}_${spec.value}'), initialValue: spec.value, decoration: InputDecoration(labelText: spec.label, isDense: true), onChanged: spec.onChanged);
  }
}

class _ScenarioBar extends StatefulWidget {
  const _ScenarioBar({required this.controller, required this.selectedRows});

  final CarParkingController controller;
  final Set<String> selectedRows;

  @override
  State<_ScenarioBar> createState() => _ScenarioBarState();
}

class _ScenarioBarState extends State<_ScenarioBar> {
  late final TextEditingController _loopController;
  late final TextEditingController _delayController;

  @override
  void initState() {
    super.initState();
    final scenario = _scenario;
    _loopController = TextEditingController(text: scenario.loopCount.toString());
    _delayController = TextEditingController(text: scenario.defaultDelayMs.toString());
  }

  CarParkingScenario get _scenario {
    final scenarios = widget.controller.workspace.scenarios;
    return scenarios.isEmpty ? CarParkingScenario.defaults() : scenarios.first;
  }

  @override
  void dispose() {
    _loopController.dispose();
    _delayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final snapshot = controller.runnerSnapshot;
    final scenario = _scenario;
    final running = snapshot.status == ScenarioRunnerStatus.running;
    final paused = snapshot.status == ScenarioRunnerStatus.paused;

    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          SegmentedButton<CarParkingScenarioMode>(
            segments: const [ButtonSegment(value: CarParkingScenarioMode.sequential, label: Text('Sequential'), icon: Icon(Icons.format_list_numbered)), ButtonSegment(value: CarParkingScenarioMode.random, label: Text('Random'), icon: Icon(Icons.shuffle))],
            selected: {scenario.mode},
            onSelectionChanged: controller.autoTestRunning ? null : (value) => controller.updateScenario(scenario.copyWith(mode: value.first)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: TextField(
              controller: _loopController,
              enabled: !controller.autoTestRunning,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Loops', helperText: '0 = inf', isDense: true, border: OutlineInputBorder()),
              onChanged: (value) => controller.updateScenario(scenario.copyWith(loopCount: int.tryParse(value) ?? 1)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 118,
            child: TextField(
              controller: _delayController,
              enabled: !controller.autoTestRunning,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Default ms', isDense: true, border: OutlineInputBorder()),
              onChanged: (value) => controller.updateScenario(scenario.copyWith(defaultDelayMs: int.tryParse(value) ?? 1000)),
            ),
          ),
          const SizedBox(width: 8),
          Checkbox(value: scenario.stopOnError, onChanged: controller.autoTestRunning ? null : (value) => controller.updateScenario(scenario.copyWith(stopOnError: value ?? false))),
          const Text('Stop on error'),
          const Spacer(),
          Text('Step ${snapshot.totalSteps == 0 ? 0 : snapshot.currentStepIndex + 1}/${snapshot.totalSteps}  Loop ${snapshot.completedLoops}'),
          const SizedBox(width: 12),
          FilledButton.icon(onPressed: running ? controller.stopScenario : () => controller.startScenario(selectedRowIds: widget.selectedRows.toList()), icon: Icon(running ? Icons.stop : Icons.play_arrow), label: Text(running ? 'Stop Auto' : 'Start Auto')),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: paused ? 'Resume' : 'Pause',
            onPressed:
                running
                    ? controller.pauseScenario
                    : paused
                    ? controller.resumeScenario
                    : null,
            icon: Icon(paused ? Icons.play_arrow : Icons.pause),
          ),
        ],
      ),
    );
  }
}

class _SignalTable extends StatelessWidget {
  const _SignalTable({required this.controller, required this.selectedRows, required this.onSelectionChanged});

  final CarParkingController controller;
  final Set<String> selectedRows;
  final VoidCallback onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              FilledButton.icon(onPressed: controller.autoTestRunning ? null : controller.addCardRow, icon: const Icon(Icons.credit_card), label: const Text('Add Card')),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: controller.autoTestRunning ? null : controller.addIoRow, icon: const Icon(Icons.input), label: const Text('Add IO')),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: controller.exportRowsJson()));
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Export Rows'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: controller.autoTestRunning ? null : () => _showImportDialog(context, controller), icon: const Icon(Icons.download), label: const Text('Import Rows')),
              const Spacer(),
              Text('${selectedRows.length} selected'),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: controller.rows.length,
            itemBuilder: (context, index) {
              final row = controller.rows[index];
              return _SignalRowEditor(
                key: ValueKey(row.id),
                row: row,
                devices: controller.devices,
                selected: selectedRows.contains(row.id),
                currentStep: controller.runnerSnapshot.currentRowId == row.id,
                autoRunning: controller.autoTestRunning,
                onSelected: (selected) {
                  if (selected) {
                    selectedRows.add(row.id);
                  } else {
                    selectedRows.remove(row.id);
                  }
                  onSelectionChanged();
                },
                onChanged: controller.updateRow,
                onSend: () => controller.sendRow(row),
                onDuplicate: () => controller.duplicateRow(row),
                onDelete: () => controller.deleteRow(row.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showImportDialog(BuildContext context, CarParkingController controller) async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Import Rows JSON'),
            content: SizedBox(width: 640, child: TextField(controller: textController, minLines: 12, maxLines: 18, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '[{ "label": "Card 1", ... }]'))),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, textController.text), child: const Text('Import'))],
          ),
    );
    textController.dispose();
    if (result == null || result.trim().isEmpty) {
      return;
    }
    try {
      controller.importRowsJson(result);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $error')));
      }
    }
  }
}

class _SignalRowEditor extends StatelessWidget {
  const _SignalRowEditor({super.key, required this.row, required this.devices, required this.selected, required this.currentStep, required this.autoRunning, required this.onSelected, required this.onChanged, required this.onSend, required this.onDuplicate, required this.onDelete});

  final CarParkingSignalRow row;
  final List<CarParkingDeviceProfile> devices;
  final bool selected;
  final bool currentStep;
  final bool autoRunning;
  final ValueChanged<bool> onSelected;
  final ValueChanged<CarParkingSignalRow> onChanged;
  final VoidCallback onSend;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: currentStep ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5) : null, border: Border.all(color: currentStep ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Checkbox(value: selected, onChanged: (value) => onSelected(value ?? false)),
          Checkbox(value: row.enabled, onChanged: (value) => onChanged(row.copyWith(enabled: value ?? true))),
          SizedBox(width: 130, child: TextFormField(key: ValueKey('${row.id}_label_${row.label}'), initialValue: row.label, decoration: const InputDecoration(labelText: 'Label', isDense: true), onChanged: (value) => onChanged(row.copyWith(label: value)))),
          const SizedBox(width: 8),
          SizedBox(
            width: 106,
            child: DropdownButtonFormField<CarParkingSignalType>(
              initialValue: row.type,
              decoration: const InputDecoration(labelText: 'Type', isDense: true),
              items: const [DropdownMenuItem(value: CarParkingSignalType.card, child: Text('Card')), DropdownMenuItem(value: CarParkingSignalType.io, child: Text('IO'))],
              onChanged:
                  autoRunning
                      ? null
                      : (value) {
                        if (value != null) {
                          onChanged(row.copyWith(type: value).withDefaultsForType(value));
                        }
                      },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<String>(
              initialValue: devices.any((device) => device.id == row.deviceProfileId) ? row.deviceProfileId : devices.first.id,
              decoration: const InputDecoration(labelText: 'Device', isDense: true),
              items: [for (final device in devices) DropdownMenuItem(value: device.id, child: Text(device.label))],
              onChanged: (value) {
                if (value != null) {
                  onChanged(row.copyWith(deviceProfileId: value));
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          if (row.type == CarParkingSignalType.card) ...[
            _RowTextField(width: 150, label: 'Card ID', value: row.cardId, onChanged: (value) => onChanged(row.copyWith(cardId: value))),
            _RowNumberField(width: 92, label: 'Reader', value: row.readerIndex, onChanged: (value) => onChanged(row.copyWith(readerIndex: value, readerName: row.readerName.isEmpty ? 'Reader $value' : null))),
            _RowTextField(width: 130, label: 'Reader name', value: row.readerName, onChanged: (value) => onChanged(row.copyWith(readerName: value))),
          ] else ...[
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<int>(
                initialValue: row.inputIndex.clamp(1, 8),
                decoration: const InputDecoration(labelText: 'Input', isDense: true),
                items: [for (var i = 0; i < CarParkingConstants.inputNames.length; i++) DropdownMenuItem(value: i + 1, child: Text(CarParkingConstants.inputNames[i]))],
                onChanged: (value) {
                  if (value != null) {
                    onChanged(row.copyWith(inputIndex: value, inputName: CarParkingConstants.inputNames[value - 1]));
                  }
                },
              ),
            ),
            _RowTextField(width: 130, label: 'Input name', value: row.inputName, onChanged: (value) => onChanged(row.copyWith(inputName: value))),
          ],
          _RowNumberField(width: 96, label: 'Delay ms', value: row.delayMs, onChanged: (value) => onChanged(row.copyWith(delayMs: value))),
          _RowTextField(width: 170, label: 'Note', value: row.note, onChanged: (value) => onChanged(row.copyWith(note: value))),
          IconButton.filledTonal(tooltip: 'Send row', onPressed: autoRunning ? null : onSend, icon: const Icon(Icons.send)),
          IconButton(tooltip: 'Duplicate row', onPressed: autoRunning ? null : onDuplicate, icon: const Icon(Icons.copy)),
          IconButton(tooltip: 'Delete row', onPressed: autoRunning ? null : onDelete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
    );
  }
}

class _RowTextField extends StatelessWidget {
  const _RowTextField({required this.width, required this.label, required this.value, required this.onChanged});

  final double width;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(right: 8), child: SizedBox(width: width, child: TextFormField(key: ValueKey('${label}_$value'), initialValue: value, decoration: InputDecoration(labelText: label, isDense: true), onChanged: onChanged)));
  }
}

class _RowNumberField extends StatelessWidget {
  const _RowNumberField({required this.width, required this.label, required this.value, required this.onChanged});

  final double width;
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _RowTextField(width: width, label: label, value: value.toString(), onChanged: (text) => onChanged(int.tryParse(text) ?? value));
  }
}

class _MessageConsole extends StatelessWidget {
  const _MessageConsole({required this.controller});

  final CarParkingController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Text('Console', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                FilterChip(label: const Text('Pretty JSON'), selected: controller.prettyConsole, onSelected: controller.setPrettyConsole),
                const Spacer(),
                IconButton(tooltip: 'Clear console', onPressed: controller.clearConsole, icon: const Icon(Icons.clear_all)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: controller.console.length,
              itemBuilder: (context, index) {
                final entry = controller.console[index];
                final text = controller.prettyConsole ? entry.prettyText : entry.text;
                return ListTile(
                  dense: true,
                  leading: Icon(_iconFor(entry.kind), color: _colorFor(entry.kind)),
                  title: SelectableText(text, style: const TextStyle(fontFamily: 'monospace')),
                  subtitle: Text(
                    '${entry.timestamp.toIso8601String()}'
                    '${entry.sessionId == null ? '' : '  ${entry.sessionId}'}',
                  ),
                  trailing: IconButton(tooltip: 'Copy message', icon: const Icon(Icons.copy), onPressed: () => Clipboard.setData(ClipboardData(text: entry.text))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(ConsoleEntryKind kind) {
    return switch (kind) {
      ConsoleEntryKind.incoming => Icons.call_received,
      ConsoleEntryKind.outgoing => Icons.call_made,
      ConsoleEntryKind.error => Icons.error_outline,
      ConsoleEntryKind.info => Icons.info_outline,
    };
  }

  Color _colorFor(ConsoleEntryKind kind) {
    return switch (kind) {
      ConsoleEntryKind.incoming => Colors.indigo,
      ConsoleEntryKind.outgoing => Colors.green,
      ConsoleEntryKind.error => Colors.red,
      ConsoleEntryKind.info => Colors.blueGrey,
    };
  }
}
