import 'package:flutter/material.dart';

enum RowType { card, io }

class DeviceRow {
  RowType type;
  TextEditingController cardController;
  TextEditingController readerController;
  String selectedInputName;

  DeviceRow({
    this.type = RowType.card,
    String cardNumber = "",
    String reader = "",
    this.selectedInputName = "",
  }) : cardController = TextEditingController(text: cardNumber),
       readerController = TextEditingController(text: reader);

  Map<String, dynamic> toJson() {
    return {
      "type": type.toString(),
      "cardNumber": cardController.text,
      "reader": readerController.text,
      "selectedInputName": selectedInputName,
    };
  }

  factory DeviceRow.fromJson(Map<String, dynamic> json) {
    final typeStr = json["type"] ?? RowType.card.toString();
    final type = typeStr.contains("io") ? RowType.io : RowType.card;

    return DeviceRow(
      type: type,
      cardNumber: json["cardNumber"] ?? "",
      reader: json["reader"] ?? "",
      selectedInputName: json["selectedInputName"] ?? "",
    );
  }
}
