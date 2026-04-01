import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Colors/Appbar.dart';

class MechanicalDpt extends StatelessWidget {
  final bool isAdmin;
  const MechanicalDpt({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Professional Spreadsheet',
      home: SpreadsheetHomePage(isAdmin: isAdmin),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

class SpreadsheetHomePage extends StatefulWidget {
  final bool isAdmin;
  const SpreadsheetHomePage({super.key, required this.isAdmin});

  @override
  State<SpreadsheetHomePage> createState() => _SpreadsheetHomePageState();
}

class _SpreadsheetHomePageState extends State<SpreadsheetHomePage> {
  List<SpreadsheetFile> savedFiles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllSheets();
  }

  Future<void> _loadAllSheets() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final filesJson = prefs.getString('Mechanical_Sheet');

    if (filesJson != null && filesJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(filesJson);
      savedFiles = decoded.map((json) => SpreadsheetFile.fromJson(json)).toList();
    }

    setState(() => isLoading = false);
  }

  Future<void> _saveAllSheets() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(savedFiles.map((f) => f.toJson()).toList());
    await prefs.setString('Mechanical_Sheet', encoded);
  }

  List<List<String>> _getDefaultSheetData() {
    return [
      ['S.NO', 'PROJECT', 'MATERIAL', 'FAILURE', 'STATUS'],
      ['1', 'Project A', 'Steel', '45', 'Active'],
      ['2', 'Project B', 'Aluminum', '73', 'Active'],
      ['3', 'Project C', 'Copper', '99', 'Completed'],
      ['4', 'Project D', 'Steel', '23', 'Pending'],
      ['5', 'Project E', 'Aluminum', '67', 'Active'],
    ];
  }

  Future<void> _createNewSheet() async {
    final fileName = await _showFileNameDialog();
    if (fileName != null && fileName.isNotEmpty) {
      final newFile = SpreadsheetFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        data: _getDefaultSheetData(),
      );

      savedFiles.add(newFile);
      await _saveAllSheets();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfessionalSpreadsheet(
              isAdmin: widget.isAdmin,
              spreadsheetFile: newFile,
              onSave: _saveAllSheets,
            ),
          ),
        ).then((_) => _loadAllSheets());
      }
    }
  }

  Future<String?> _showFileNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Spreadsheet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter file name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: appbarwidget(),
        centerTitle: true,
        title: const Text('Mechanical Department Spreadsheets'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewSheet,
            tooltip: 'New Spreadsheet',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : savedFiles.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No spreadsheets yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create your first spreadsheet',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: savedFiles.length,
        itemBuilder: (context, index) {
          final file = savedFiles[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.table_chart, color: Colors.blue),
              ),
              title: Text(
                file.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Last modified: ${_formatDate(file.lastModified)}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfessionalSpreadsheet(
                            isAdmin: widget.isAdmin,
                            spreadsheetFile: file,
                            onSave: _saveAllSheets,
                          ),
                        ),
                      ).then((_) => _loadAllSheets());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteFile(file),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewSheet,
        child: const Icon(Icons.add),
        tooltip: 'New Spreadsheet',
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteFile(SpreadsheetFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Spreadsheet'),
        content: Text('Are you sure you want to delete "${file.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        savedFiles.removeWhere((f) => f.id == file.id);
      });
      await _saveAllSheets();
    }
  }
}

class SpreadsheetFile {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime lastModified;
  List<List<String>> data;

  SpreadsheetFile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastModified,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'lastModified': lastModified.toIso8601String(),
    'data': data,
  };

  factory SpreadsheetFile.fromJson(Map<String, dynamic> json) => SpreadsheetFile(
    id: json['id'],
    name: json['name'],
    createdAt: DateTime.parse(json['createdAt']),
    lastModified: DateTime.parse(json['lastModified']),
    data: List<List<String>>.from(json['data'].map((row) => List<String>.from(row))),
  );
}

class ProfessionalSpreadsheet extends StatefulWidget {
  final bool isAdmin;
  final SpreadsheetFile spreadsheetFile;
  final VoidCallback onSave;

  const ProfessionalSpreadsheet({
    super.key,
    required this.isAdmin,
    required this.spreadsheetFile,
    required this.onSave,
  });

  @override
  State<ProfessionalSpreadsheet> createState() => _ProfessionalSpreadsheetState();
}

class _ProfessionalSpreadsheetState extends State<ProfessionalSpreadsheet> {
  late List<List<String>> sheetData;
  late List<List<List<String>>> _history;
  late List<List<List<String>>> _redoStack;
  final int _maxUndoSteps = 50;

  bool editMode = false;
  bool isSearching = false;
  int? selectedRow;
  int? selectedCol;
  Offset? selectedStart;
  Offset? selectedEnd;

  final TextEditingController searchController = TextEditingController();
  List<Offset> searchResults = [];
  int currentSearchIndex = -1;

  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _verticalScroll = ScrollController();

