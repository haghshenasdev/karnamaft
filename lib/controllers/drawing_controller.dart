import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karnamaft/services/note_autosave_service.dart';

import '../models/note_page.dart';
import '../models/stroke.dart';

class DrawingController extends ChangeNotifier {
  // ============================================================
  // Pages
  // ============================================================

  final List<NotePage> pages = [NotePage()];

  int currentPage = 0;

  int get pageCount => pages.length;

  List<StrokeModel> get strokes => pages[currentPage].strokes;

  bool get currentPageLandscape => pages[currentPage].landscape;

  // ============================================================
  // Default settings for new pages
  // ============================================================

  /// پس‌زمینه‌ای که برای صفحات جدید استفاده می‌شود.
  String? _defaultBackgroundImagePath;

  /// جهت پیش‌فرض صفحات جدید.
  bool _defaultLandscape = false;

  String? get defaultBackgroundImagePath => _defaultBackgroundImagePath;

  bool get defaultLandscape => _defaultLandscape;

  // ============================================================
  // Page orientation
  // ============================================================

  /// فقط صفحه فعلی را تغییر می‌دهد.
  void togglePageOrientation() {
    final page = pages[currentPage];

    page.landscape = !page.landscape;

    requestAutoSave();
    notifyListeners();
  }

  /// جهت همه صفحات فعلی را یکسان می‌کند
  /// و همین حالت را برای صفحات آینده نگه می‌دارد.
  void setPageOrientationForAll(bool landscape) {
    _defaultLandscape = landscape;

    for (final page in pages) {
      page.landscape = landscape;
    }

    requestAutoSave();
    notifyListeners();
  }

  /// حالت همه صفحات را بر اساس وضعیت فعلی برعکس می‌کند.
  void togglePageOrientationForAll() {
    final newLandscape = !currentPageLandscape;

    setPageOrientationForAll(newLandscape);
  }

  // ============================================================
  // Background
  // ============================================================

  /// فقط پس‌زمینه صفحه فعلی را تغییر می‌دهد.
  void setPageBackground(String? path) {
    pages[currentPage].backgroundImagePath = path;

    requestAutoSave();
    notifyListeners();
  }

  /// پس‌زمینه را برای تمام صفحات فعلی اعمال می‌کند
  /// و صفحات جدید نیز همین پس‌زمینه را خواهند داشت.
  void setPageBackgroundForAll(String? path) {
    _defaultBackgroundImagePath = path;

    for (final page in pages) {
      page.backgroundImagePath = path;
    }

    requestAutoSave();
    notifyListeners();
  }

  // ============================================================
  // Create page
  // ============================================================

  /// ساخت صفحه جدید با تنظیمات پیش‌فرض فعلی.
  NotePage _createPage() {
    return NotePage(
      backgroundImagePath: _defaultBackgroundImagePath,
      landscape: _defaultLandscape,
    );
  }

  // ============================================================
  // Navigation
  // ============================================================

  bool get canPrevious => currentPage > 0;

  /// چون صفحه بعدی در صورت نیاز ساخته می‌شود،
  /// همیشه امکان رفتن به صفحه بعد وجود دارد.
  bool get canNext => true;

  void previousPage() {
    if (!canPrevious) {
      return;
    }

    goToPage(currentPage - 1);
  }

