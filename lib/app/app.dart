import 'package:flutter/material.dart';
import 'package:socket_server/app/module_registry.dart';

class SocketTestingToolsApp extends StatelessWidget {
  const SocketTestingToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Socket Testing Tools', debugShowCheckedModeBanner: false, theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)), useMaterial3: true, visualDensity: VisualDensity.compact), home: const ModuleHomeScreen());
  }
}

class ModuleHomeScreen extends StatefulWidget {
  const ModuleHomeScreen({super.key});

  @override
  State<ModuleHomeScreen> createState() => _ModuleHomeScreenState();
}

class _ModuleHomeScreenState extends State<ModuleHomeScreen> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final modules = ModuleRegistry.modules;
    final selectedIndex = _selectedIndex;
    final selected = selectedIndex == null ? null : modules[selectedIndex];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.sizeOf(context).width >= 1180,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            leading: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Icon(Icons.hub_outlined)),
            destinations: [for (final module in modules) NavigationRailDestination(icon: Icon(module.icon), selectedIcon: Icon(module.selectedIcon), label: Text(module.shortTitle))],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _ModuleHeader(module: selected),
                const Divider(height: 1),
                Expanded(
                  child:
                      selected == null
                          ? _ModuleDashboard(
                            modules: modules,
                            onOpen: (index) {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                          )
                          : selected.builder(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleHeader extends StatelessWidget {
  const _ModuleHeader({required this.module});

  final TestingModule? module;

  @override
  Widget build(BuildContext context) {
    final selected = module;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(selected?.selectedIcon ?? Icons.dashboard_customize, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selected?.title ?? 'Socket Testing Tools', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                Text(selected?.description ?? 'Choose a desktop testing module to begin.', style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleDashboard extends StatelessWidget {
  const _ModuleDashboard({required this.modules, required this.onOpen});

  final List<TestingModule> modules;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 360, mainAxisExtent: 150, crossAxisSpacing: 16, mainAxisSpacing: 16),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onOpen(index),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(module.selectedIcon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(module.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Expanded(child: Text(module.description, maxLines: 2, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
