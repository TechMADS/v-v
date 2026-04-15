// reliabilitysheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Colors/Appbar.dart';

// ─────────────────────────────────────────────
// TOP-LEVEL ENTRY
// ─────────────────────────────────────────────

class ReliabilitySheetPage extends StatelessWidget {
  final bool isAdmin;
  const ReliabilitySheetPage({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return SpreadsheetHomePage(isAdmin: isAdmin);
  }
}

// ─────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────

class SpreadsheetFile {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime lastModified;
  List<List<String>> data;

  /// key = "row,col"  →  absolute file path of the captured image
  Map<String, String> cellImages;

  SpreadsheetFile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastModified,
    required this.data,
    Map<String, String>? cellImages,
  }) : cellImages = cellImages ?? {};

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'lastModified': lastModified.toIso8601String(),
    'data': data,
    'cellImages': cellImages,
  };

  factory SpreadsheetFile.fromJson(Map<String, dynamic> json) =>
      SpreadsheetFile(
        id: json['id'],
        name: json['name'],
        createdAt: DateTime.parse(json['createdAt']),
        lastModified: DateTime.parse(json['lastModified']),
        data: List<List<String>>.from(
            json['data'].map((row) => List<String>.from(row))),
        cellImages: json['cellImages'] != null
            ? Map<String, String>.from(json['cellImages'])
            : {},
      );
}

// ─────────────────────────────────────────────
// HOME PAGE  (list of sheets)
// ─────────────────────────────────────────────

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
    final filesJson = prefs.getString('ReliabilitySheet');
    if (filesJson != null && filesJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(filesJson);
      savedFiles = decoded.map((j) => SpreadsheetFile.fromJson(j)).toList();
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _saveAllSheets() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(savedFiles.map((f) => f.toJson()).toList());
    await prefs.setString('ReliabilitySheet', encoded);
  }

  List<List<String>> _getDefaultSheetData() => [
    ['S.NO', 'PROJECT', 'MATERIAL', 'FAILURE', 'STATUS'],
    ['1', 'Project A', 'Steel', '45', 'Active'],
    ['2', 'Project B', 'Aluminum', '73', 'Active'],
    ['3', 'Project C', 'Copper', '99', 'Completed'],
    ['4', 'Project D', 'Steel', '23', 'Pending'],
    ['5', 'Project E', 'Aluminum', '67', 'Active'],
  ];

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
            builder: (_) => ProfessionalSpreadsheet(
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
    final result = await showDialog<String>(
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
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Create')),
        ],
      ),
    );
    controller.dispose();
    return result;
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
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => savedFiles.removeWhere((f) => f.id == file.id));
      await _saveAllSheets();
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year} '
          '${date.hour}:${date.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: appbarwidget(),
        centerTitle: true,
        title: const Text('Reliability Department Spreadsheets'),
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
            Icon(Icons.table_chart,
                size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No spreadsheets yet',
                style: TextStyle(
                    fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Tap + to create your first spreadsheet',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey[500])),
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
                child: const Icon(Icons.table_chart,
                    color: Colors.blue),
              ),
              title: Text(file.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Last modified: ${_formatDate(file.lastModified)}',
                  style: const TextStyle(fontSize: 12)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit,
                        color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfessionalSpreadsheet(
                            isAdmin: widget.isAdmin,
                            spreadsheetFile: file,
                            onSave: _saveAllSheets,
                          ),
                        ),
                      ).then((_) => _loadAllSheets());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        color: Colors.red),
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
        tooltip: 'New Spreadsheet',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SPREADSHEET PAGE
// ─────────────────────────────────────────────

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
  State<ProfessionalSpreadsheet> createState() =>
      _ProfessionalSpreadsheetState();
}

class _ProfessionalSpreadsheetState extends State<ProfessionalSpreadsheet> {
  late List<List<String>> sheetData;
  late List<List<List<String>>> _history;
  late List<List<List<String>>> _redoStack;
  final int _maxUndoSteps = 50;

  late Map<String, String> _cellImages;

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

