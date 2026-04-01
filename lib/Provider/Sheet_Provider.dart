import 'package:flutter/material.dart';

class SheetProvider extends ChangeNotifier {
  List<List<String>> sheetData = [
    ['Name', 'Age', 'City'],
    ['Alice', '23', 'NY'],
    ['Bob', '29', 'LA'],
  ];

  bool canEdit = false;

  void toggleEditPermission(bool value) {
    canEdit = value;
    notifyListeners();
  }

  void updateCell(int row, int col, String value) {
    sheetData[row][col] = value;
    notifyListeners();
  }

  void addRow() {
    sheetData.add(List.generate(sheetData[0].length, (_) => ''));
    notifyListeners();
  }

  void addColumn() {
    for (var row in sheetData) {
      row.add('');
    }
    notifyListeners();
  }
}
