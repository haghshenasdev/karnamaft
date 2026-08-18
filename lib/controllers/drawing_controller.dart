import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karnamaft/services/note_autosave_service.dart';

import '../models/note_page.dart';
import '../models/stroke.dart';

class DrawingController extends ChangeNotifier {
  final List<NotePage> pages = [NotePage()];

  bool _writingMode = false;

  bool get writingMode => _writingMode;

  final NoteAutoSaveService _autoSaveService = NoteAutoSaveService();

  Timer? _autoSaveTimer;

  String? _noteId;

  String _title = '';

  bool _isAutoSaving = false;

  bool get isAutoSaving => _isAutoSaving;

  bool get hasAutoSave => _noteId != null;

  String get title => _title;

  bool _autoSaveSaved = false;

  bool get autoSaveSaved => _autoSaveSaved;

  //--------------------------------------------------
  // Page
  //--------------------------------------------------

  int currentPage = 0;

  int get pageCount => pages.length;

  List<StrokeModel> get strokes => pages[currentPage].strokes;

  bool get canPrevious => currentPage > 0;

  bool get canNext => true;

  //--------------------------------------------------
  // Text
  //--------------------------------------------------

  //--------------------------------------------------
  // Text
  //--------------------------------------------------

  final TextEditingController noteController = TextEditingController();

  /// ذخیره متن فعلی در صفحه فعلی
  void saveCurrentPageText() {
    pages[currentPage].text = noteController.text;
  }

