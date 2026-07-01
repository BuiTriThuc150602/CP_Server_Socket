import 'package:flutter/material.dart';
import 'package:socket_server/modules/carparking/ui/carparking_module_screen.dart';
import 'package:socket_server/modules/payload_studio/payload_studio_screen.dart';
import 'package:socket_server/modules/protocol_bridge/protocol_bridge_screen.dart';
import 'package:socket_server/modules/serial_lab/serial_lab_screen.dart';
import 'package:socket_server/modules/tcp_lab/tcp_lab_screen.dart';
import 'package:socket_server/modules/websocket_lab/websocket_lab_screen.dart';

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
      title: 'Payload Studio / Converter',
      shortTitle: 'Payloads',
      description: 'Future JSON, text, and hex conversion workspace.',
      icon: Icons.data_object_outlined,
      selectedIcon: Icons.data_object,
      builder: (_) => const PayloadStudioScreen(),
    ),
  ];
}
