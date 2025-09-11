// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:socket_server/view_models/socket_server_view_model.dart';
// import '../models/device_row.dart';
// import 'device_config_page.dart';

// class SocketServerPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final vm = context.watch<SocketServerViewModel>();

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('SOCKET SERVER'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.settings),
//             onPressed: () async {
//               final result = await Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => DeviceConfigPage(deviceInfo: vm.deviceInfo),
//                 ),
//               );
//               if (result != null) {
//                 vm.setDeviceInfo(result);
//               }
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Status bar
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.all(16),
//             color: vm.isServerRunning ? Colors.green.shade100 : Colors.red.shade100,
//             child: Row(
//               children: [
//                 Icon(
//                   vm.isServerRunning ? Icons.check_circle : Icons.error,
//                   color: vm.isServerRunning ? Colors.green : Colors.red,
//                 ),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     vm.serverStatus,
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: vm.isServerRunning ? Colors.green.shade800 : Colors.red.shade800,
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(
//                     'Dữ liệu lưu tại : ${vm.storage.path ?? "chưa có"}',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: vm.isServerRunning ? Colors.green.shade800 : Colors.red.shade800,
//                     ),
//                   ),
//                 ),
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: vm.clientsCount > 0 ? Colors.blue.shade100 : Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                       color: vm.clientsCount > 0 ? Colors.blue : Colors.grey,
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         Icons.people,
//                         size: 16,
//                         color: vm.clientsCount > 0 ? Colors.blue.shade700 : Colors.grey.shade600,
//                       ),
//                       SizedBox(width: 4),
//                       Text(
//                         'Clients: ${vm.clientsCount}',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: vm.clientsCount > 0 ? Colors.blue.shade700 : Colors.grey.shade600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Rows
//           Expanded(
//             child: ListView.builder(
//               itemCount: vm.rows.length,
//               itemBuilder: (context, index) {
//                 final row = vm.rows[index];
//                 if (row.type == RowType.card) {
//                   return _buildCardRow(vm, row);
//                 } else {
//                   return _buildIoRow(vm, row);
//                 }
//               },
//             ),
//           ),

//           // Buttons
//           Container(
//             padding: EdgeInsets.all(16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: () async {
//                     final type = await showDialog<RowType>(
//                       context: context,
//                       builder: (_) => AlertDialog(
//                         title: Text("Chọn loại dòng"),
//                         content: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             ListTile(
//                               leading: Icon(Icons.credit_card),
//                               title: Text("Card"),
//                               onTap: () => Navigator.pop(context, RowType.card),
//                             ),
//                             ListTile(
//                               leading: Icon(Icons.sensors),
//                               title: Text("Vòng từ (iOStatus)"),
//                               onTap: () => Navigator.pop(context, RowType.io),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                     if (type != null) {
//                       vm.addRow(type);
//                     }
//                   },
//                   icon: Icon(Icons.add),
//                   label: Text("Thêm dòng"),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: vm.rows.length > 1 ? () => vm.removeLastRow() : null,
//                   icon: Icon(Icons.remove),
//                   label: Text('Xóa dòng'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCardRow(SocketServerViewModel vm, DeviceRow row) {
//     return Container(
//       margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 2,
//             child: TextField(
//               controller: row.cardController,
//               decoration: InputDecoration(labelText: "Số Thẻ"),
//               onChanged: (_) => vm.saveData(),
//             ),
//           ),
//           SizedBox(width: 16),
//           Expanded(
//             flex: 2,
//             child: TextField(
//               controller: row.readerController,
//               decoration: InputDecoration(labelText: "Chân Reader"),
//               onChanged: (_) => vm.saveData(),
//             ),
//           ),
//           SizedBox(width: 16),
//           ElevatedButton(
//             onPressed: () => vm.sendCard(row.cardController.text, row.readerController.text),
//             child: Text("Gửi"),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildIoRow(SocketServerViewModel vm, DeviceRow row) {
//     final inputNames = [
//       "Button 1",
//       "Button 2",
//       "Button 3",
//       "Button 4",
//       "Aux 1",
//       "Aux 2",
//       "Aux 3",
//       "Aux 4",
//     ];
//     return Container(
//       margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.orange.shade300),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: DropdownButtonFormField<String>(
//               value: row.selectedInputName.isNotEmpty ? row.selectedInputName : null,
//               items: inputNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
//               onChanged: (val) {
//                 row.selectedInputName = val ?? "";
//                 vm.saveData();
//               },
//               decoration: InputDecoration(labelText: "Chọn Input"),
//             ),
//           ),
//           SizedBox(width: 16),
//           ElevatedButton(
//             onPressed: () => vm.sendIoStatus(row.selectedInputName),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
//             child: Text("Gửi"),
//           ),
//         ],
//       ),
//     );
//   }
// }
