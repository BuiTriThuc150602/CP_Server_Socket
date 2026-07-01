import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_server/app/app_settings_controller.dart';
import 'package:socket_server/app/module_registry.dart';

class SocketTestingToolsApp extends StatelessWidget {
  const SocketTestingToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppSettingsController()..load(),
      child: Consumer<AppSettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Socket Testing Tools',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: settings.themeMode,
            home: const ModuleHomeScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

class ModuleHomeScreen extends StatefulWidget {
  const ModuleHomeScreen({super.key});

  @override
  State<ModuleHomeScreen> createState() => _ModuleHomeScreenState();
}

class _ModuleHomeScreenState extends State<ModuleHomeScreen> {
  int? _selectedIndex;
  bool? _railExpanded; // null = auto (follows window width)

  bool _isRailExpanded(BuildContext context) {
    if (_railExpanded != null) return _railExpanded!;
    return MediaQuery.sizeOf(context).width >= 1180;
  }

  @override
  Widget build(BuildContext context) {
    final modules = ModuleRegistry.modules;
    final selectedIndex = _selectedIndex;
    final selected = selectedIndex == null ? null : modules[selectedIndex];
    final expanded = _isRailExpanded(context);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: expanded,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Icon(Icons.hub_outlined),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    tooltip: expanded ? 'Collapse sidebar' : 'Expand sidebar',
                    icon: Icon(
                      expanded ? Icons.chevron_left : Icons.chevron_right,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _railExpanded = !expanded;
                      });
                    },
                  ),
                ),
              ),
            ),
            destinations: [
              for (final module in modules)
                NavigationRailDestination(
                  icon: Icon(module.icon),
                  selectedIcon: Icon(module.selectedIcon),
                  label: Text(module.shortTitle),
                ),
            ],
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
    final settings = context.watch<AppSettingsController>();
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(
            selected?.selectedIcon ?? Icons.dashboard_customize,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected?.title ?? 'Socket Testing Tools',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  selected?.description ??
                      'Choose a desktop testing module to begin.',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                tooltip: 'System theme',
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                tooltip: 'Light theme',
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                tooltip: 'Dark theme',
              ),
            ],
            selected: {settings.themeMode},
            showSelectedIcon: false,
            onSelectionChanged: (value) {
              settings.setThemeMode(value.first);
            },
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
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        mainAxisExtent: 150,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
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
                  Icon(
                    module.selectedIcon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    module.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      module.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
