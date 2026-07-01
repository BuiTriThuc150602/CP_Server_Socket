import 'package:flutter/material.dart';
import 'package:socket_server/modules/carparking/models/carparking_models.dart';
import 'package:socket_server/modules/carparking/services/carparking_controller.dart';
import 'package:socket_server/modules/carparking/ui/widgets/carparking_signal_card.dart';

enum SignalDensity { compact, comfortable, advanced }

class CarParkingSignalList extends StatefulWidget {
  const CarParkingSignalList({super.key, required this.controller, required this.selectedRows, required this.onSelectionChanged});

  final CarParkingController controller;
  final Set<String> selectedRows;
  final VoidCallback onSelectionChanged;

  @override
  State<CarParkingSignalList> createState() => _CarParkingSignalListState();
}

class _CarParkingSignalListState extends State<CarParkingSignalList> {
  final _search = TextEditingController();
  CarParkingSignalType? _type;
  bool _enabledOnly = false;
  bool _selectedOnly = false;
  SignalDensity _density = SignalDensity.compact;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CarParkingSignalRow> get _filteredRows => widget.controller.rows.where(_matches).toList();

  bool get _allSelected {
    final rows = _filteredRows;
    if (rows.isEmpty) return false;
    return rows.every((row) => widget.selectedRows.contains(row.id));
  }

  bool get _someSelected {
    final rows = _filteredRows;
    return rows.any((row) => widget.selectedRows.contains(row.id));
  }

  void _toggleSelectAll() {
    final rows = _filteredRows;
    setState(() {
      if (_allSelected) {
        for (final row in rows) {
          widget.selectedRows.remove(row.id);
        }
      } else {
        for (final row in rows) {
          widget.selectedRows.add(row.id);
        }
      }
    });
    widget.onSelectionChanged();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredRows;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              // Select All checkbox
              Tooltip(message: _allSelected ? 'Deselect all' : 'Select all', child: Checkbox(tristate: true, value: _allSelected ? true : (_someSelected ? null : false), onChanged: (_) => _toggleSelectAll())),
              // Search field – takes remaining space
              Expanded(child: TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Search rows…', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)), onChanged: (_) => setState(() {}))),
              const SizedBox(width: 8),
              // Filter & View popup
              PopupMenuButton<String>(
                tooltip: 'Filter & Display Options',
                child: Chip(avatar: Icon(Icons.tune, size: 16, color: (_enabledOnly || _selectedOnly || _type != null) ? Theme.of(context).colorScheme.primary : null), label: const Text('Filter'), visualDensity: VisualDensity.compact),
                itemBuilder:
                    (context) => [
                      PopupMenuItem(enabled: false, child: Text('SIGNAL TYPE', style: Theme.of(context).textTheme.labelSmall)),
                      CheckedPopupMenuItem(checked: _type == null, value: 'type_all', child: const Text('All Types')),
                      CheckedPopupMenuItem(checked: _type == CarParkingSignalType.card, value: 'type_card', child: const Text('Card Only')),
                      CheckedPopupMenuItem(checked: _type == CarParkingSignalType.io, value: 'type_io', child: const Text('IO Only')),
                      const PopupMenuDivider(),
                      PopupMenuItem(enabled: false, child: Text('FILTERS', style: Theme.of(context).textTheme.labelSmall)),
                      CheckedPopupMenuItem(checked: _enabledOnly, value: 'filter_enabled', child: const Text('Enabled Only')),
                      CheckedPopupMenuItem(checked: _selectedOnly, value: 'filter_selected', child: const Text('Selected Only')),
                      const PopupMenuDivider(),
                      PopupMenuItem(enabled: false, child: Text('DISPLAY DENSITY', style: Theme.of(context).textTheme.labelSmall)),
                      CheckedPopupMenuItem(checked: _density == SignalDensity.compact, value: 'density_compact', child: const Text('Compact')),
                      CheckedPopupMenuItem(checked: _density == SignalDensity.comfortable, value: 'density_comfortable', child: const Text('Comfortable')),
                      CheckedPopupMenuItem(checked: _density == SignalDensity.advanced, value: 'density_advanced', child: const Text('Advanced')),
                    ],
                onSelected: (value) {
                  setState(() {
                    switch (value) {
                      case 'type_all':
                        _type = null;
                      case 'type_card':
                        _type = CarParkingSignalType.card;
                      case 'type_io':
                        _type = CarParkingSignalType.io;
                      case 'filter_enabled':
                        _enabledOnly = !_enabledOnly;
                      case 'filter_selected':
                        _selectedOnly = !_selectedOnly;
                      case 'density_compact':
                        _density = SignalDensity.compact;
                      case 'density_comfortable':
                        _density = SignalDensity.comfortable;
                      case 'density_advanced':
                        _density = SignalDensity.advanced;
                    }
                  });
                },
              ),
              const SizedBox(width: 4),
              // Add buttons
              FilledButton.icon(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, textStyle: const TextStyle(fontSize: 12)),
                onPressed: widget.controller.autoTestRunning ? null : widget.controller.addCardRow,
                icon: const Icon(Icons.credit_card, size: 14),
                label: const Text('Card'),
              ),
              const SizedBox(width: 4),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, textStyle: const TextStyle(fontSize: 12)),
                onPressed: widget.controller.autoTestRunning ? null : widget.controller.addIoRow,
                icon: const Icon(Icons.input, size: 14),
                label: const Text('IO'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1280 ? 2 : 1;
              if (rows.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('No signal rows', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisExtent: _density == SignalDensity.compact ? 100 : 132, crossAxisSpacing: 6, mainAxisSpacing: 6),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return CarParkingSignalCard(
                    key: ValueKey(row.id),
                    row: row,
                    controller: widget.controller,
                    density: _density,
                    selected: widget.selectedRows.contains(row.id),
                    current: widget.controller.runnerSnapshot.currentRowId == row.id,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          widget.selectedRows.add(row.id);
                        } else {
                          widget.selectedRows.remove(row.id);
                        }
                      });
                      widget.onSelectionChanged();
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  bool _matches(CarParkingSignalRow row) {
    if (_type != null && row.type != _type) return false;
    if (_enabledOnly && !row.enabled) return false;
    if (_selectedOnly && !widget.selectedRows.contains(row.id)) return false;
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    final device = widget.controller.devices.where((item) => item.id == row.deviceProfileId).map((item) => item.label).join(' ');
    return [row.label, row.cardId, row.inputName, row.note, device].join(' ').toLowerCase().contains(query);
  }
}
