import 'package:flutter/material.dart';
import 'package:testdeck/l10n/app_localizations.dart';
import 'package:testdeck/modules/api_lab/api_lab_screen.dart';
import 'package:testdeck/modules/carparking/ui/carparking_module_screen.dart';
import 'package:testdeck/modules/payload_studio/payload_studio_screen.dart';
import 'package:testdeck/modules/protocol_bridge/protocol_bridge_screen.dart';
import 'package:testdeck/modules/serial_lab/serial_lab_screen.dart';
import 'package:testdeck/modules/tcp_lab/tcp_lab_screen.dart';
import 'package:testdeck/modules/websocket_lab/websocket_lab_screen.dart';

class TestingModule {
  const TestingModule({
    required this.title,
    required this.shortTitle,
    required this.description,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String title;
  final String shortTitle;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;

  String localizedTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (shortTitle) {
      'CarParking' => l10n.carParkingTitle,
      'TCP Lab' => l10n.tcpLabTitle,
      'WebSocket' => l10n.webSocketTitle,
      'Serial' => l10n.serialTitle,
      'Bridge' => l10n.bridgeTitle,
      'Payloads' => l10n.payloadStudioTitle,
      'API' => l10n.apiLabTitle,
      _ => title,
    };
  }

  String localizedShortTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (shortTitle) {
      'CarParking' => l10n.carParkingShort,
      'TCP Lab' => l10n.tcpLabShort,
      'WebSocket' => l10n.webSocketShort,
      'Serial' => l10n.serialShort,
      'Bridge' => l10n.bridgeShort,
      'Payloads' => l10n.payloadStudioShort,
      'API' => l10n.apiLabShort,
      _ => shortTitle,
    };
  }

  String localizedDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (shortTitle) {
      'CarParking' => l10n.carParkingDescription,
      'TCP Lab' => l10n.tcpLabDescription,
      'WebSocket' => l10n.webSocketDescription,
      'Serial' => l10n.serialDescription,
      'Bridge' => l10n.bridgeDescription,
      'Payloads' => l10n.payloadStudioDescription,
      'API' => l10n.apiLabDescription,
      _ => description,
    };
  }
}

class ModuleRegistry {
  const ModuleRegistry._();

  static final modules = <TestingModule>[
    TestingModule(
      title: 'CarParking Device Gateway Simulator',
      shortTitle: 'CarParking',
      description:
          'Device Gateway TCP simulator for CarParking_Techpro_Client.',
      icon: Icons.local_parking_outlined,
      selectedIcon: Icons.local_parking,
      builder: (_) => const CarParkingModuleScreen(),
    ),
    TestingModule(
      title: 'TCP Socket Lab',
      shortTitle: 'TCP Lab',
      description: 'Generic TCP client/server workspace.',
      icon: Icons.settings_ethernet_outlined,
      selectedIcon: Icons.settings_ethernet,
      builder: (_) => const TcpLabScreen(),
    ),
    TestingModule(
      title: 'WebSocket Lab',
      shortTitle: 'WebSocket',
      description: 'WebSocket send/receive test bench.',
      icon: Icons.cable_outlined,
      selectedIcon: Icons.cable,
      builder: (_) => const WebSocketLabScreen(),
    ),
    TestingModule(
      title: 'Serial/COM Lab',
      shortTitle: 'Serial',
      description: 'Desktop serial-port test bench.',
      icon: Icons.usb_outlined,
      selectedIcon: Icons.usb,
      builder: (_) => const SerialLabScreen(),
    ),
    TestingModule(
      title: 'Protocol Bridge',
      shortTitle: 'Bridge',
      description: 'Future TCP, Serial, and WebSocket bridge tools.',
      icon: Icons.account_tree_outlined,
      selectedIcon: Icons.account_tree,
      builder: (_) => const ProtocolBridgeScreen(),
    ),
    TestingModule(
      title: 'API Lab',
      shortTitle: 'API',
      description:
          'HTTP/API testing workspace with collections, environments, variables, and import/export.',
      icon: Icons.api_outlined,
      selectedIcon: Icons.api,
      builder: (_) => const ApiLabScreen(),
    ),
    TestingModule(
      title: 'Payload Studio / Converter',
      shortTitle: 'Payloads',
      description: 'Future JSON, text, and hex conversion workspace.',
      icon: Icons.data_object_outlined,
      selectedIcon: Icons.data_object,
      builder: (_) => const PayloadStudioScreen(),
    ),
  ];
}
