import 'package:flutter/material.dart';

enum RowType { card, io }

class DeviceRow {
  RowType type;
  TextEditingController cardController = TextEditingController();
  TextEditingController readerController = TextEditingController();

  // cho IO row
  String selectedInputName = "Button 1";

  DeviceRow.card({String cardId = '', String readerId = ''})
    : type = RowType.card {
    cardController.text = cardId;
    readerController.text = readerId;
  }

  DeviceRow.io({String inputName = "Button 1"}) : type = RowType.io {
    selectedInputName = inputName;
  }

  Map<String, dynamic> toJson() {
    if (type == RowType.card) {
      return {
        "type": "card",
        "cardId": cardController.text,
        "readerId": readerController.text,
      };
    } else {
      return {"type": "io", "inputName": selectedInputName};
    }
  }

  factory DeviceRow.fromJson(Map<String, dynamic> json) {
    if (json["type"] == "io") {
      return DeviceRow.io(inputName: json["inputName"] ?? "Button 1");
    }
    return DeviceRow.card(
      cardId: json["cardId"] ?? "",
      readerId: json["readerId"] ?? "",
    );
  }

  void dispose() {
    cardController.dispose();
    readerController.dispose();
  }
}
