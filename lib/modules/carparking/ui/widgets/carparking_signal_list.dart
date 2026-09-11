import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluxlab/modules/carparking/models/carparking_models.dart';
import 'package:fluxlab/modules/carparking/services/carparking_controller.dart';
import 'package:fluxlab/modules/carparking/ui/widgets/carparking_signal_card.dart';

enum SignalDensity { compact, comfortable, advanced }

class CarParkingSignalList extends StatefulWidget {
  const CarParkingSignalList({
    super.key,
    required this.controller,
    required this.selectedRows,
    required this.onSelectionChanged,
  });

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

  List<CarParkingSignalRow> get _filteredRows =>
      widget.controller.rows.where(_matches).toList();

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
    final selectedRows =
        rows.where((row) => widget.selectedRows.contains(row.id)).toList();
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyA, control: true): () {
          if (_canHandleShortcut()) _selectAllVisible();
        },
        const SingleActivator(LogicalKeyboardKey.delete): () {
          if (_canHandleShortcut()) _deleteSelected();
        },
        const SingleActivator(LogicalKeyboardKey.keyD, control: true): () {
          if (_canHandleShortcut()) _duplicateSelected();
        },
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (_canHandleShortcut() && selectedRows.length == 1) {
            _sendSelectedOnce(selectedRows);
          }
        },
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                InkWell(
                  onTap: _toggleSelectAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message:
                            _allSelected
                                ? 'Deselect visible rows'
                                : 'Select all visible rows',
                        child: Checkbox(
                          tristate: true,
                          value:
                              _allSelected
                                  ? true
                                  : (_someSelected ? null : false),
                          onChanged: (_) => _toggleSelectAll(),
                        ),
                      ),
                      const Text('Select all visible'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Search field – takes remaining space
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, size: 18),
                      hintText: 'Search rows…',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                _rowsMenu(),
                const SizedBox(width: 8),
                // Filter & View popup
                PopupMenuButton<String>(
                  tooltip: 'Filter & Display Options',
                  child: Chip(
                    avatar: Icon(
                      Icons.tune,
                      size: 16,
                      color:
                          (_enabledOnly || _selectedOnly || _type != null)
                              ? Theme.of(context).colorScheme.primary
                              : null,
                    ),
                    label: const Text('Filter'),
                    visualDensity: VisualDensity.compact,
                  ),
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          enabled: false,
                          child: Text(
                            'SIGNAL TYPE',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        CheckedPopupMenuItem(
                          checked: _type == null,
                          value: 'type_all',
                          child: const Text('All Types'),
                        ),
                        CheckedPopupMenuItem(
                          checked: _type == CarParkingSignalType.card,
                          value: 'type_card',
                          child: const Text('Card Only'),
                        ),
                        CheckedPopupMenuItem(
                          checked: _type == CarParkingSignalType.io,
                          value: 'type_io',
                          child: const Text('IO Only'),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          enabled: false,
                          child: Text(
                            'FILTERS',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        CheckedPopupMenuItem(
                          checked: _enabledOnly,
                          value: 'filter_enabled',
                          child: const Text('Enabled Only'),
                        ),
                        CheckedPopupMenuItem(
                          checked: _selectedOnly,
                          value: 'filter_selected',
                          child: const Text('Selected Only'),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          enabled: false,
                          child: Text(
                            'DISPLAY DENSITY',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        CheckedPopupMenuItem(
                          checked: _density == SignalDensity.compact,
                          value: 'density_compact',
                          child: const Text('Compact'),
                        ),
                        CheckedPopupMenuItem(
                          checked: _density == SignalDensity.comfortable,
                          value: 'density_comfortable',
                          child: const Text('Comfortable'),
                        ),
                        CheckedPopupMenuItem(
                          checked: _density == SignalDensity.advanced,
                          value: 'density_advanced',
                          child: const Text('Advanced'),
                        ),
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
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 16,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed:
                      widget.controller.autoTestRunning
                          ? null
                          : widget.controller.addCardRow,
                  icon: const Icon(Icons.credit_card, size: 14),
                  label: const Text('Card'),
                ),
                const SizedBox(width: 4),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 16,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed:
                      widget.controller.autoTestRunning
                          ? null
                          : widget.controller.addIoRow,
                  icon: const Icon(Icons.input, size: 14),
                  label: const Text('IO'),
                ),
              ],
            ),
          ),
          if (widget.selectedRows.isNotEmpty) _bulkActionBar(selectedRows),
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
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No signal rows',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent:
                        _density == SignalDensity.compact ? 100 : 132,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return CarParkingSignalCard(
                      key: ValueKey(row.id),
                      row: row,
                      controller: widget.controller,
                      density: _density,
                      selected: widget.selectedRows.contains(row.id),
                      current:
                          widget.controller.runnerSnapshot.currentRowId ==
                          row.id,
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
      ),
    );
  }

  Widget _bulkActionBar(List<CarParkingSignalRow> selectedRows) {
    final count = widget.selectedRows.length;
    final running = widget.controller.autoTestRunning;
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.secondaryContainer.withValues(alpha: 0.42),
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(
              Icons.checklist_rtl,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '$count selected',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed:
                  selectedRows.isEmpty
                      ? null
                      : () => _sendSelectedOnce(selectedRows),
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Send'),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed:
                  selectedRows.isEmpty || running
                      ? null
                      : () => _runSelected(selectedRows),
              icon: const Icon(Icons.playlist_play, size: 16),
              label: const Text('Run'),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed:
                  () => widget.controller.setRowsEnabled(
                    widget.selectedRows,
                    true,
                  ),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('Enable'),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed:
                  () => widget.controller.setRowsEnabled(
                    widget.selectedRows,
                    false,
                  ),
              icon: const Icon(Icons.visibility_off, size: 16),
              label: const Text('Disable'),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: running ? null : _duplicateSelected,
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Duplicate'),
            ),
            const SizedBox(width: 6),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: running ? null : _deleteSelected,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Delete'),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: _clearSelection,
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowsMenu() {
    final hasSelection = widget.selectedRows.isNotEmpty;
    return PopupMenuButton<String>(
      tooltip: 'Rows',
      child: const Chip(
        avatar: Icon(Icons.table_rows, size: 16),
        label: Text('Rows'),
        visualDensity: VisualDensity.compact,
      ),
      onSelected: (value) async {
        switch (value) {
          case 'import':
            await _showImportDialog();
          case 'export_all':
            await Clipboard.setData(
              ClipboardData(text: widget.controller.exportRowsJson()),
            );
          case 'export_selected':
            await Clipboard.setData(
              ClipboardData(
                text: widget.controller.exportSelectedRowsJson(
                  widget.selectedRows,
                ),
              ),
            );
        }
      },
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: 'import',
              child: Text('Import rows JSON'),
            ),
            const PopupMenuItem(
              value: 'export_all',
              child: Text('Export all rows JSON'),
            ),
            PopupMenuItem(
              enabled: hasSelection,
              value: 'export_selected',
              child: const Text('Export selected rows JSON'),
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
    final device = widget.controller.devices
        .where((item) => item.id == row.deviceProfileId)
        .map((item) => item.label)
        .join(' ');
    return [
      row.label,
      row.cardId,
      row.inputName,
      row.note,
      device,
    ].join(' ').toLowerCase().contains(query);
  }

  void _clearSelection() {
    setState(widget.selectedRows.clear);
    widget.onSelectionChanged();
  }

  void _selectAllVisible() {
    setState(() {
      for (final row in _filteredRows) {
        widget.selectedRows.add(row.id);
      }
    });
    widget.onSelectionChanged();
  }

  bool _canHandleShortcut() {
    final focus = FocusManager.instance.primaryFocus;
    final context = focus?.context;
    if (context == null) return true;
    return context.findAncestorWidgetOfExactType<EditableText>() == null;
  }

  void _duplicateSelected() {
    if (widget.selectedRows.isEmpty || widget.controller.autoTestRunning) {
      return;
    }
    widget.controller.duplicateRows(widget.selectedRows);
  }

  void _runSelected(List<CarParkingSignalRow> selectedRows) {
    if (selectedRows.isEmpty || widget.controller.autoTestRunning) {
      return;
    }
    widget.controller.startScenario(
      selectedRowIds: selectedRows.map((row) => row.id).toList(),
    );
  }

  Future<void> _sendSelectedOnce(List<CarParkingSignalRow> selectedRows) async {
    final enabledRows = selectedRows.where((row) => row.enabled).toList();
    if (enabledRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No enabled selected rows to send.')),
      );
      return;
    }
    for (final row in enabledRows) {
      await widget.controller.sendRow(row);
    }
  }

  Future<void> _deleteSelected() async {
    final count = widget.selectedRows.length;
    if (count == 0) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete selected rows?'),
            content: Text(
              'Delete $count selected row${count == 1 ? '' : 's'}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      widget.controller.deleteRows(widget.selectedRows);
      _clearSelection();
    }
  }

  Future<void> _showImportDialog() async {
    final controller = TextEditingController();
    String? errorText;
    final imported = await showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Import rows JSON'),
                  content: SizedBox(
                    width: 640,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: controller,
                          minLines: 8,
                          maxLines: 14,
                          style: const TextStyle(fontFamily: 'monospace'),
                          decoration: InputDecoration(
                            hintText: '[{ "label": "Card 1", ... }]',
                            errorText: errorText,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        try {
                          widget.controller.importRowsJson(controller.text);
                          Navigator.pop(context, true);
                        } catch (error) {
                          setDialogState(() => errorText = error.toString());
                        }
                      },
                      child: const Text('Import'),
                    ),
                  ],
                ),
          ),
    );
    controller.dispose();
    if (imported == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rows imported.')));
    }
  }
}