  // Zoom controls
  double _zoomLevel = 1.0;
  final TransformationController _transformationController = TransformationController();

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    sheetData = _cloneSheet(widget.spreadsheetFile.data);
    _initHistory();
  }

  void _initHistory() {
    _history = [_cloneSheet(sheetData)];
    _redoStack = [];
  }

  void _addToHistory() {
    if (_history.length >= _maxUndoSteps) {
      _history.removeAt(0);
    }
    _history.add(_cloneSheet(sheetData));
    _redoStack.clear();
  }

  void undo() {
    if (_history.length > 1) {
      final current = _history.removeLast();
      _redoStack.add(current);
      setState(() {
        sheetData = _cloneSheet(_history.last);
      });
      _autoSave();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      final redoData = _redoStack.removeLast();
      _addToHistory();
      setState(() {
        sheetData = _cloneSheet(redoData);
      });
      _autoSave();
    }
  }

  bool get canUndo => _history.length > 1;
  bool get canRedo => _redoStack.isNotEmpty;

  List<List<String>> _cloneSheet(List<List<String>> original) {
    return original.map((row) => List<String>.from(row)).toList();
  }

  void _autoSave() {
    widget.spreadsheetFile.data = _cloneSheet(sheetData);
    widget.spreadsheetFile.lastModified = DateTime.now();
    widget.onSave();
  }

  void updateCell(int row, int col, String value) {
    setState(() {
      sheetData[row][col] = value;
    });
    _autoSave();
  }

  void addRow() {
    setState(() {
      final newRow = List.generate(sheetData[0].length, (_) => '');
      sheetData.add(newRow);
      _addToHistory();
      _autoSave();
    });
    _showSnackBar('Row added');
  }

  void addColumn() {
    setState(() {
      final newColumnName = 'Column ${_getColumnLabel(sheetData[0].length)}';

      for (int i = 0; i < sheetData.length; i++) {
        sheetData[i].add(i == 0 ? newColumnName : '');
      }
      _addToHistory();
      _autoSave();
    });
    _showSnackBar('Column added');
  }

  String _getColumnLabel(int index) {
    String result = '';
    while (index >= 0) {
      result = String.fromCharCode(65 + (index % 26)) + result;
      index = (index ~/ 26) - 1;
    }
    return result;
  }

  void deleteRow() {
    if (selectedRow != null && selectedRow! < sheetData.length && selectedRow! > 0) {
      setState(() {
        sheetData.removeAt(selectedRow!);
        selectedRow = null;
        _addToHistory();
        _autoSave();
      });
      _showSnackBar('Row deleted');
    } else {
      _showSnackBar('Please select a valid row to delete');
    }
  }

  void deleteColumn() {
    if (selectedCol != null && selectedCol! < sheetData[0].length && selectedCol! > 0) {
      setState(() {
        for (var row in sheetData) {
          row.removeAt(selectedCol!);
        }
        selectedCol = null;
        _addToHistory();
        _autoSave();
      });
      _showSnackBar('Column deleted');
    } else {
      _showSnackBar('Please select a valid column to delete');
    }
  }

  void clearSelection() {
    setState(() {
      selectedStart = null;
      selectedEnd = null;
      selectedRow = null;
      selectedCol = null;
    });
  }

  String getColumnLabel(int index) {
    String label = '';
    while (index >= 0) {
      label = String.fromCharCode((index % 26) + 65) + label;
      index = (index ~/ 26) - 1;
    }
    return label;
  }

  bool isCellInSelection(int row, int col) {
    if (selectedStart == null || selectedEnd == null) return false;
    int startRow = selectedStart!.dy.toInt();
    int endRow = selectedEnd!.dy.toInt();
    int startCol = selectedStart!.dx.toInt();
    int endCol = selectedEnd!.dx.toInt();

    if (startRow > endRow) {
      final temp = startRow;
      startRow = endRow;
      endRow = temp;
    }
    if (startCol > endCol) {
      final temp = startCol;
      startCol = endCol;
      endCol = temp;
    }
    return row >= startRow && row <= endRow && col >= startCol && col <= endCol;
  }

  List<List<String>> getSelectedRangeData() {
    if (selectedStart == null || selectedEnd == null) return [];
    int startRow = selectedStart!.dy.toInt();
    int endRow = selectedEnd!.dy.toInt();
    int startCol = selectedStart!.dx.toInt();
    int endCol = selectedEnd!.dx.toInt();

    if (startRow > endRow) {
      final temp = startRow;
      startRow = endRow;
      endRow = temp;
    }
    if (startCol > endCol) {
      final temp = startCol;
      startCol = endCol;
      endCol = temp;
    }

    // Ensure indices are within bounds
    startRow = startRow.clamp(0, sheetData.length - 1);
    endRow = endRow.clamp(0, sheetData.length - 1);
    startCol = startCol.clamp(0, sheetData[0].length - 1);
    endCol = endCol.clamp(0, sheetData[0].length - 1);

    return sheetData.sublist(startRow, endRow + 1)
        .map((row) => row.sublist(startCol, endCol + 1))
        .toList();
  }

  void copySelection() {
    final selectedData = getSelectedRangeData();
    if (selectedData.isEmpty) {
      _showSnackBar('No range selected');
      return;
    }

    final csv = selectedData.map((row) => row.join('\t')).join('\n');
    Clipboard.setData(ClipboardData(text: csv));
    _showSnackBar('Copied ${selectedData.length} row(s)');
  }

  void pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');

    if (clipboardData == null || clipboardData.text == null) {
      _showSnackBar('Clipboard is empty');
      return;
    }

    final rows = clipboardData.text!.split('\n');
    if (selectedStart == null || rows.isEmpty) {
      _showSnackBar('No range selected');
      return;
    }

    final startRow = selectedStart!.dy.toInt();
    final startCol = selectedStart!.dx.toInt();

    if (startRow >= sheetData.length || startCol >= sheetData[0].length) {
      _showSnackBar('Invalid paste position');
      return;
    }

    setState(() {
      for (int i = 0; i < rows.length && startRow + i < sheetData.length; i++) {
        final cells = rows[i].split('\t');
        for (int j = 0; j < cells.length && startCol + j < sheetData[0].length; j++) {
          sheetData[startRow + i][startCol + j] = cells[j];
        }
      }
      _addToHistory();
      _autoSave();
    });

    _showSnackBar('Pasted successfully');
  }

  void _search(String query) {
    if (query.isEmpty) {
      setState(() {
        searchResults.clear();
        currentSearchIndex = -1;
      });
      return;
    }

    final results = <Offset>[];
    for (int row = 0; row < sheetData.length; row++) {
      for (int col = 0; col < sheetData[row].length; col++) {
        if (sheetData[row][col].toLowerCase().contains(query.toLowerCase())) {
          results.add(Offset(col.toDouble(), row.toDouble()));
        }
      }
    }

    setState(() {
      searchResults = results;
      currentSearchIndex = results.isNotEmpty ? 0 : -1;
      if (currentSearchIndex != -1) {
        selectedStart = searchResults[currentSearchIndex];
        selectedEnd = searchResults[currentSearchIndex];
      }
    });
  }

  void _navigateSearch(int direction) {
    if (searchResults.isEmpty) return;

    currentSearchIndex = (currentSearchIndex + direction) % searchResults.length;
    if (currentSearchIndex < 0) currentSearchIndex = searchResults.length - 1;

    setState(() {
      selectedStart = searchResults[currentSearchIndex];
      selectedEnd = searchResults[currentSearchIndex];

      final row = selectedStart!.dy.toInt();
      final col = selectedStart!.dx.toInt();
      _scrollToCell(row, col);
    });
  }

  void _scrollToCell(int row, int col) {
    final double colPosition = col * 100.0 * _zoomLevel;
    final double rowPosition = row * 40.0 * _zoomLevel;

    _horizontalScroll.animateTo(
      colPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _verticalScroll.animateTo(
      rowPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // void _showGraph() {
  //   final selectedData = getSelectedRangeData();
  //   if (selectedData.isEmpty) {
  //     _showSnackBar('Please select a range first');
  //     return;
  //   }
  //
  //   if (selectedData.length < 2) {
  //     _showSnackBar('Please select at least 2 rows of data');
  //     return;
  //   }
  //
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) => SafeArea(
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const SizedBox(height: 8),
  //           Container(
  //             width: 40,
  //             height: 4,
  //             decoration: BoxDecoration(
  //               color: Colors.grey[300],
  //               borderRadius: BorderRadius.circular(2),
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           ListTile(
  //             leading: const Icon(Icons.pie_chart),
  //             title: const Text('Pie Chart'),
  //             onTap: () => _showChart('pie', selectedData),
  //           ),
  //           const Divider(),
  //           ListTile(
  //             leading: const Icon(Icons.bar_chart),
  //             title: const Text('Bar Chart'),
  //             onTap: () => _showChart('bar', selectedData),
  //           ),
  //           const Divider(),
  //           ListTile(
  //             leading: const Icon(Icons.show_chart),
  //             title: const Text('Line Chart'),
  //             onTap: () => _showChart('line', selectedData),
  //           ),
  //           const SizedBox(height: 8),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  //
  // void _showChart(String type, List<List<String>> chartData) {
  //   Navigator.pop(context);
  //
  //   try {
  //     // Extract numeric data from the selected range
  //     final List<Map<String, dynamic>> chartValues = [];
  //
  //     // Assume first row is headers, subsequent rows contain data
  //     final headers = chartData[0];
  //
  //     // For each data row, try to extract numeric values
  //     for (int i = 1; i < chartData.length && i < chartData.length; i++) {
  //       final row = chartData[i];
  //       for (int j = 0; j < row.length && j < headers.length; j++) {
  //         final value = double.tryParse(row[j]);
  //         if (value != null) {
  //           chartValues.add({
  //             'label': headers[j],
  //             'value': value,
  //             'series': row[0], // First column as series name if available
  //           });
  //         }
  //       }
  //     }
  //
  //     if (chartValues.isEmpty) {
  //       _showSnackBar('No numeric data found in selected range');
  //       return;
  //     }
  //
  //     // Group by label for charts
  //     final Map<String, double> dataMap = {};
  //     for (var item in chartValues) {
  //       final label = item['label'].toString();
  //       final value = item['value'] as double;
  //       if (dataMap.containsKey(label)) {
  //         dataMap[label] = dataMap[label]! + value;
  //       } else {
  //         dataMap[label] = value;
  //       }
  //     }
  //
  //     final labels = dataMap.keys.toList();
  //     final values = dataMap.values.toList();
  //
  //     if (labels.isEmpty || values.isEmpty) {
  //       _showSnackBar('No valid data for chart');
  //       return;
  //     }
  //
  //     showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: Text('$type Chart'),
  //         content: SizedBox(
  //           height: 350,
  //           width: 350,
  //           child: _buildChartWidget(type, labels, values),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text('Close'),
  //           ),
  //         ],
  //       ),
  //     );
  //   } catch (e) {
  //     _showSnackBar('Error creating chart: $e');
  //   }
  // }
  //
  // Widget _buildChartWidget(String type, List<String> labels, List<double> values) {
  //   // Ensure we have valid data
  //   if (labels.isEmpty || values.isEmpty) {
  //     return const Center(
  //       child: Text('No valid data to display'),
  //     );
  //   }
  //
  //   // Limit to 10 items for better display
  //   final displayLabels = labels.length > 10 ? labels.sublist(0, 10) : labels;
  //   final displayValues = values.length > 10 ? values.sublist(0, 10) : values;
  //
  //   switch (type) {
  //     case 'pie':
  //       return PieChart(
  //         PieChartData(
  //           sections: List.generate(
  //             displayValues.length,
  //                 (i) => PieChartSectionData(
  //               value: displayValues[i],
  //               title: displayLabels[i].length > 15
  //                   ? '${displayLabels[i].substring(0, 12)}...'
  //                   : displayLabels[i],
  //               radius: 80,
  //               titleStyle: const TextStyle(
  //                 fontSize: 10,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.white,
  //               ),
  //               color: Colors.primaries[i % Colors.primaries.length],
  //             ),
  //           ),
  //           sectionsSpace: 2,
  //           centerSpaceRadius: 0,
  //         ),
  //       );
  //
  //     case 'bar':
  //       return BarChart(
  //         BarChartData(
  //           barGroups: List.generate(
  //             displayValues.length,
  //                 (i) => BarChartGroupData(
  //               x: i,
  //               barRods: [
  //                 BarChartRodData(
  //                   toY: displayValues[i],
  //                   color: Colors.primaries[i % Colors.primaries.length],
  //                   width: 20,
  //                   borderRadius: BorderRadius.circular(4),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           titlesData: FlTitlesData(
  //             bottomTitles: AxisTitles(
  //               sideTitles: SideTitles(
  //                 showTitles: true,
  //                 getTitlesWidget: (value, meta) {
  //                   final index = value.toInt();
  //                   if (index >= 0 && index < displayLabels.length) {
  //                     return Padding(
  //                       padding: const EdgeInsets.only(top: 8),
  //                       child: Text(
  //                         displayLabels[index].length > 10
  //                             ? '${displayLabels[index].substring(0, 8)}...'
  //                             : displayLabels[index],
  //                         style: const TextStyle(fontSize: 10),
  //                         textAlign: TextAlign.center,
  //                       ),
  //                     );
  //                   }
  //                   return const Text('');
  //                 },
  //                 reservedSize: 40,
  //               ),
  //             ),
  //             leftTitles: const AxisTitles(
  //               sideTitles: SideTitles(showTitles: true),
  //             ),
  //             topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  //             rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  //           ),
  //           gridData: const FlGridData(show: true),
  //           borderData: FlBorderData(show: true),
  //         ),
  //       );
  //
  //     default: // line chart
  //       return LineChart(
  //         LineChartData(
  //           lineBarsData: [
  //             LineChartBarData(
  //               spots: List.generate(
  //                 displayValues.length,
  //                     (i) => FlSpot(i.toDouble(), displayValues[i]),
  //               ),
  //               isCurved: true,
  //               color: Colors.blue,
  //               dotData: const FlDotData(show: true),
  //               belowBarData: BarAreaData(
  //                 show: true,
  //                 color: Colors.blue.withOpacity(0.1),
  //               ),
  //             ),
  //           ],
  //           titlesData: FlTitlesData(
  //             bottomTitles: AxisTitles(
  //               sideTitles: SideTitles(
  //                 showTitles: true,
  //                 getTitlesWidget: (value, meta) {
  //                   final index = value.toInt();
  //                   if (index >= 0 && index < displayLabels.length) {
  //                     return Padding(
  //                       padding: const EdgeInsets.only(top: 8),
  //                       child: Text(
  //                         displayLabels[index].length > 10
  //                             ? '${displayLabels[index].substring(0, 8)}...'
  //                             : displayLabels[index],
  //                         style: const TextStyle(fontSize: 10),
  //                         textAlign: TextAlign.center,
  //                       ),
  //                     );
  //                   }
  //                   return const Text('');
  //                 },
  //                 reservedSize: 40,
  //               ),
  //             ),
  //             leftTitles: const AxisTitles(
  //               sideTitles: SideTitles(showTitles: true),
  //             ),
  //             topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  //             rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  //           ),
  //           gridData: const FlGridData(show: true),
  //           borderData: FlBorderData(show: true),
  //         ),
  //       );
  //   }
  // }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel + 0.1).clamp(0.5, 3.0);
      _transformationController.value = Matrix4.diagonal3Values(_zoomLevel, _zoomLevel, 1.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel - 0.1).clamp(0.5, 3.0);
      _transformationController.value = Matrix4.diagonal3Values(_zoomLevel, _zoomLevel, 1.0);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = sheetData.length;
    final columns = sheetData[0].length;

    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
          controller: searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            suffixIcon: searchResults.isNotEmpty
                ? Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${currentSearchIndex + 1}/${searchResults.length}',
                style: const TextStyle(color: Colors.white),
              ),
            )
                : null,
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: _search,
        )
            : Text(widget.spreadsheetFile.name),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (!isSearching) ...[
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: _zoomIn,
              tooltip: 'Zoom In',
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: _zoomOut,
              tooltip: 'Zoom Out',
            ),
            IconButton(
              icon: const Icon(Icons.center_focus_strong),
              onPressed: _resetZoom,
              tooltip: 'Reset Zoom',
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => isSearching = true),
            ),
            if (widget.isAdmin)
              IconButton(
                icon: Icon(editMode ? Icons.edit_off : Icons.edit),
                onPressed: () => setState(() => editMode = !editMode),
                tooltip: editMode ? 'Exit Edit Mode' : 'Enter Edit Mode',
              ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  isSearching = false;
                  searchController.clear();
                  searchResults.clear();
                  currentSearchIndex = -1;
                });
              },
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.blue[600],
            height: 50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (widget.isAdmin && editMode) ...[
                    _buildToolbarButton(Icons.add_box, 'Add Row', addRow),
                    _buildToolbarButton(Icons.view_column, 'Add Column', addColumn),
                    _buildToolbarButton(Icons.delete_sweep, 'Delete Row', deleteRow,
                        enabled: selectedRow != null && selectedRow! > 0),
                    _buildToolbarButton(Icons.delete, 'Delete Column', deleteColumn,
                        enabled: selectedCol != null && selectedCol! > 0),
                    _buildToolbarButton(Icons.undo, 'Undo', undo, enabled: canUndo),
                    _buildToolbarButton(Icons.redo, 'Redo', redo, enabled: canRedo),
                    const VerticalDivider(color: Colors.white54),
                  ],
                  _buildToolbarButton(Icons.content_copy, 'Copy', copySelection),
                  _buildToolbarButton(Icons.content_paste, 'Paste', pasteFromClipboard),
                  // _buildToolbarButton(Icons.bar_chart, 'Chart', _showGraph),
                  _buildToolbarButton(Icons.clear_all, 'Clear Selection', clearSelection),
                  if (selectedStart != null && selectedEnd != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        _getRangeText(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 3.0,
        boundaryMargin: const EdgeInsets.all(20),
        child: Container(
          color: Colors.grey[100],
          child: Scrollbar(
            controller: _verticalScroll,
            child: SingleChildScrollView(
              controller: _verticalScroll,
              scrollDirection: Axis.vertical,
              child: Scrollbar(
                controller: _horizontalScroll,
                child: SingleChildScrollView(
                  controller: _horizontalScroll,
                  scrollDirection: Axis.horizontal,
                  child: _buildTable(rows, columns),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: isSearching && searchResults.isNotEmpty
          ? Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'prev',
            mini: true,
            child: const Icon(Icons.arrow_upward),
            onPressed: () => _navigateSearch(-1),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'next',
            mini: true,
            child: const Icon(Icons.arrow_downward),
            onPressed: () => _navigateSearch(1),
          ),
        ],
      )
          : null,
    );
  }

  Widget _buildTable(int rows, int columns) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with column letters
          Row(
            children: [
              // Top-left corner cell
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  color: Colors.grey[200],
                ),
                child: const Center(
                  child: Text(''),
                ),
              ),
              // Column headers
              ...List.generate(columns, (col) {
                return GestureDetector(
                  onTap: () => setState(() {
                    selectedCol = col;
                    selectedStart = Offset(col.toDouble(), 0);
                    selectedEnd = Offset(col.toDouble(), rows - 1);
                  }),
                  child: Container(
                    width: 100,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      color: selectedCol == col ? Colors.blue[100] : Colors.grey[200],
                    ),
                    child: Center(
                      child: Text(
                        getColumnLabel(col),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          // Data rows
          ...List.generate(rows, (row) {
            return Row(
              children: [
                // Row header with row number
                GestureDetector(
                  onTap: () => setState(() {
                    selectedRow = row;
                    selectedStart = Offset(0, row.toDouble());
                    selectedEnd = Offset(columns - 1, row.toDouble());
                  }),
                  child: Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      color: selectedRow == row ? Colors.blue[100] : Colors.grey[200],
                    ),
                    child: Center(
                      child: Text(
                        (row + 1).toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                // Data cells
                ...List.generate(columns, (col) {
                  final isSelected = isCellInSelection(row, col);
                  final isSearchMatch = searchResults.contains(Offset(col.toDouble(), row.toDouble()));
                  final isCurrentMatch = currentSearchIndex != -1 &&
                      searchResults[currentSearchIndex] == Offset(col.toDouble(), row.toDouble());

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selectedStart == null) {
                          selectedStart = Offset(col.toDouble(), row.toDouble());
                          selectedEnd = Offset(col.toDouble(), row.toDouble());
                        } else {
                          selectedEnd = Offset(col.toDouble(), row.toDouble());
                        }
                      });
                    },
                    child: Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        color: isSelected
                            ? Colors.blue.withOpacity(0.2)
                            : isCurrentMatch
                            ? Colors.yellow
                            : isSearchMatch
                            ? Colors.yellow.withOpacity(0.5)
                            : Colors.white,
                      ),
                      child: editMode && widget.isAdmin
                          ? TextFormField(
                        initialValue: sheetData[row][col],
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onChanged: (value) => updateCell(row, col, value),
                      )
                          : Center(
                        child: Text(
                          sheetData[row][col],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String tooltip, VoidCallback onPressed, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon, size: 20),
          color: enabled ? Colors.white : Colors.white54,
          onPressed: enabled ? onPressed : null,
        ),
      ),
    );
  }

  String _getRangeText() {
    if (selectedStart == null || selectedEnd == null) return '';
    final startLabel = getColumnLabel(selectedStart!.dx.toInt()) + (selectedStart!.dy.toInt() + 1).toString();
    final endLabel = getColumnLabel(selectedEnd!.dx.toInt()) + (selectedEnd!.dy.toInt() + 1).toString();
    return startLabel == endLabel ? 'Selected: $startLabel' : 'Range: $startLabel : $endLabel';
  }

  @override
  void dispose() {
    _horizontalScroll.dispose();
    _verticalScroll.dispose();
    _focusNode.dispose();
    searchController.dispose();
    _transformationController.dispose();
    super.dispose();
  }
}

// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:vector_math/vector_math_64.dart' as vector;
//
//
//
//
// class MechanicalDpt extends StatelessWidget {
//   final bool isAdmin;
//   MechanicalDpt({required this.isAdmin});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'pro',
//       home: MechanicalDptSheet( isAdmin: isAdmin),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
//
// class MechanicalDptSheet extends StatefulWidget {
//   final bool isAdmin;
//   bool isclicked = false;
//
//   MechanicalDptSheet({super.key, required this.isAdmin});
//
//   @override
//   State<MechanicalDptSheet> createState() => _MechanicalDptSheetState();
// }
//
// class _MechanicalDptSheetState extends State<MechanicalDptSheet> {
//   List<List<String>> sheetData = [];
//   final String sheetKey = 'Mechanical_Sheet';
//   bool editMode = false;
//   bool isclicked = false;
//   OverlayEntry? entry;
//   Offset offset = Offset(20, 40);
//   int? selectedRow;
//   int? selectedCol;
//   Offset? selectedStart;
//   Offset? selectedEnd;
//   final TextEditingController searchController = TextEditingController();
//   List<Offset> searchResults = [];
//   int currentSearchIndex = -1;
//
//   // Zoom variables
//   // double _scale = 1.0;
//   vector.Matrix4 _matrix = vector.Matrix4.identity();
//
//   // Undo/Redo implementation
//   final List<List<List<String>>> _history = [];
//   final List<List<List<String>>> _redoStack = [];
//   final int _maxUndoSteps = 100;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadSavedSheet();
//   }
//
//   void _addToHistory(List<List<String>> data) {
//     if (_history.length >= _maxUndoSteps) {
//       _history.removeAt(0);
//     }
//     _history.add(_cloneSheet(data));
//     _redoStack.clear();
//   }
//
//   void undo() {
//     if (_history.length > 1) {
//       final current = _history.removeLast();
//       _redoStack.add(current);
//       setState(() {
//         sheetData = _cloneSheet(_history.last);
//       });
//     }
//   }
//
//   void redo() {
//     if (_redoStack.isNotEmpty) {
//       final redoData = _redoStack.removeLast();
//       _addToHistory(redoData);
//       setState(() {
//         sheetData = _cloneSheet(redoData);
//       });
//     }
//   }
//
//   bool get canUndo => _history.length > 1;
//   bool get canRedo => _redoStack.isNotEmpty;
//
//   Future<void> _loadSavedSheet() async {
//     final prefs = await SharedPreferences.getInstance();
//     final savedData = prefs.getString(sheetKey);
//     if (savedData != null) {
//       final List<dynamic> decoded = jsonDecode(savedData);
//       final data = decoded.map<List<String>>((row) => List<String>.from(row)).toList();
//       setState(() {
//         sheetData = data;
//         _addToHistory(_cloneSheet(data));
//       });
//     } else {
//       sheetData = [
//         ['S.NO', 'PROJECT', 'MATERIAL','FAILURE'],
//         ['A', '56', '45', '65'],
//         ['B', '56', '73', '99'],
//       ];
//       _addToHistory(_cloneSheet(sheetData));
//       setState(() {});
//     }
//   }
//
//   void updateSheet(List<List<String>> newData) {
//     _addToHistory(_cloneSheet(newData));
//     setState(() {
//       sheetData = _cloneSheet(newData);
//     });
//   }
//
//   List<List<String>> _cloneSheet(List<List<String>> original) {
//     return original.map((row) => List<String>.from(row)).toList();
//   }
//
//   Future<void> _saveSheet() async {
//     final prefs = await SharedPreferences.getInstance();
//     final encoded = jsonEncode(sheetData);
//     await prefs.setString(sheetKey, encoded); // Save using unique sheetKey
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Sheet saved successfully! ✅")),
//     );
//   }
//
//   Future<void> _saveToFile() async {
//     final status = await Permission.storage.request();
//     if (status.isGranted) {
//       final dir = await getExternalStorageDirectory();
//
//       // 🔑 Use unique filename per sheet
//       final basicfileName = "$sheetKey.json"; // sheetKey like "attendance", "expenses"
//       final filePath = "${dir!.path}/$basicfileName";
//
//       final file = File(filePath);
//       await file.writeAsString(jsonEncode(sheetData));
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("File saved: $basicfileName 📄")),
//       );
//     }
//   }
//
//   void addRow() {
//     final newData = _cloneSheet(sheetData);
//     newData.add(List.generate(sheetData[0].length, (_) => ''));
//     updateSheet(newData);
//   }
//
//   void addColumn() {
//     final newData = _cloneSheet(sheetData);
//     newData[0].add("New Column");
//     for (int i = 1; i < newData.length; i++) {
//       newData[i].add("");
//     }
//     updateSheet(newData);
//   }
//
//   void deleteRow() {
//     if (selectedRow != null && selectedRow! < sheetData.length) {
//       final newData = _cloneSheet(sheetData);
//       newData.removeAt(selectedRow!);
//       selectedRow = null;
//       updateSheet(newData);
//     }
//   }
//
//   void deleteColumn() {
//     if (selectedCol != null && selectedCol! < sheetData[0].length) {
//       final newData = _cloneSheet(sheetData);
//       for (var row in newData) {
//         row.removeAt(selectedCol!);
//       }
//       selectedCol = null;
//       updateSheet(newData);
//     }
//   }
//
//   void updateCell(int row, int col, String value) {
//     final newData = _cloneSheet(sheetData);
//     newData[row][col] = value;
//     updateSheet(newData);
//   }
//
//   String getColumnLabel(int index) {
//     String label = '';
//     while (index >= 0) {
//       label = String.fromCharCode((index % 26) + 65) + label;
//       index = (index ~/ 26) - 1;
//     }
//     return label;
//   }
//
//   String get selectedRangeText {
//     if (selectedStart == null || selectedEnd == null) return "\t No range selected";
//     final startLabel = getColumnLabel(selectedStart!.dx.toInt()) + (selectedStart!.dy.toInt() + 1).toString();
//     final endLabel = getColumnLabel(selectedEnd!.dx.toInt()) + (selectedEnd!.dy.toInt() + 1).toString();
//     return "\t Selected Range: $startLabel to $endLabel";
//   }
//
//   bool isCellInSelection(int row, int col) {
//     if (selectedStart == null || selectedEnd == null) return false;
//     int startRow = selectedStart!.dy.toInt();
//     int endRow = selectedEnd!.dy.toInt();
//     int startCol = selectedStart!.dx.toInt();
//     int endCol = selectedEnd!.dx.toInt();
//     if (startRow > endRow) {
//       final temp = startRow;
//       startRow = endRow;
//       endRow = temp;
//     }
//     if (startCol > endCol) {
//       final temp = startCol;
//       startCol = endCol;
//       endCol = temp;
//     }
//     return row >= startRow && row <= endRow && col >= startCol && col <= endCol;
//   }
//
//
//   List<List<String>> getSelectedRangeData() {
//     if (selectedStart == null || selectedEnd == null) return [];
//     int startRow = selectedStart!.dy.toInt();
//     int endRow = selectedEnd!.dy.toInt();
//     int startCol = selectedStart!.dx.toInt();
//     int endCol = selectedEnd!.dx.toInt();
//     if (startRow > endRow) {
//       final temp = startRow;
//       startRow = endRow;
//       endRow = temp;
//     }
//     if (startCol > endCol) {
//       final temp = startCol;
//       startCol = endCol;
//       endCol = temp;
//     }
//     return sheetData.sublist(startRow, endRow + 1).map((row) => row.sublist(startCol, endCol + 1)).toList();
//   }
//
//   void showGraph() {
//     final selectedData = getSelectedRangeData();
//     if (selectedData.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a range first")));
//       return;
//     }
//
//     showModalBottomSheet(
//       context: context,
//       builder: (_) => SizedBox(
//         height: 300,
//         child: Column(
//           children: [
//             ListTile(title: const Text("Pie Chart"), onTap: () => _showChart("pie", selectedData)),
//             ListTile(title: const Text("Bar Chart"), onTap: () => _showChart("bar", selectedData)),
//             ListTile(title: const Text("Line Chart"), onTap: () => _showChart("line", selectedData)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showChart(String type, List<List<String>> chartData) {
//     Navigator.pop(context);
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text("$type Chart Representation"),
//         content: SizedBox(
//           height: 300,
//           width: 300,
//           child: _buildChart(type, chartData),
//         ),
//         actions: [
//           // TextButton(
//           //   onPressed: () => Navigator.pop(context),
//           //   child: const Text("Close"),
//           // ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildChart(String type, List<List<String>> chartData) {
//     try {
//       if (chartData.isEmpty || chartData[0].isEmpty) {
//         return const Center(child: Text("No data available for chart"));
//       }
//
//       List<double> values = [];
//       for (int i = 0; i < chartData[0].length; i++) {
//         if (chartData.length > 1) {
//           values.add(double.tryParse(chartData[1][i]) ?? 0);
//         } else {
//           values.add(double.tryParse(chartData[0][i]) ?? 0);
//         }
//       }
//
//       List<String> labels = [];
//       for (int i = 0; i < chartData[0].length; i++) {
//         labels.add(chartData[0][i].isEmpty ? getColumnLabel(i) : chartData[0][i]);
//       }
//
//       switch (type) {
//         case "pie":
//           return PieChart(
//             PieChartData(
//               sections: List.generate(
//                 values.length,
//                     (i) => PieChartSectionData(
//                   value: values[i],
//                   title: labels[i],
//                   radius: 20,
//                   color: Colors.primaries[i % Colors.primaries.length],
//                 ),
//               ),
//             ),
//           );
//         case "bar":
//           return BarChart(
//             BarChartData(
//               barGroups: List.generate(
//                 values.length,
//                     (i) => BarChartGroupData(
//                   x: i,
//                   barRods: [
//                     BarChartRodData(
//                       toY: values[i],
//                       color: Colors.primaries[i % Colors.primaries.length],
//                       width: 16,
//                     )
//                   ],
//                 ),
//               ),
//               titlesData: FlTitlesData(
//                 bottomTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     getTitlesWidget: (value, meta) => Padding(
//                       padding: const EdgeInsets.only(top: 4.0),
//                       child: Text(
//                         labels[value.toInt()],
//                         style: const TextStyle(fontSize: 10),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         case "line":
//         default:
//           return LineChart(
//             LineChartData(
//               lineBarsData: [
//                 LineChartBarData(
//                   spots: List.generate(
//                     values.length,
//                         (i) => FlSpot(i.toDouble(), values[i]),
//                   ),
//                   isCurved: true,
//                   color: Colors.blue,
//                   dotData: const FlDotData(show: true),
//                   belowBarData: BarAreaData(show: true),
//                 )
//               ],
//               titlesData: FlTitlesData(
//                 bottomTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     getTitlesWidget: (value, meta) => Padding(
//                       padding: const EdgeInsets.only(top: 4.0),
//                       child: Text(
//                         labels[value.toInt()],
//                         style: const TextStyle(fontSize: 10),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//       }
//     } catch (e) {
//       return Center(child: Text("Error creating chart: $e"));
//     }
//   }
//
//   void _search(String query) {
//     if (query.isEmpty) {
//       setState(() {
//         searchResults.clear();
//         currentSearchIndex = -1;
//       });
//       return;
//     }
//
//     List<Offset> results = [];
//     for (int row = 0; row < sheetData.length; row++) {
//       for (int col = 0; col < sheetData[row].length; col++) {
//         if (sheetData[row][col].toLowerCase().contains(query.toLowerCase())) {
//           results.add(Offset(col.toDouble(), row.toDouble()));
//         }
//       }
//     }
//
//     setState(() {
//       searchResults = results;
//       currentSearchIndex = results.isNotEmpty ? 0 : -1;
//     });
//   }
//
//   void _navigateToSearchResult(int index) {
//     if (index < 0 || index >= searchResults.length) return;
//
//     setState(() {
//       currentSearchIndex = index;
//       selectedStart = searchResults[index];
//       selectedEnd = searchResults[index];
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     int rows = sheetData.length;
//     int columns = sheetData[0].length;
//
//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(
//           leading: IconButton(onPressed: (){
//             Navigator.pop(context);
//           }, icon: Icon(Icons.arrow_back),color: Colors.white,),
//           elevation: 0,
//           backgroundColor: Colors.green,
//           centerTitle: true,
//           actions: [IconButton(onPressed: (){
//             setState(() {
//               isclicked = !isclicked;
//               if(!isclicked){
//                 searchController.clear();
//               }
//             });
//           }, icon: Icon(Icons.search,color: Colors.white,))],
//           title: isclicked? Container(
//             height: 60,
//             decoration: BoxDecoration(borderRadius: BorderRadius.circular(35),color: Colors.white),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: searchController,
//                     decoration: InputDecoration(
//                       hintText: 'Search...',
//                       prefixIcon: const Icon(Icons.search),
//                       // suffixIcon: searchController.text.isNotEmpty
//                       //     ? IconButton(
//                       //   icon: const Icon(Icons.clear),
//                       //   onPressed: () {
//                       //     searchController.clear();
//                       //     _search('');
//                       //   },
//                       // )
//                       //     : null,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8.0),
//                       ),
//                     ),
//                     onChanged: _search,
//                   ),
//                 ),
//                 if (searchResults.isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.only(left: 0),
//                     child: Text(
//                       '${currentSearchIndex + 1}/${searchResults.length}',
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                   ),
//                 if (searchResults.isNotEmpty)
//                   IconButton(
//                     icon: const Icon(Icons.arrow_upward),
//                     onPressed: () => _navigateToSearchResult((currentSearchIndex - 1) % searchResults.length),
//                   ),
//                 if (searchResults.isNotEmpty)
//                   IconButton(
//                     icon: const Icon(Icons.arrow_downward),
//                     onPressed: () => _navigateToSearchResult((currentSearchIndex + 1) % searchResults.length),
//                   ),
//               ],
//             ),
//           )
//               : Text("Cost Sheet" , style: TextStyle(fontSize: 26,color: Colors.white, fontWeight: FontWeight.bold),
//           ),// Increased height to accommodate two rows
//         ),
//         body:  SafeArea(
//           child: Column(
//             children: [
//               // Action buttons container below AppBar
//               Container(
//                 color: Colors.green,
//                 padding: const EdgeInsets.symmetric(vertical: 0),
//                 child: Column(
//                   children: [
//                     // First row of buttons
//                     SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: <Widget>[
//                           if (widget.isAdmin && editMode) ...[
//                             IconButton(icon: const Icon(Icons.add_box), tooltip: "Add Row", onPressed: addRow,color: Colors.white,),
//                             IconButton(icon: const Icon(Icons.view_column), tooltip: "Add Column", onPressed: addColumn,color: Colors.white,),
//                             IconButton(icon: const Icon(Icons.delete_sweep), tooltip: "Delete Row", onPressed: deleteRow,color: Colors.white,),
//                             IconButton(icon: const Icon(Icons.delete), tooltip: "Delete Column", onPressed: deleteColumn,color: Colors.white,),
//                             IconButton(icon: const Icon(Icons.save), tooltip: "Save Sheet", onPressed: _saveSheet,color: Colors.white,),
//                             IconButton(
//                               icon: const Icon(Icons.undo),
//                               tooltip: "Undo",
//                               onPressed: canUndo ? undo : null,
//                               color: canUndo ? Colors.white : Colors.white.withOpacity(0.5),
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.redo),
//                               tooltip: "Redo",
//                               onPressed: canRedo ? redo : null,
//                               color: canRedo ? Colors.white : Colors.white.withOpacity(0.5),
//                             ),
//                             IconButton(icon: const Icon(Icons.file_copy), tooltip: "Save as File", onPressed: _saveToFile,color: Colors.white,),
//                           ],
//                           Text( selectedRangeText , style: TextStyle(fontSize: 19,color: Colors.white),),
//                           IconButton(
//                             onPressed: () => setState(() {
//                               selectedStart = null;
//                               selectedEnd = null;
//                             }),
//                             icon: const Icon(Icons.clear, color: Colors.white),
//                             tooltip: "Clear Selection",
//                           ),
//                           IconButton(icon: const Icon(Icons.bar_chart), tooltip: "Show Graph", onPressed: showGraph,color: Colors.white,),
//
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: GestureDetector(
//                   onScaleStart: (details) {
//                     // Handle scale start if needed
//                   },
//                   child: InteractiveViewer(
//                     panEnabled: false, // Enables drag
//                     scaleEnabled: true, // Enables pinch zoom
//                     minScale: 1.0,
//                     maxScale: 7.0,
//                     boundaryMargin: const EdgeInsets.all(20),
//                     child:Transform(
//                       transform: _matrix,
//                       child: SingleChildScrollView(
//                         scrollDirection: Axis.horizontal,
//                         child: SingleChildScrollView(
//                           scrollDirection: Axis.vertical,
//                           child: Center(
//                             child: Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Table(
//                                 defaultColumnWidth: IntrinsicColumnWidth(),
//                                 border: TableBorder.all(color: Colors.black),
//                                 children: [
//                                   TableRow(children: [
//                                     const SizedBox(),
//                                     ...List.generate(columns, (col) {
//                                       return GestureDetector(
//                                         onTap: () => setState(() {
//                                           selectedCol = col;
//                                           selectedStart = Offset(col.toDouble(), 0);
//                                           selectedEnd = Offset(col.toDouble(), rows.toDouble() - 1);
//                                         }),
//                                         onLongPress: () => setState(() {
//                                           selectedCol = col;
//                                           selectedStart = Offset(col.toDouble(), 0);
//                                           selectedEnd = Offset(col.toDouble(), rows.toDouble() - 1);
//                                         }),
//                                         child: Container(
//                                           color: Colors.grey[300],
//                                           padding: const EdgeInsets.all(8),
//                                           alignment: Alignment.center,
//                                           child: Text(getColumnLabel(col), style: const TextStyle(fontWeight: FontWeight.bold)),
//                                         ),
//                                       );
//                                     })
//                                   ]),
//                                   ...List.generate(rows, (row) {
//                                     return TableRow(children: [
//                                       GestureDetector(
//                                         onTap: () => setState(() {
//                                           selectedRow = row;
//                                           selectedStart = Offset(0, row.toDouble());
//                                           selectedEnd = Offset(columns.toDouble() - 1, row.toDouble());
//                                         }),
//                                         onLongPress: () => setState(() {
//                                           selectedRow = row;
//                                           selectedStart = Offset(0, row.toDouble());
//                                           selectedEnd = Offset(columns.toDouble() - 1, row.toDouble());
//                                         }),
//                                         child: Container(
//                                           color: Colors.grey[300],
//                                           padding: const EdgeInsets.all(8),
//                                           alignment: Alignment.center,
//                                           child: Text((row + 1).toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
//                                         ),
//                                       ),
//                                       ...List.generate(columns, (col) {
//                                         bool isSearchResult = searchResults.contains(Offset(col.toDouble(), row.toDouble()));
//                                         bool isCurrentSearchResult = currentSearchIndex != -1 &&
//                                             searchResults[currentSearchIndex] == Offset(col.toDouble(), row.toDouble());
//
//                                         return GestureDetector(
//                                           onTap: () {
//                                             if (selectedStart == null) {
//                                               setState(() {
//                                                 selectedStart = Offset(col.toDouble(), row.toDouble());
//                                                 selectedEnd = Offset(col.toDouble(), row.toDouble());
//                                               });
//                                             } else {
//                                               setState(() {
//                                                 selectedEnd = Offset(col.toDouble(), row.toDouble());
//                                               });
//                                             }
//                                           },
//                                           onLongPressStart: (details) {
//                                             setState(() {
//                                               selectedStart = Offset(col.toDouble(), row.toDouble());
//                                               selectedEnd = Offset(col.toDouble(), row.toDouble());
//                                             });
//                                           },
//                                           onLongPressMoveUpdate: (details) {
//                                             final localPosition = details.localPosition;
//                                             final row = (localPosition.dy / 50).floor();
//                                             final col = (localPosition.dx / 100).floor();
//                                             if (col >= 0 && col < columns && row >= 0 && row < rows) {
//                                               setState(() {
//                                                 selectedEnd = Offset(col.toDouble(), row.toDouble());
//                                               });
//                                             }
//                                           },
//                                           child: Container(
//                                             color: isCellInSelection(row, col)
//                                                 ? Colors.blue.withOpacity(0.3)
//                                                 : isCurrentSearchResult
//                                                 ? Colors.yellow
//                                                 : isSearchResult
//                                                 ? Colors.yellow.withOpacity(0.5)
//                                                 : Colors.transparent,
//                                             child: Padding(
//                                               padding: const EdgeInsets.all(4),
//                                               child: widget.isAdmin && editMode
//                                                   ? TextFormField(
//                                                 initialValue: sheetData[row][col],
//                                                 textAlign: TextAlign.center,
//                                                 decoration: const InputDecoration(isDense: true, border: InputBorder.none),
//                                                 onChanged: (val) => updateCell(row, col, val),
//                                               )
//                                                   : Center(child: Text(sheetData[row][col])),
//                                             ),
//                                           ),
//                                         );
//                                       }),
//                                     ]);
//                                   })
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         floatingActionButton: widget.isAdmin
//             ? FloatingActionButton(
//           onPressed: () => setState(() => editMode = !editMode),
//           child: Icon(editMode ? Icons.lock_open : Icons.lock),
//           tooltip: "Toggle Edit Mode",
//         )
//             : null,
//       ),
//     );
//   }
// }
//
//
//
