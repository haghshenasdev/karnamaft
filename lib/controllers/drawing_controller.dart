import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/note_page.dart';
import '../models/stroke.dart';

class DrawingController extends ChangeNotifier {
  final List<NotePage> pages = [NotePage()];
  bool _writingMode = false;

  bool get writingMode => _writingMode;

  void toggleWritingMode() {
    _writingMode = !_writingMode;

    if (_writingMode) {
      _textMode = false;
      selectedTool = ToolType.pen;
    }

    notifyListeners();
  }

  int get pageCount => pages.length;

  bool get canUndo => strokes.isNotEmpty;

  bool get canRedo => redoStack.isNotEmpty;

  bool get canPrevious => currentPage > 0;

  bool get canNext => true;

  int currentPage = 0;

  List<StrokeModel> get strokes => pages[currentPage].strokes;

  final List<StrokeModel> redoStack = [];

  Color penColor = Colors.black;

  double penWidth = 3;

  StrokeModel? currentStroke;

  ToolType selectedTool = ToolType.pen;

  //--------------------------------------------------
  // Text Mode
  //--------------------------------------------------

  bool _textMode = false;

  bool get textMode => _textMode;
  final noteController = TextEditingController();

  void setTool(ToolType tool) {
    selectedTool = tool;
    notifyListeners();
  }

  //--------------------------------------------------
  // Text Mode
  //--------------------------------------------------

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

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

  //-------------------------------------------------

  void previousPage() {
    if (currentPage == 0) return;

    currentPage--;

    redoStack.clear();

    notifyListeners();
  }

  void nextPage() {
    if (currentPage == pages.length - 1) {
      pages.add(NotePage());
    }

    currentPage++;

    redoStack.clear();

    notifyListeners();
  }

  //-------------------------------------------------

  void undo() {
    if (strokes.isEmpty) return;

    redoStack.add(strokes.removeLast());

    notifyListeners();
  }

  void redo() {
    if (redoStack.isEmpty) return;

    strokes.add(redoStack.removeLast());

    notifyListeners();
  }

  void clear() {
    strokes.clear();

    redoStack.clear();

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

  void removeCurrentPage() {
    // اگر فقط یک صفحه وجود دارد، فقط محتوایش پاک شود.
    if (pages.length == 1) {
      clear();
      return;
    }

    pages.removeAt(currentPage);

    // اگر صفحه آخر حذف شده بود
    if (currentPage >= pages.length) {
      currentPage = pages.length - 1;
    }

    redoStack.clear();

    notifyListeners();
  }
}

enum ToolType { pen, highlighter, eraser }