  /// بارگذاری متن صفحه فعلی
  void loadCurrentPageText() {
    final text = pages[currentPage].text;

    noteController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// ذخیره مستقیم متن یک صفحه
  void savePageText(String value) {
    pages[currentPage].text = value;

    requestAutoSave();
  }
  //--------------------------------------------------
  // Writing Mode
  //--------------------------------------------------

  Future<void> toggleWritingMode() async {
    _writingMode = !_writingMode;

    if (_writingMode) {
      _textMode = false;
      selectedTool = ToolType.pen;

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    notifyListeners();
  }

  //--------------------------------------------------
  // Drawing / Text Mode
  //--------------------------------------------------

  bool _textMode = false;

  bool get textMode => _textMode;

  void setTextMode(bool value) {
    if (_textMode == value) {
      return;
    }

    _textMode = value;

    notifyListeners();
  }

  void enableDrawingMode() {
    if (!_textMode) {
      return;
    }

    _textMode = false;

    notifyListeners();
  }

  void enableTextMode() {
    if (_textMode) {
      return;
    }

    _textMode = true;

    notifyListeners();
  }

  //--------------------------------------------------
  // Pen
  //--------------------------------------------------

  final List<StrokeModel> redoStack = [];

  Color penColor = Colors.black;

  double penWidth = 3;

  StrokeModel? currentStroke;

  ToolType selectedTool = ToolType.pen;

  void setTool(ToolType tool) {
    selectedTool = tool;
    notifyListeners();
  }

  void setColor(Color color) {
    penColor = color;
    notifyListeners();
  }

  void setWidth(double width) {
    penWidth = width;
    notifyListeners();
  }

  //--------------------------------------------------
  // Drawing
  //--------------------------------------------------

  void start(Offset point) {
    if (_textMode) return;

    currentStroke = StrokeModel(
      points: [point],
      color: penColor,
      width: penWidth,
      type: switch (selectedTool) {
        ToolType.pen => StrokeType.pen,
        ToolType.highlighter => StrokeType.highlighter,
        ToolType.eraser => StrokeType.eraser,
      },
    );

    strokes.add(currentStroke!);

    notifyListeners();
  }

  void update(Offset point) {
    if (_textMode) return;
    if (currentStroke == null) return;

    final points = currentStroke!.points;

    if (points.isNotEmpty) {
      if ((points.last - point).distance < 2.5) {
        return;
      }
    }

    points.add(point);

    notifyListeners();
  }

  void end() {
    if (_textMode) return;

    currentStroke = null;

    redoStack.clear();

    requestAutoSave();

    notifyListeners();
  }

  //--------------------------------------------------
  // Pages
  //--------------------------------------------------

  void previousPage() {
    if (!canPrevious) {
      return;
    }

    goToPage(currentPage - 1);
  }

  void nextPage() {
    saveCurrentPageText();

    if (currentPage == pages.length - 1) {
      pages.add(NotePage());
    }

    currentPage++;

    loadCurrentPageText();

    redoStack.clear();

    requestAutoSave();

    notifyListeners();
  }

  //--------------------------------------------------
  // Undo / Redo
  //--------------------------------------------------

  bool get canUndo => strokes.isNotEmpty;

  bool get canRedo => redoStack.isNotEmpty;

  void undo() {
    if (strokes.isEmpty) {
      return;
    }

    redoStack.add(strokes.removeLast());

    notifyListeners();
  }

  void redo() {
    if (redoStack.isEmpty) {
      return;
    }

    strokes.add(redoStack.removeLast());

    notifyListeners();
  }

  //--------------------------------------------------
  // Clear
  //--------------------------------------------------

  void clear() {
    strokes.clear();

    pages[currentPage].text = '';

    noteController.clear();

    redoStack.clear();

    requestAutoSave();

    notifyListeners();
  }

  //--------------------------------------------------
  // Delete Page
  //--------------------------------------------------

  void removeCurrentPage() {
    // اگر فقط یک صفحه داریم،
    // خود صفحه حذف نمی‌شود؛ فقط محتوایش پاک می‌شود.
    if (pages.length == 1) {
      clear();
      return;
    }

    pages.removeAt(currentPage);

    if (currentPage >= pages.length) {
      currentPage = pages.length - 1;
    }

    loadCurrentPageText();

    redoStack.clear();

    notifyListeners();
  }

  //--------------------------------------------------
  // Dispose
  //--------------------------------------------------

  @override
  void dispose() {
    _autoSaveTimer?.cancel();

    noteController.dispose();

    super.dispose();
  }

  void goToPage(int index) {
    if (index < 0 || index >= pages.length) {
      return;
    }

    if (index == currentPage) {
      return;
    }

    saveCurrentPageText();

    currentPage = index;

    loadCurrentPageText();

    redoStack.clear();

    requestAutoSave();

    notifyListeners();
  }

  void setTitle(String value) {
    _title = value;

    requestAutoSave();

    notifyListeners();
  }

  void requestAutoSave() {
    _autoSaveTimer?.cancel();

    _autoSaveTimer = Timer(const Duration(seconds: 1), () {
      autoSave();
    });
  }

  Future<void> autoSave() async {
    final hasContent = pages.any(
      (page) => page.text.trim().isNotEmpty || page.strokes.isNotEmpty,
    );

    if (!hasContent && _noteId == null) {
      return;
    }

    _isAutoSaving = true;
    _autoSaveSaved = false;
    notifyListeners();

    try {
      _noteId ??= DateTime.now().microsecondsSinceEpoch.toString();

      saveCurrentPageText();

      final stopwatch = Stopwatch()..start();

      await _autoSaveService.save(
        id: _noteId!,
        title: _title,
        pages: pages,
        currentPage: currentPage,
      );

      stopwatch.stop();

      // حداقل 700 میلی‌ثانیه حالت نارنجی نمایش داده شود
      final remaining = 700 - stopwatch.elapsedMilliseconds;

      if (remaining > 0) {
        await Future.delayed(Duration(milliseconds: remaining));
      }

      _autoSaveSaved = true;
    } catch (e) {
      debugPrint('AutoSave error: $e');

      _autoSaveSaved = false;
    } finally {
      _isAutoSaving = false;
      notifyListeners();
    }
  }

  Future<bool> restoreLatestAutoSave() async {
    try {
      final data = await _autoSaveService.loadLatest();

      if (data == null) {
        return false;
      }

      pages
        ..clear()
        ..addAll(data.pages);

      if (pages.isEmpty) {
        pages.add(NotePage());
      }

      _noteId = data.id;

      _title = data.title;

      currentPage = data.currentPage.clamp(0, pages.length - 1);

      loadCurrentPageText();

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Restore AutoSave error: $e');

      return false;
    }
  }

  void createNewNote() {
    _autoSaveTimer?.cancel();

    _noteId = null;

    _title = '';

    pages
      ..clear()
      ..add(NotePage());

    currentPage = 0;

    noteController.clear();

    redoStack.clear();

    notifyListeners();
  }

  void loadAutoSaveData(AutoSaveData data) {
    pages
      ..clear()
      ..addAll(data.pages);

    if (pages.isEmpty) {
      pages.add(NotePage());
    }

    _noteId = data.id;

    _title = data.title;

    currentPage = data.currentPage.clamp(0, pages.length - 1);

    loadCurrentPageText();

    redoStack.clear();

    notifyListeners();
  }

  Future<void> removeCurrentAutoSave() async {
    if (_noteId == null) {
      return;
    }

    try {
      await _autoSaveService.delete(_noteId!);

      _noteId = null;
      _autoSaveSaved = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Delete AutoSave error: $e');
    }
  }
}

enum ToolType { pen, highlighter, eraser }
