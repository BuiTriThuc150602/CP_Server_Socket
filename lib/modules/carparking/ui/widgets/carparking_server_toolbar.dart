import 'package:flutter/material.dart';
import 'package:socket_server/core/socket/tcp_server_engine.dart';
import 'package:socket_server/core/ui/status_badge.dart';
import 'package:socket_server/modules/carparking/models/carparking_models.dart';
import 'package:socket_server/modules/carparking/services/carparking_controller.dart';

class CarParkingServerToolbar extends StatelessWidget {
  const CarParkingServerToolbar({super.key, required this.controller});

  final CarParkingController controller;

  @override
  Widget build(BuildContext context) {
    final running = controller.serverState == TcpServerState.running;
    final busy =
        controller.serverState == TcpServerState.starting ||
        controller.serverState == TcpServerState.stopping;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return Row(
            children: [
              StatusBadge(
                label: running ? 'Running' : controller.serverState.name,
                color: running ? Colors.green : Colors.red,
                icon: running ? Icons.check_circle : Icons.stop_circle,
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.settings_ethernet, size: 18),
                label: Text(
                  '${controller.server.bindHost}:${controller.server.port}',
                ),
                onPressed: () => _showServerDialog(context),
              ),
              const Spacer(),
              if (!isNarrow) ...[
                ActionChip(
                  avatar: const Icon(Icons.people, size: 18),
                  label: Text('Clients ${controller.clients.length}'),
                  onPressed: () => _showClients(context),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: Icon(
                    controller.server.heartbeatEnabled
                        ? Icons.monitor_heart
                        : Icons.heart_broken,
                    size: 18,
                  ),
                  label: Text(
                    controller.server.heartbeatEnabled
                        ? 'Heartbeat ${controller.server.heartbeatIntervalSeconds}s'
                        : 'Heartbeat off',
                  ),
                  onPressed: () => _showServerDialog(context),
                ),
                const SizedBox(width: 8),
              ],
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
              if (!isNarrow)
                OutlinedButton.icon(
                  onPressed: busy ? null : controller.restartServer,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Restart'),
                )
              else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'restart' && !busy) {
                      controller.restartServer();
                    } else if (value == 'clients') {
                      _showClients(context);
                    } else if (value == 'heartbeat') {
                      _showServerDialog(context);
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'restart',
                          enabled: !busy,
                          child: const ListTile(
                            leading: Icon(Icons.restart_alt),
                            title: Text('Restart'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'clients',
                          child: ListTile(
                            leading: const Icon(Icons.people),
                            title: Text('Clients ${controller.clients.length}'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'heartbeat',
                          child: ListTile(
                            leading: Icon(
                              controller.server.heartbeatEnabled
                                  ? Icons.monitor_heart
                                  : Icons.heart_broken,
                            ),
                            title: Text(
                              controller.server.heartbeatEnabled
                                  ? 'Heartbeat ${controller.server.heartbeatIntervalSeconds}s'
                                  : 'Heartbeat off',
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showServerDialog(BuildContext context) async {
    final host = TextEditingController(text: controller.server.bindHost);
    final port = TextEditingController(text: controller.server.port.toString());
    final interval = TextEditingController(
      text: controller.server.heartbeatIntervalSeconds.toString(),
    );
    var heartbeat = controller.server.heartbeatEnabled;
    final result = await showDialog<CarParkingServerProfile>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Server Settings'),
                  content: SizedBox(
                    width: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: host,
                          decoration: const InputDecoration(
                            labelText: 'Bind host',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: port,
                          decoration: const InputDecoration(labelText: 'Port'),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          value: heartbeat,
                          onChanged:
                              (value) => setState(() => heartbeat = value),
                          title: const Text('Heartbeat'),
                        ),
                        TextField(
                          controller: interval,
                          enabled: heartbeat,
                          decoration: const InputDecoration(
                            labelText: 'Heartbeat seconds',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed:
                          () => Navigator.pop(
                            context,
                            controller.server.copyWith(
                              bindHost: host.text.trim(),
                              port:
                                  int.tryParse(port.text) ??
                                  controller.server.port,
                              heartbeatEnabled: heartbeat,
                              heartbeatIntervalSeconds:
                                  int.tryParse(interval.text) ??
                                  controller.server.heartbeatIntervalSeconds,
                            ),
                          ),
                      child: const Text('Save & restart'),
                    ),
                  ],
                ),
          ),
    );
    host.dispose();
    port.dispose();
    interval.dispose();
    if (result != null) {
      await controller.applyServerAndRestart(result);
    }
  }

  void _showClients(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Connected Clients'),
            content: SizedBox(
              width: 520,
              child:
                  controller.clients.isEmpty
                      ? const Text('No clients connected.')
                      : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final client in controller.clients)
                            ListTile(
                              leading: const Icon(Icons.computer),
                              title: Text(
                                '${client.remoteAddress}:${client.remotePort}',
                              ),
                              subtitle: Text(
                                'Connected: ${client.connectedAt.toLocal()}\n'
                                'Last message: ${client.lastMessageAt?.toLocal() ?? '-'}',
                              ),
                            ),
                        ],
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