  double _zoomLevel = 1.0;
  final TransformationController _transformationController =
  TransformationController();
  final FocusNode _focusNode = FocusNode();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    sheetData = _cloneSheet(widget.spreadsheetFile.data);
    _cellImages = Map<String, String>.from(widget.spreadsheetFile.cellImages);
    _initHistory();
  }

  // ── history ──────────────────────────────

  void _initHistory() {
    _history = [_cloneSheet(sheetData)];
    _redoStack = [];
  }

  void _addToHistory() {
    if (_history.length >= _maxUndoSteps) _history.removeAt(0);
    _history.add(_cloneSheet(sheetData));
    _redoStack.clear();
  }

  void undo() {
    if (_history.length > 1) {
      final current = _history.removeLast();
      _redoStack.add(current);
      setState(() => sheetData = _cloneSheet(_history.last));
      _autoSave();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      final redoData = _redoStack.removeLast();
      _addToHistory();
      setState(() => sheetData = _cloneSheet(redoData));
      _autoSave();
    }
  }

  bool get canUndo => _history.length > 1;
  bool get canRedo => _redoStack.isNotEmpty;

  List<List<String>> _cloneSheet(List<List<String>> src) =>
      src.map((r) => List<String>.from(r)).toList();

  // ── save ─────────────────────────────────

  void _autoSave() {
    widget.spreadsheetFile.data = _cloneSheet(sheetData);
    widget.spreadsheetFile.cellImages = Map<String, String>.from(_cellImages);
    widget.spreadsheetFile.lastModified = DateTime.now();
    widget.onSave();
  }

  // ── cell operations ───────────────────────

  void updateCell(int row, int col, String value) {
    setState(() => sheetData[row][col] = value);
    _autoSave();
  }

  void addRow() {
    setState(() {
      sheetData.add(List.generate(sheetData[0].length, (_) => ''));
      _addToHistory();
    });
    _autoSave();
    _showSnackBar('Row added');
  }

  void addColumn() {
    setState(() {
      final name = 'Column ${_getColumnLabel(sheetData[0].length)}';
      for (int i = 0; i < sheetData.length; i++) {
        sheetData[i].add(i == 0 ? name : '');
      }
      _addToHistory();
    });
    _autoSave();
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
    if (selectedRow != null &&
        selectedRow! < sheetData.length &&
        selectedRow! > 0) {
      final newImages = <String, String>{};
      _cellImages.forEach((key, path) {
        final parts = key.split(',');
        final r = int.parse(parts[0]);
        final c = int.parse(parts[1]);
        if (r == selectedRow) return;
        if (r > selectedRow!) {
          newImages['${r - 1},$c'] = path;
        } else {
          newImages[key] = path;
        }
      });
      setState(() {
        sheetData.removeAt(selectedRow!);
        _cellImages = newImages;
        selectedRow = null;
        _addToHistory();
      });
      _autoSave();
      _showSnackBar('Row deleted');
    } else {
      _showSnackBar('Please select a valid row to delete');
    }
  }

  void deleteColumn() {
    if (selectedCol != null &&
        selectedCol! < sheetData[0].length &&
        selectedCol! > 0) {
      final newImages = <String, String>{};
      _cellImages.forEach((key, path) {
        final parts = key.split(',');
        final r = int.parse(parts[0]);
        final c = int.parse(parts[1]);
        if (c == selectedCol) return;
        if (c > selectedCol!) {
          newImages['$r,${c - 1}'] = path;
        } else {
          newImages[key] = path;
        }
      });
      setState(() {
        for (var row in sheetData) {
          row.removeAt(selectedCol!);
        }
        _cellImages = newImages;
        selectedCol = null;
        _addToHistory();
      });
      _autoSave();
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

  // ── camera / image ────────────────────────

  String _cellKey(int row, int col) => '$row,$col';

  Future<void> _showImageOptions(int row, int col) async {
    final key = _cellKey(row, col);
    final hasImage =
        _cellImages.containsKey(key) && _cellImages[key]!.isNotEmpty;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Cell Image — Row ${row + 1}, Col ${_getColumnLabel(col)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Capture with Camera'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImage(row, col, ImageSource.camera);
              },
            ),
            ListTile(
              leading:
              const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImage(row, col, ImageSource.gallery);
              },
            ),
            if (hasImage) ...[
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading:
                const Icon(Icons.visibility, color: Colors.orange),
                title: const Text('View Captured Image'),
                onTap: () {
                  Navigator.pop(ctx);
                  _viewImage(row, col);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Image'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _cellImages.remove(key));
                  _autoSave();
                  _showSnackBar('Image removed');
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(int row, int col, ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (picked == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'reliability_${widget.spreadsheetFile.id}_${row}_${col}_'
          '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destPath = '${dir.path}/$fileName';
      await File(picked.path).copy(destPath);

      if (mounted) {
        setState(() => _cellImages[_cellKey(row, col)] = destPath);
        _autoSave();
        _showSnackBar(
            'Image saved for cell ${_getColumnLabel(col)}${row + 1}');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e');
    }
  }

  void _viewImage(int row, int col) {
    final path = _cellImages[_cellKey(row, col)];
    if (path == null || path.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImageViewPage(
          imagePath: path,
          title: 'Image — Row ${row + 1}, Col ${_getColumnLabel(col)}',
          cellLabel: sheetData[row][col].isNotEmpty
              ? sheetData[row][col]
              : '(empty cell)',
        ),
      ),
    );
  }

  // ── search ────────────────────────────────

  void _search(String query) {
    if (query.isEmpty) {
      setState(() {
        searchResults.clear();
        currentSearchIndex = -1;
      });
      return;
    }
    final results = <Offset>[];
    for (int r = 0; r < sheetData.length; r++) {
      for (int c = 0; c < sheetData[r].length; c++) {
        if (sheetData[r][c].toLowerCase().contains(query.toLowerCase())) {
          results.add(Offset(c.toDouble(), r.toDouble()));
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
    currentSearchIndex =
        (currentSearchIndex + direction) % searchResults.length;
    if (currentSearchIndex < 0)
      currentSearchIndex = searchResults.length - 1;
    setState(() {
      selectedStart = searchResults[currentSearchIndex];
      selectedEnd = searchResults[currentSearchIndex];
      _scrollToCell(
          selectedStart!.dy.toInt(), selectedStart!.dx.toInt());
    });
  }

  void _scrollToCell(int row, int col) {
    _horizontalScroll.animateTo(col * 100.0 * _zoomLevel,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
    _verticalScroll.animateTo(row * 40.0 * _zoomLevel,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
  }

  // ── selection ─────────────────────────────

  bool isCellInSelection(int row, int col) {
    if (selectedStart == null || selectedEnd == null) return false;
    int r0 = selectedStart!.dy.toInt(), r1 = selectedEnd!.dy.toInt();
    int c0 = selectedStart!.dx.toInt(), c1 = selectedEnd!.dx.toInt();
    if (r0 > r1) {
      final t = r0;
      r0 = r1;
      r1 = t;
    }
    if (c0 > c1) {
      final t = c0;
      c0 = c1;
      c1 = t;
    }
    return row >= r0 && row <= r1 && col >= c0 && col <= c1;
  }

  List<List<String>> getSelectedRangeData() {
    if (selectedStart == null || selectedEnd == null) return [];
    int r0 = selectedStart!.dy.toInt(), r1 = selectedEnd!.dy.toInt();
    int c0 = selectedStart!.dx.toInt(), c1 = selectedEnd!.dx.toInt();
    if (r0 > r1) {
      final t = r0;
      r0 = r1;
      r1 = t;
    }
    if (c0 > c1) {
      final t = c0;
      c0 = c1;
      c1 = t;
    }
    r0 = r0.clamp(0, sheetData.length - 1);
    r1 = r1.clamp(0, sheetData.length - 1);
    c0 = c0.clamp(0, sheetData[0].length - 1);
    c1 = c1.clamp(0, sheetData[0].length - 1);
    return sheetData
        .sublist(r0, r1 + 1)
        .map((row) => row.sublist(c0, c1 + 1))
        .toList();
  }

  void copySelection() {
    final data = getSelectedRangeData();
    if (data.isEmpty) {
      _showSnackBar('No range selected');
      return;
    }
    Clipboard.setData(
        ClipboardData(text: data.map((r) => r.join('\t')).join('\n')));
    _showSnackBar('Copied ${data.length} row(s)');
  }

  Future<void> pasteFromClipboard() async {
    final clip = await Clipboard.getData('text/plain');
    if (clip == null || clip.text == null) {
      _showSnackBar('Clipboard is empty');
      return;
    }
    if (selectedStart == null) {
      _showSnackBar('No range selected');
      return;
    }
    final rows = clip.text!.split('\n');
    final sr = selectedStart!.dy.toInt();
    final sc = selectedStart!.dx.toInt();
    setState(() {
      for (int i = 0;
      i < rows.length && sr + i < sheetData.length;
      i++) {
        final cells = rows[i].split('\t');
        for (int j = 0;
        j < cells.length && sc + j < sheetData[0].length;
        j++) {
          sheetData[sr + i][sc + j] = cells[j];
        }
      }
      _addToHistory();
    });
    _autoSave();
    _showSnackBar('Pasted successfully');
  }

  // ── zoom ──────────────────────────────────

  void _zoomIn() => setState(() {
    _zoomLevel = (_zoomLevel + 0.1).clamp(0.5, 3.0);
    _transformationController.value =
        Matrix4.diagonal3Values(_zoomLevel, _zoomLevel, 1.0);
  });

  void _zoomOut() => setState(() {
    _zoomLevel = (_zoomLevel - 0.1).clamp(0.5, 3.0);
    _transformationController.value =
        Matrix4.diagonal3Values(_zoomLevel, _zoomLevel, 1.0);
  });

  void _resetZoom() => setState(() {
    _zoomLevel = 1.0;
    _transformationController.value = Matrix4.identity();
  });

  // ── misc ──────────────────────────────────

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _getRangeText() {
    if (selectedStart == null || selectedEnd == null) return '';
    final s = _getColumnLabel(selectedStart!.dx.toInt()) +
        (selectedStart!.dy.toInt() + 1).toString();
    final e = _getColumnLabel(selectedEnd!.dx.toInt()) +
        (selectedEnd!.dy.toInt() + 1).toString();
    return s == e ? 'Selected: $s' : 'Range: $s : $e';
  }

  // ── build ─────────────────────────────────

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
        actions: isSearching
            ? [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() {
              isSearching = false;
              searchController.clear();
              searchResults.clear();
              currentSearchIndex = -1;
            }),
          )
        ]
            : [
          IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: _zoomIn,
              tooltip: 'Zoom In'),
          IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: _zoomOut,
              tooltip: 'Zoom Out'),
          IconButton(
              icon: const Icon(Icons.center_focus_strong),
              onPressed: _resetZoom,
              tooltip: 'Reset Zoom'),
          IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => isSearching = true)),
          if (widget.isAdmin)
            IconButton(
              icon: Icon(editMode ? Icons.edit_off : Icons.edit),
              onPressed: () =>
                  setState(() => editMode = !editMode),
              tooltip:
              editMode ? 'Exit Edit Mode' : 'Enter Edit Mode',
            ),
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
                    _toolbarBtn(Icons.add_box, 'Add Row', addRow),
                    _toolbarBtn(
                        Icons.view_column, 'Add Col', addColumn),
                    _toolbarBtn(Icons.delete_sweep, 'Del Row', deleteRow,
                        enabled:
                        selectedRow != null && selectedRow! > 0),
                    _toolbarBtn(Icons.delete, 'Del Col', deleteColumn,
                        enabled:
                        selectedCol != null && selectedCol! > 0),
                    _toolbarBtn(Icons.undo, 'Undo', undo,
                        enabled: canUndo),
                    _toolbarBtn(Icons.redo, 'Redo', redo,
                        enabled: canRedo),
                    const VerticalDivider(color: Colors.white54),
                  ],
                  _toolbarBtn(
                      Icons.content_copy, 'Copy', copySelection),
                  _toolbarBtn(Icons.content_paste, 'Paste',
                      pasteFromClipboard),
                  _toolbarBtn(
                      Icons.clear_all, 'Clear', clearSelection),
                  if (selectedStart != null && selectedEnd != null)
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(_getRangeText(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
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
            onPressed: () => _navigateSearch(-1),
            child: const Icon(Icons.arrow_upward),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'next',
            mini: true,
            onPressed: () => _navigateSearch(1),
            child: const Icon(Icons.arrow_downward),
          ),
        ],
      )
          : null,
    );
  }

  // ── table builder ─────────────────────────

  Widget _buildTable(int rows, int columns) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _cornerCell(),
              ...List.generate(columns, (col) => _columnHeader(col, rows)),
            ],
          ),
          ...List.generate(rows, (row) => _buildRow(row, columns)),
        ],
      ),
    );
  }

  Widget _cornerCell() => Container(
    width: 60,
    height: 40,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[400]!),
      color: Colors.grey[200],
    ),
  );

  Widget _columnHeader(int col, int totalRows) => GestureDetector(
    onTap: () => setState(() {
      selectedCol = col;
      selectedStart = Offset(col.toDouble(), 0);
      selectedEnd = Offset(col.toDouble(), totalRows - 1);
    }),
    child: Container(
      width: 100,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        color:
        selectedCol == col ? Colors.blue[100] : Colors.grey[200],
      ),
      child: Center(
        child: Text(_getColumnLabel(col),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    ),
  );

  Widget _buildRow(int row, int columns) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() {
            selectedRow = row;
            selectedStart = Offset(0, row.toDouble());
            selectedEnd = Offset(columns - 1, row.toDouble());
          }),
          child: Container(
            width: 60,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              color: selectedRow == row
                  ? Colors.blue[100]
                  : Colors.grey[200],
            ),
            child: Center(
              child: Text('${row + 1}',
                  style:
                  const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        ...List.generate(columns, (col) => _buildCell(row, col)),
      ],
    );
  }

  Widget _buildCell(int row, int col) {
    final isSelected = isCellInSelection(row, col);
    final key = _cellKey(row, col);
    final hasImage =
        _cellImages.containsKey(key) && _cellImages[key]!.isNotEmpty;
    final isSearchMatch =
    searchResults.contains(Offset(col.toDouble(), row.toDouble()));
    final isCurrentMatch = currentSearchIndex != -1 &&
        searchResults[currentSearchIndex] ==
            Offset(col.toDouble(), row.toDouble());

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
      onLongPress: () => _showImageOptions(row, col),
      child: Container(
        width: 100,
        height: 50,
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
        child: Stack(
          children: [
            Center(
              child: editMode && widget.isAdmin
                  ? TextFormField(
                initialValue: sheetData[row][col],
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 8),
                ),
                onChanged: (v) => updateCell(row, col, v),
              )
                  : Text(
                sheetData[row][col],
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasImage)
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => _viewImage(row, col),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 12, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarBtn(
      IconData icon,
      String tooltip,
      VoidCallback onPressed, {
        bool enabled = true,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon, size: 20),
          color: enabled ? Colors.white : Colors.white38,
          onPressed: enabled ? onPressed : null,
        ),
      ),
    );
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

// ─────────────────────────────────────────────
// FULL-SCREEN IMAGE VIEWER
// ─────────────────────────────────────────────

class _ImageViewPage extends StatelessWidget {
  final String imagePath;
  final String title;
  final String cellLabel;

  const _ImageViewPage({
    required this.imagePath,
    required this.title,
    required this.cellLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14)),
            if (cellLabel.isNotEmpty)
              Text(cellLabel,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Add share_plus package to enable sharing')),
              );
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image,
                      color: Colors.white54, size: 80),
                  SizedBox(height: 12),
                  Text('Image not found',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}