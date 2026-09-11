import 'package:flutter/material.dart';
import 'package:fluxlab/modules/carparking/models/carparking_models.dart';
import 'package:fluxlab/modules/carparking/services/carparking_controller.dart';
import 'package:fluxlab/modules/carparking/services/carparking_scenario_runner.dart';

class CarParkingScenarioToolbar extends StatelessWidget {
  const CarParkingScenarioToolbar({
    super.key,
    required this.controller,
    required this.selectedRows,
  });

  final CarParkingController controller;
  final Set<String> selectedRows;

  @override
  Widget build(BuildContext context) {
    final scenario =
        controller.workspace.scenarios.isEmpty
            ? CarParkingScenario.defaults()
            : controller.workspace.scenarios.first;
    final snapshot = controller.runnerSnapshot;
    final running = snapshot.status == ScenarioRunnerStatus.running;
    final paused = snapshot.status == ScenarioRunnerStatus.paused;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.icon(
            onPressed:
                running
                    ? controller.stopScenario
                    : () => controller.startScenario(
                      selectedRowIds: selectedRows.toList(),
                    ),
            icon: Icon(running ? Icons.stop : Icons.play_arrow),
            label: Text(running ? 'Stop' : 'Start Auto'),
          ),
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
          Chip(label: Text('${selectedRows.length} selected')),
          ActionChip(
            avatar: const Icon(Icons.settings, size: 18),
            label: Text(
              '${scenario.mode.name} • ${scenario.defaultDelayMs}ms • ${scenario.loopCount == 0 ? '∞' : scenario.loopCount} loops',
            ),
            onPressed:
                controller.autoTestRunning
                    ? null
                    : () => _showScenarioSettings(context, scenario),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Step ${snapshot.totalSteps == 0 ? 0 : snapshot.currentStepIndex + 1}/${snapshot.totalSteps} • Loop ${snapshot.completedLoops}',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showScenarioSettings(
    BuildContext context,
    CarParkingScenario scenario,
  ) async {
    final loops = TextEditingController(text: scenario.loopCount.toString());
    final delay = TextEditingController(
      text: scenario.defaultDelayMs.toString(),
    );
    var mode = scenario.mode;
    var stopOnError = scenario.stopOnError;

    final result = await showDialog<CarParkingScenario>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Scenario Settings'),
                  content: SizedBox(
                    width: 320,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<CarParkingScenarioMode>(
                          decoration: const InputDecoration(labelText: 'Mode'),
                          initialValue: mode,
                          items: const [
                            DropdownMenuItem(
                              value: CarParkingScenarioMode.sequential,
                              child: Text('Sequential'),
                            ),
                            DropdownMenuItem(
                              value: CarParkingScenarioMode.random,
                              child: Text('Random'),
                            ),
                          ],
                          onChanged: (value) => setState(() => mode = value!),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: loops,
                          decoration: const InputDecoration(
                            labelText: 'Loops (0 for infinite)',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: delay,
                          decoration: const InputDecoration(
                            labelText: 'Delay (ms)',
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          title: const Text('Stop on error'),
                          value: stopOnError,
                          onChanged:
                              (value) => setState(() => stopOnError = value),
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
                      onPressed: () {
                        Navigator.pop(
                          context,
                          scenario.copyWith(
                            mode: mode,
                            loopCount:
                                int.tryParse(loops.text) ?? scenario.loopCount,
                            defaultDelayMs:
                                int.tryParse(delay.text) ??
                                scenario.defaultDelayMs,
                            stopOnError: stopOnError,
                          ),
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
    loops.dispose();
    delay.dispose();
    if (result != null) {
      controller.updateScenario(result);
    }
  }
}
