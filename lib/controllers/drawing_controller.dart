import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/note_page.dart';
import '../models/stroke.dart';

class DrawingController extends ChangeNotifier {
  final List<NotePage> pages = [NotePage()];

  bool _writingMode = false;

  bool get writingMode => _writingMode;

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

    notifyListeners();
  }
}

enum ToolType { pen, highlighter, eraser }
