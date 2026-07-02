import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_server/modules/carparking/models/carparking_models.dart';
import 'package:socket_server/modules/carparking/services/carparking_controller.dart';
import 'package:socket_server/modules/carparking/ui/widgets/carparking_signal_editor_dialog.dart';
import 'package:socket_server/modules/carparking/ui/widgets/carparking_signal_list.dart';

class CarParkingSignalCard extends StatelessWidget {
  const CarParkingSignalCard({
    super.key,
    required this.row,
    required this.controller,
    required this.density,
    required this.selected,
    required this.current,
    required this.onSelected,
  });

  final CarParkingSignalRow row;
  final CarParkingController controller;
  final SignalDensity density;
  final bool selected;
  final bool current;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final device = controller.devices.firstWhere(
      (item) => item.id == row.deviceProfileId,
      orElse: () => controller.devices.first,
    );
    final isCard = row.type == CarParkingSignalType.card;
    final primary =
        isCard ? row.cardId : '${row.inputName}  #${row.inputIndex}';
    final secondary = 'Input ${row.inputIndex}';
    final scheme = Theme.of(context).colorScheme;
    final accent = isCard ? Colors.indigo : Colors.teal;
    final surface =
        current
            ? scheme.primaryContainer.withValues(alpha: 0.72)
            : (!row.enabled
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.48)
                : null);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: surface,
      child: Row(
        children: [
          Container(width: 5, color: current ? scheme.primary : accent),
          SizedBox(
            width: 42,
            child: Checkbox(
              value: selected,
              onChanged: (value) => onSelected(value ?? false),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => showCarParkingSignalEditor(context, controller, row),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 8, 8, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compactWidth = constraints.maxWidth < 360;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            _TypeBadge(
                              label: isCard ? 'CARD' : 'IO',
                              icon: isCard ? Icons.credit_card : Icons.input,
                              color: accent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                row.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (!compactWidth) _StatusDot(enabled: row.enabled),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap:
                                    () => showCarParkingSignalEditor(
                                      context,
                                      controller,
                                      row,
                                      quickSend: true,
                                    ),
                                child: Text(
                                  primary.isEmpty
                                      ? 'Tap to set value'
                                      : primary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color:
                                        primary.isEmpty
                                            ? scheme.onSurfaceVariant
                                            : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isCard)
                              _ReaderQuickStepper(
                                readerIndex: row.readerIndex,
                                onChanged: (readerIndex) {
                                  controller.updateRow(
                                    row.copyWith(
                                      readerIndex: readerIndex,
                                      readerName: _nextReaderName(readerIndex),
                                    ),
                                  );
                                },
                              )
                            else
                              _MetaPill(text: secondary),
                          ],
                        ),
                        if (density != SignalDensity.compact) ...[
                          const SizedBox(height: 6),
                          Text(
                            _details(device),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          _ActionRail(
            enabled: row.enabled,
            autoRunning: controller.autoTestRunning,
            onToggleEnabled:
                () => controller.updateRow(row.copyWith(enabled: !row.enabled)),
            onSend: () => controller.sendRow(row),
            onMenuSelected: (value) => _handleMenu(context, value),
          ),
        ],
      ),
    );
  }

  String _details(CarParkingDeviceProfile device) {
    final parts = [
      device.label,
      '${row.delayMs}ms',
      if (density == SignalDensity.advanced && row.note.isNotEmpty) row.note,
    ];
    return parts.join('  |  ');
  }

  String _nextReaderName(int readerIndex) {
    final current = row.readerName.trim();
    final defaultCurrent = 'Reader ${row.readerIndex}';
    if (current.isEmpty || current == defaultCurrent) {
      return 'Reader $readerIndex';
    }
    return row.readerName;
  }

  Future<void> _handleMenu(BuildContext context, String value) async {
    switch (value) {
      case 'edit':
        showCarParkingSignalEditor(context, controller, row);
      case 'duplicate':
        controller.duplicateRow(row);
      case 'toggle':
        controller.updateRow(row.copyWith(enabled: !row.enabled));
      case 'delete':
        controller.deleteRow(row.id);
      case 'copy':
        await Clipboard.setData(
          ClipboardData(text: controller.previewPayloadForRow(row)),
        );
      case 'preview':
        if (context.mounted) {
          _preview(context);
        }
    }
  }

  void _preview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Payload: ${row.label}'),
            content: SizedBox(
              width: 640,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  controller.previewPayloadForRow(row),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}

class _ReaderQuickStepper extends StatelessWidget {
  const _ReaderQuickStepper({
    required this.readerIndex,
    required this.onChanged,
  });

  final int readerIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 28,
      constraints: const BoxConstraints(maxWidth: 128),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ReaderStepButton(
            tooltip: 'Previous reader',
            icon: Icons.remove,
            enabled: readerIndex > 1,
            onPressed: () => onChanged(readerIndex - 1),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 54),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            child: Text(
              'R$readerIndex',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          _ReaderStepButton(
            tooltip: 'Next reader',
            icon: Icons.add,
            enabled: readerIndex < 99,
            onPressed: () => onChanged(readerIndex + 1),
          ),
        ],
      ),
    );
  }
}

class _ReaderStepButton extends StatelessWidget {
  const _ReaderStepButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
        padding: EdgeInsets.zero,
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 14),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 24,
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.green : Colors.grey;
    return Tooltip(
      message: enabled ? 'Enabled' : 'Disabled',
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _ActionRail extends StatelessWidget {
  const _ActionRail({
    required this.enabled,
    required this.autoRunning,
    required this.onToggleEnabled,
    required this.onSend,
    required this.onMenuSelected,
  });

  final bool enabled;
  final bool autoRunning;
  final VoidCallback onToggleEnabled;
  final VoidCallback onSend;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: enabled ? 'Disable row' : 'Enable row',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 36, height: 28),
            onPressed: onToggleEnabled,
            icon: Icon(
              enabled ? Icons.visibility : Icons.visibility_off,
              size: 18,
            ),
          ),
          IconButton.filledTonal(
            tooltip:
                'Send manually (disabled rows are skipped only by Auto Test)',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 36, height: 30),
            onPressed: autoRunning ? null : onSend,
            icon: const Icon(Icons.send, size: 18),
          ),
          SizedBox(
            width: 36,
            height: 28,
            child: PopupMenuButton<String>(
              tooltip: 'More actions',
              padding: EdgeInsets.zero,
              onSelected: onMenuSelected,
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Text('Duplicate'),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(enabled ? 'Disable' : 'Enable'),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Text('Copy generated payload'),
                    ),
                    const PopupMenuItem(
                      value: 'preview',
                      child: Text('Preview JSON'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
              icon: const Icon(Icons.more_vert, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
