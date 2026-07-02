import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:fluxlab/app/app_settings_controller.dart';
import 'package:fluxlab/app/module_registry.dart';
import 'package:fluxlab/l10n/app_localizations.dart';

class FluxLabApp extends StatelessWidget {
  const FluxLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppSettingsController()..load(),
      child: Consumer<AppSettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'FluxLab',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: settings.themeMode,
            locale: settings.settings.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ModuleHomeScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF06B6D4),
      brightness: brightness,
    );
    const radius = 3.0;
    final denseShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
      scaffoldBackgroundColor:
          brightness == Brightness.dark
              ? const Color(0xFF0B0F14)
              : const Color(0xFFF7F8FA),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: denseShape.copyWith(
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: denseShape,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: const Size(32, 32),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: denseShape,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: const Size(32, 32),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: denseShape,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          minimumSize: const Size(32, 32),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.primary, width: 1.2),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      ),
      chipTheme: ChipThemeData(
        shape: denseShape,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: denseShape,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
      ),
      dialogTheme: DialogThemeData(shape: denseShape),
      navigationRailTheme: NavigationRailThemeData(
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
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
                  label: Text(module.localizedShortTitle(context)),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
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
                  selected?.localizedTitle(context) ?? l10n.appTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  selected?.localizedDescription(context) ?? l10n.chooseModule,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _AppPreferencesMenu(l10n: l10n),
        ],
      ),
    );
  }
}

class _AppPreferencesMenu extends StatelessWidget {
  const _AppPreferencesMenu({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    return PopupMenuButton<String>(
      tooltip: 'Preferences',
      icon: const Icon(Icons.settings_outlined, size: 20),
      onSelected: (value) {
        switch (value) {
          case 'theme_system':
            settings.setThemeMode(ThemeMode.system);
          case 'theme_light':
            settings.setThemeMode(ThemeMode.light);
          case 'theme_dark':
            settings.setThemeMode(ThemeMode.dark);
          case 'locale_system':
            settings.setLocaleCode('system');
          case 'locale_en':
            settings.setLocaleCode('en');
          case 'locale_vi':
            settings.setLocaleCode('vi');
          case 'about':
            showAboutDialog(
              context: context,
              applicationName: 'FluxLab',
              applicationVersion: 'Developer Testing Workbench',
              children: const [
                Text(
                  'API, socket, serial, terminal, payload, protocol bridge, and simulator workflows.',
                ),
              ],
            );
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem(
              enabled: false,
              child: Text(
                'Theme',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            CheckedPopupMenuItem(
              value: 'theme_system',
              checked: settings.themeMode == ThemeMode.system,
              child: Text(l10n.system),
            ),
            CheckedPopupMenuItem(
              value: 'theme_light',
              checked: settings.themeMode == ThemeMode.light,
              child: const Text('Light'),
            ),
            CheckedPopupMenuItem(
              value: 'theme_dark',
              checked: settings.themeMode == ThemeMode.dark,
              child: const Text('Dark'),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              enabled: false,
              child: Text(
                'Language',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            CheckedPopupMenuItem(
              value: 'locale_system',
              checked: settings.localeCode == 'system',
              child: Text(l10n.system),
            ),
            CheckedPopupMenuItem(
              value: 'locale_en',
              checked: settings.localeCode == 'en',
              child: Text(l10n.english),
            ),
            CheckedPopupMenuItem(
              value: 'locale_vi',
              checked: settings.localeCode == 'vi',
              child: Text(l10n.vietnamese),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'about', child: Text('About FluxLab')),
          ],
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
            borderRadius: BorderRadius.circular(3),
            onTap: () => onOpen(index),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    module.selectedIcon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    module.localizedTitle(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      module.localizedDescription(context),
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