  void nextPage() {
    saveCurrentPageText();

    if (currentPage == pages.length - 1) {
      pages.add(_createPage());
    }

    currentPage++;

    loadCurrentPageText();

    redoStack.clear();

    requestAutoSave();
    notifyListeners();
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

  // ============================================================
  // Text
  // ============================================================

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
      selection: TextSelection.collapsed(
        offset: text.length,
      ),
    );
  }

  /// ذخیره مستقیم متن یک صفحه
  void savePageText(String value) {
    pages[currentPage].text = value;

    requestAutoSave();
    notifyListeners();
  }

  // ============================================================
  // Writing Mode
  // ============================================================

  bool _writingMode = false;

  bool get writingMode => _writingMode;

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

  // ============================================================
  // Drawing / Text Mode
  // ============================================================

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

  // ============================================================
  // Pen
  // ============================================================

  final List<StrokeModel> redoStack = [];

  Color penColor = Colors.black;

  double penWidth = 3;

  StrokeModel? currentStroke;

  ToolType selectedTool = ToolType.pen;

  void setTool(ToolType tool) {
    selectedTool = tool;

    // وقتی ابزار عوض می‌شود، stroke نیمه‌کاره نباید باقی بماند.
    currentStroke = null;

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

  // ============================================================
  // Drawing
  // ============================================================

  void start(Offset point) {
    if (_textMode) {
      return;
    }

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
    if (_textMode) {
      return;
    }

    if (currentStroke == null) {
      return;
    }

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
    if (_textMode) {
      return;
    }

    currentStroke = null;

    redoStack.clear();

    requestAutoSave();
    notifyListeners();
  }

  // ============================================================
  // Undo / Redo
  // ============================================================

  bool get canUndo => strokes.isNotEmpty;

  bool get canRedo => redoStack.isNotEmpty;

  void undo() {
    if (strokes.isEmpty) {
      return;
    }

    redoStack.add(strokes.removeLast());

    requestAutoSave();
    notifyListeners();
  }

  void redo() {
    if (redoStack.isEmpty) {
      return;
    }

    strokes.add(redoStack.removeLast());

    requestAutoSave();
    notifyListeners();
  }

  // ============================================================
  // Clear
  // ============================================================

  void clear() {
    strokes.clear();

    pages[currentPage].text = '';

    noteController.clear();

    redoStack.clear();

    currentStroke = null;

    requestAutoSave();
    notifyListeners();
  }

  // ============================================================
  // Delete Page
  // ============================================================

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

    currentStroke = null;

    requestAutoSave();
    notifyListeners();
  }

  // ============================================================
  // Auto Save
  // ============================================================

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

  void setTitle(String value) {
    _title = value;

    requestAutoSave();
    notifyListeners();
  }

  void requestAutoSave() {
    _autoSaveTimer?.cancel();

    _autoSaveTimer = Timer(
      const Duration(seconds: 1),
      () {
        autoSave();
      },
    );
  }

  Future<void> autoSave() async {
    final hasContent = pages.any(
      (page) =>
          page.text.trim().isNotEmpty ||
          page.strokes.isNotEmpty ||
          page.backgroundImagePath != null ||
          page.landscape,
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

      // حداقل 700 میلی‌ثانیه حالت ذخیره نمایش داده شود.
      final remaining = 700 - stopwatch.elapsedMilliseconds;

      if (remaining > 0) {
        await Future.delayed(
          Duration(milliseconds: remaining),
        );
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

      currentPage = data.currentPage.clamp(
        0,
        pages.length - 1,
      );

      // در صورتی که یادداشت قبلی تنظیمات یکسانی
      // برای صفحات داشته باشد، همان تنظیمات برای
      // صفحات جدید ادامه پیدا می‌کند.
      _syncDefaultsFromPages();

      loadCurrentPageText();

      redoStack.clear();

      currentStroke = null;

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Restore AutoSave error: $e');

      return false;
    }
  }

  void _syncDefaultsFromPages() {
    if (pages.isEmpty) {
      _defaultBackgroundImagePath = null;
      _defaultLandscape = false;
      return;
    }

    final firstBackground = pages.first.backgroundImagePath;
    final firstLandscape = pages.first.landscape;

    final sameBackground = pages.every(
      (page) => page.backgroundImagePath == firstBackground,
    );
    final sameLandscape = pages.every(
      (page) => page.landscape == firstLandscape,
    );

    _defaultBackgroundImagePath = sameBackground
        ? firstBackground
        : pages[currentPage].backgroundImagePath;

    _defaultLandscape = sameLandscape
        ? firstLandscape
        : pages[currentPage].landscape;
  }

  void createNewNote() {
    _autoSaveTimer?.cancel();

    _noteId = null;

    _title = '';

    // یادداشت جدید با تنظیمات پایه شروع می‌شود.
    _defaultBackgroundImagePath = null;
    _defaultLandscape = false;

    pages
      ..clear()
      ..add(_createPage());

    currentPage = 0;

    noteController.clear();

    redoStack.clear();

    currentStroke = null;

    _autoSaveSaved = false;

    notifyListeners();
  }

  void loadAutoSaveData(AutoSaveData data) {
    pages
      ..clear()
      ..addAll(data.pages);

    if (pages.isEmpty) {
      pages.add(_createPage());
    }

    _noteId = data.id;

    _title = data.title;

    currentPage = data.currentPage.clamp(
      0,
      pages.length - 1,
    );

    _syncDefaultsFromPages();

    loadCurrentPageText();

    redoStack.clear();

    currentStroke = null;

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

  // ============================================================
  // Dispose
  // ============================================================

  @override
  void dispose() {
    _autoSaveTimer?.cancel();

    noteController.dispose();

    super.dispose();
  }
}

// ============================================================
// Tools
// ============================================================

enum ToolType {
  pen,
  highlighter,
  eraser,
}