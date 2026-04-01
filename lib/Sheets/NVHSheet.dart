import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Colors/Appbar.dart';

class NVH_Sheet extends StatelessWidget {
  final bool isAdmin;
  const NVH_Sheet({super.key, required this.isAdmin});

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
    final filesJson = prefs.getString('NVH_Sheet');

    if (filesJson != null && filesJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(filesJson);
      savedFiles = decoded.map((json) => SpreadsheetFile.fromJson(json)).toList();
    }

    setState(() => isLoading = false);
  }

  Future<void> _saveAllSheets() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(savedFiles.map((f) => f.toJson()).toList());
    await prefs.setString('NVH_Sheet', encoded);
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
        title: const Text('NVH Department Spreadsheets'),
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