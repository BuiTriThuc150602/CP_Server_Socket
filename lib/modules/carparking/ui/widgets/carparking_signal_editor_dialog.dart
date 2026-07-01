import 'package:flutter/material.dart';
import 'package:socket_server/modules/carparking/models/carparking_models.dart';
import 'package:socket_server/modules/carparking/services/carparking_controller.dart';
import 'package:socket_server/modules/carparking/services/carparking_payload_factory.dart';

Future<void> showCarParkingSignalEditor(BuildContext context, CarParkingController controller, CarParkingSignalRow row, {bool quickSend = false}) {
  return showDialog<void>(context: context, builder: (context) => _SignalEditorDialog(controller: controller, row: row, quickSend: quickSend));
}

class _SignalEditorDialog extends StatefulWidget {
  const _SignalEditorDialog({required this.controller, required this.row, required this.quickSend});

  final CarParkingController controller;
  final CarParkingSignalRow row;
  final bool quickSend;

  @override
  State<_SignalEditorDialog> createState() => _SignalEditorDialogState();
}

class _SignalEditorDialogState extends State<_SignalEditorDialog> {
  late CarParkingSignalRow _row;
  late final TextEditingController _label;
  late final TextEditingController _cardId;
  late final TextEditingController _readerIndex;
  late final TextEditingController _readerName;
  late final TextEditingController _inputName;
  late final TextEditingController _delay;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _row = widget.row;
    _label = TextEditingController(text: _row.label);
    _cardId = TextEditingController(text: _row.cardId);
    _readerIndex = TextEditingController(text: _row.readerIndex.toString());
    _readerName = TextEditingController(text: _row.readerName);
    _inputName = TextEditingController(text: _row.inputName);
    _delay = TextEditingController(text: _row.delayMs.toString());
    _note = TextEditingController(text: _row.note);
  }

  @override
  void dispose() {
    _label.dispose();
    _cardId.dispose();
    _readerIndex.dispose();
    _readerName.dispose();
    _inputName.dispose();
    _delay.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.quickSend ? 'Quick Send' : 'Edit Signal'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(width: 220, child: TextField(controller: _label, decoration: const InputDecoration(labelText: 'Label'))),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: _row.deviceProfileId,
                      decoration: const InputDecoration(labelText: 'Device'),
                      items: [for (final device in widget.controller.devices) DropdownMenuItem(value: device.id, child: Text(device.label))],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _row = _row.copyWith(deviceProfileId: value));
                        }
                      },
                    ),
                  ),
                  if (_row.type == CarParkingSignalType.card) ...[
                    SizedBox(width: 220, child: TextField(controller: _cardId, autofocus: widget.quickSend, decoration: const InputDecoration(labelText: 'Card ID'), onSubmitted: widget.quickSend ? (_) => _sendAndClose() : null)),
                    SizedBox(width: 120, child: TextField(controller: _readerIndex, decoration: const InputDecoration(labelText: 'Reader'))),
                    SizedBox(width: 220, child: TextField(controller: _readerName, decoration: const InputDecoration(labelText: 'Reader name'))),
                  ] else ...[
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<int>(
                        initialValue: _row.inputIndex.clamp(1, 8),
                        decoration: const InputDecoration(labelText: 'Input'),
                        items: [for (var i = 0; i < CarParkingConstants.inputNames.length; i++) DropdownMenuItem(value: i + 1, child: Text(CarParkingConstants.inputNames[i]))],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _row = _row.copyWith(inputIndex: value, inputName: CarParkingConstants.inputNames[value - 1]);
                              _inputName.text = _row.inputName;
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 220, child: TextField(controller: _inputName, decoration: const InputDecoration(labelText: 'Input name'))),
                  ],
                  SizedBox(width: 120, child: TextField(controller: _delay, decoration: const InputDecoration(labelText: 'Delay ms'))),
                  SizedBox(width: 460, child: TextField(controller: _note, decoration: const InputDecoration(labelText: 'Note'))),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), OutlinedButton(onPressed: _save, child: const Text('Save')), FilledButton.icon(onPressed: _sendAndClose, icon: const Icon(Icons.send), label: const Text('Send & close'))],
    );
  }

  CarParkingSignalRow _buildRow() {
    return _row.copyWith(
      label: _label.text.trim().isEmpty ? _row.label : _label.text.trim(),
      cardId: _cardId.text,
      readerIndex: int.tryParse(_readerIndex.text) ?? _row.readerIndex,
      readerName: _readerName.text,
      inputName: _inputName.text,
      delayMs: int.tryParse(_delay.text) ?? _row.delayMs,
      note: _note.text,
    );
  }

  void _save() {
    widget.controller.updateRow(_buildRow());
    Navigator.pop(context);
  }

  Future<void> _sendAndClose() async {
    final updated = _buildRow();
    widget.controller.updateRow(updated);
    await widget.controller.sendRow(updated);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
