import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karnamaft/pages/minute_create_page.dart';
import 'package:karnamaft/services/note_autosave_service.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:provider/provider.dart';

import '../controllers/drawing_controller.dart';
import '../models/note_page.dart';
import '../models/stroke.dart';
import '../painters/drawing_painter.dart';
import '../widgets/category_picker/category_picker.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/note_editor.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/note_export_result.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final NoteAutoSaveService _autoSaveService = NoteAutoSaveService();
  //--------------------------------------------------
  // Controllers
  //--------------------------------------------------

  final TextEditingController _titleController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  // حداکثر عرض واقعی کاغذ
  static const double _maxWritingPageWidth = 1000;

  final GlobalKey _paperKey = GlobalKey();

  //--------------------------------------------------
  // Page Size
  //--------------------------------------------------

  static const double _paperRatio = 210 / 297;

  static const double _writingHeight = 2400;
  double _zoom = 1.0;

  static const double _minZoom = 0.7;
  static const double _maxZoom = 1.5;
  static const double _zoomStep = 0.1;

  // --------------------------------------------------
  // قلم هوشمند / Samsung Notes style handwriting pad
  // --------------------------------------------------
  bool _smartPenPadOpen = false;
  bool _smartPenEnabled = false;
  final List<StrokeModel> _smartPadStrokes = [];
  StrokeModel? _smartPadCurrentStroke;

  // موقعیت و اندازه کادر کوچک روی کاغذ، به صورت نسبت به خود کاغذ.
  // بنابراین با Zoom و تغییر اندازه صفحه، جای کادر خراب نمی‌شود.
  Rect _smartPenTarget = const Rect.fromLTWH(.56, .34, .30, .12);
  static const double _smartTargetMinWidth = .14;
  static const double _smartTargetMinHeight = .055;

  // کنترل‌های کادر بزرگ نوشتن
  Rect _smartPadRect = const Rect.fromLTWH(.04, .45, .92, .48);
  Timer? _smartAdvanceTimer;
  bool _smartPadDragging = false;

  static const double _smartPadMinWidth = .60;
  static const double _smartPadMaxWidth = .98;
  static const double _smartPadMinHeight = .30;
  static const double _smartPadMaxHeight = .72;

  // نوار سمت چپ کادر بزرگ؛ عبور قلم از این ناحیه یعنی رفتن
  // به قسمت بعدی برگه، درست مثل نوار Advance در Samsung Notes.
  double _smartPadAdvanceZoneWidth = 105.0;
  static const double _smartPadAdvanceZoneMin = 55.0;
  static const double _smartPadAdvanceZoneMax = 260.0;
  static const double _smartLineGap = .018;

  bool _noteSavedToMinute = false;

  Future<void> _setOrientation() async {
    final controller = context.read<DrawingController>();

    if (controller.writingMode) {
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
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _setOrientation();

      if (!mounted) return;

      final controller = context.read<DrawingController>();

      final restored = await controller.restoreLatestAutoSave();

      if (restored && mounted) {
        _titleController.text = controller.title;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _smartAdvanceTimer?.cancel();
    _titleController.dispose();

    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xfff5f6fa),

      //--------------------------------------------------
      // APP BAR
      //--------------------------------------------------
      appBar: AppBar(
        elevation: 0,

        scrolledUnderElevation: 0,

        backgroundColor: colors.surface,

        title: TextField(
          controller: _titleController,
          onChanged: (value) {
            context.read<DrawingController>().setTitle(value);

            if (_noteSavedToMinute) {
              setState(() {
                _noteSavedToMinute = false;
              });
            }
          },

          textAlign: TextAlign.right,

          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),

          decoration: const InputDecoration(
            hintText: "عنوان یادداشت ...",

            border: InputBorder.none,

            hintStyle: TextStyle(
              color: Colors.grey,

              fontWeight: FontWeight.normal,
            ),
          ),
        ),

        actions: [
          Consumer<DrawingController>(
            builder: (context, controller, _) {
              Color? iconColor;
              IconData icon;
              String tooltip;

              if (controller.isAutoSaving) {
                // در حال Auto Save
                iconColor = Colors.orange;
                icon = Icons.cloud_upload_outlined;
                tooltip = 'در حال ذخیره خودکار...';
              } else if (_noteSavedToMinute) {
                // صورتجلسه با موفقیت ساخته شده
                iconColor = Colors.green;
                icon = Icons.cloud_done;
                tooltip = 'صورتجلسه با موفقیت ذخیره شد';
              } else {
                // حالت عادی
                iconColor = null;
                icon = Icons.cloud_outlined;
                tooltip = 'ذخیره';
              }

              return IconButton(
                tooltip: tooltip,
                onPressed: _saveNote,
                icon: Icon(icon, color: iconColor),
              );
            },
          ),

          IconButton(
            tooltip: "یادداشت جدید",

            onPressed: () {
              final controller = context.read<DrawingController>();

              if (_smartPenPadOpen) {
                _closeSmartPenPad(commit: true);
              }

              controller.createNewNote();

              setState(() {
                _smartPenEnabled = false;
                _smartPenPadOpen = false;
                _smartPadStrokes.clear();
              });

              _titleController.clear();

              setState(() {
                _noteSavedToMinute = false;
              });
            },

            icon: const Icon(Icons.note_add_outlined),
          ),

          IconButton(
            tooltip: "تاریخچه",

            onPressed: () {
              _showAutoSaveHistory();
            },

            icon: const Icon(Icons.history),
          ),

          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: "clear", child: Text("پاک کردن صفحه")),

              const PopupMenuItem(value: "pdf", child: Text("خروجی PDF")),

              const PopupMenuItem(value: "setting", child: Text("تنظیمات")),
            ],

            onSelected: (value) {
              if (value == "clear") {
                _confirmClearPage(context);
              }

              if (value == "pdf") {
                _exportPdf();
              }
            },
          ),
        ],
      ),

      //--------------------------------------------------
      // BODY
      //--------------------------------------------------
      body: SafeArea(
        child: Consumer<DrawingController>(
          builder: (context, controller, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    //--------------------------------------------------
                    // Header : Type + Category
                    //--------------------------------------------------
                    // if (!controller.writingMode)
                    if (false)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),

                        child: Card(
                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),

                          child: Padding(
                            padding: const EdgeInsets.all(10),

                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final typeWidth = (constraints.maxWidth * .34)
                                    .clamp(120.0, 160.0);

                                return Row(
                                  children: [
                                    //--------------------------------------------------
                                    // Note Type
                                    //--------------------------------------------------
                                    SizedBox(
                                      width: typeWidth,

                                      child: DropdownMenu<NoteType>(
                                        width: typeWidth,

                                        label: const Text("نوع"),

                                        initialSelection: NoteType.note,

                                        dropdownMenuEntries: noteTypes.map((
                                          item,
                                        ) {
                                          return DropdownMenuEntry<NoteType>(
                                            value: item.type,

                                            label: item.title,

                                            leadingIcon: Icon(item.icon),
                                          );
                                        }).toList(),

                                        onSelected: (value) {},
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    //--------------------------------------------------
                                    // Category
                                    //--------------------------------------------------
                                    Expanded(
                                      child: CategoryPicker(
                                        selectedItems: const [],

                                        onChanged: (items) {},
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    //--------------------------------------------------
                    // PAPER
                    //--------------------------------------------------
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final availableWidth = constraints.maxWidth - 40;
                          final availableHeight = constraints.maxHeight - 24;

                          //--------------------------------------------------
                          // WRITING MODE
                          //--------------------------------------------------
                          if (controller.writingMode) {
                            final availableWidth = constraints.maxWidth - 40;
                            final availableHeight = constraints.maxHeight - 24;

                            // حداکثر عرض کاغذ بر اساس فضای واقعی صفحه
                            final double maxWritingPageWidth = availableWidth;

                            // اعمال Zoom
                            final double paperWidth =
                                maxWritingPageWidth * _zoom;

                            // نسبت A4
                            final double paperHeight = paperWidth / _paperRatio;
                            //--------------------------------------------------
                            // VIEWPORT
                            //--------------------------------------------------

                            return SizedBox(
                              width: double.infinity,
                              height: availableHeight,

                              child: Stack(
                                children: [
                                  //--------------------------------------------------
                                  // SCROLL AREA
                                  //--------------------------------------------------
                                  Positioned.fill(
                                    child: SingleChildScrollView(
                                      controller: _scrollController,

                                      physics:
                                          const NeverScrollableScrollPhysics(),

                                      child: Center(
                                        child: Card(
                                          elevation: 5,
                                          color: Colors.white,
                                          clipBehavior: Clip.antiAlias,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: RepaintBoundary(
                                            key: _paperKey,
                                            child: Container(
                                              width: paperWidth,
                                              height: paperHeight,
                                              color: Colors.white,
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Consumer<DrawingController>(
                                                    builder:
                                                        (
                                                          context,
                                                          controller,
                                                          _,
                                                        ) {
                                                          return NoteEditor(
                                                            controller: controller
                                                                .noteController,
                                                            enabled: controller
                                                                .textMode,
                                                            onChanged: controller
                                                                .savePageText,
                                                          );
                                                        },
                                                  ),

                                                  DrawingCanvas(
                                                    controller: controller,
                                                    zoom: _zoom,
                                                  ),

                                                  // کادر کوچک مقصد دقیقاً روی خود کاغذ قرار می‌گیرد.
                                                  if (_smartPenEnabled)
                                                    _buildSmartPenTarget(
                                                      Size(
                                                        paperWidth,
                                                        paperHeight,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  //--------------------------------------------------
                                  // FLOATING SCROLL BUTTONS
                                  //--------------------------------------------------
                                  Positioned(
                                    right: 24,
                                    bottom: 24,

                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,

                                      children: [
                                        //--------------------------------------------------
                                        // UP
                                        //--------------------------------------------------
                                        FloatingActionButton.small(
                                          heroTag: 'writing_scroll_up',

                                          tooltip: 'بالا',

                                          onPressed: () {
                                            if (!_scrollController.hasClients) {
                                              return;
                                            }

                                            final position =
                                                _scrollController.position;

                                            _scrollController.animateTo(
                                              (_scrollController.offset - 500)
                                                  .clamp(
                                                    0.0,
                                                    position.maxScrollExtent,
                                                  ),

                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),

                                              curve: Curves.easeOut,
                                            );
                                          },

                                          child: const Icon(
                                            Icons.keyboard_arrow_up,
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        //--------------------------------------------------
                                        // DOWN
                                        //--------------------------------------------------
                                        FloatingActionButton.small(
                                          heroTag: 'writing_scroll_down',

                                          tooltip: 'پایین',

                                          onPressed: () {
                                            if (!_scrollController.hasClients) {
                                              return;
                                            }

                                            final position =
                                                _scrollController.position;

                                            _scrollController.animateTo(
                                              (_scrollController.offset + 500)
                                                  .clamp(
                                                    0.0,
                                                    position.maxScrollExtent,
                                                  ),

                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),

                                              curve: Curves.easeOut,
                                            );
                                          },

                                          child: const Icon(
                                            Icons.keyboard_arrow_down,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    left: 24,
                                    bottom: 24,

                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,

                                      children: [
                                        //--------------------------------------------------
                                        // ZOOM IN
                                        //--------------------------------------------------
                                        FloatingActionButton.small(
                                          heroTag: 'zoom_in',

                                          tooltip: 'بزرگ‌نمایی',

                                          onPressed: () {
                                            setState(() {
                                              _zoom = (_zoom + _zoomStep).clamp(
                                                _minZoom,
                                                _maxZoom,
                                              );
                                            });
                                          },

                                          child: const Icon(Icons.add),
                                        ),

                                        const SizedBox(height: 10),

                                        //--------------------------------------------------
                                        // ZOOM OUT
                                        //--------------------------------------------------
                                        FloatingActionButton.small(
                                          heroTag: 'zoom_out',

                                          tooltip: 'کوچک‌نمایی',

                                          onPressed: () {
                                            setState(() {
                                              _zoom = (_zoom - _zoomStep).clamp(
                                                _minZoom,
                                                _maxZoom,
                                              );
                                            });
                                          },

                                          child: const Icon(Icons.remove),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          //--------------------------------------------------
                          // NORMAL MODE
                          //--------------------------------------------------

                          double pageWidth = availableWidth;

                          double pageHeight = pageWidth / _paperRatio;

                          if (pageHeight > availableHeight) {
                            pageHeight = availableHeight;

                            pageWidth = pageHeight * _paperRatio;
                          }

                          return Align(
                            alignment: Alignment.topCenter,
                            child: Card(
                              elevation: 5,
                              color: Colors.white,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: RepaintBoundary(
                                key: _paperKey,
                                child: Container(
                                  width: pageWidth,
                                  height: pageHeight,
                                  color: Colors.white,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Consumer<DrawingController>(
                                        builder: (context, controller, _) {
                                          return NoteEditor(
                                            controller:
                                                controller.noteController,
                                            enabled: controller.textMode,
                                            onChanged: controller.savePageText,
                                          );
                                        },
                                      ),

                                      DrawingCanvas(controller: controller),

                                      if (_smartPenEnabled)
                                        _buildSmartPenTarget(
                                          Size(pageWidth, pageHeight),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // --------------------------------------------------
                    // Toolbar
                    // --------------------------------------------------
                    Container(
                      height: 54,

                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),

                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,

                        borderRadius: BorderRadius.circular(18),

                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,

                            offset: const Offset(0, 3),

                            color: Colors.black.withOpacity(.08),
                          ),
                        ],
                      ),

                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            //--------------------------------------------------
                            // Undo
                            //--------------------------------------------------
                            IconButton.filledTonal(
                              icon: const Icon(Icons.undo),

                              onPressed: controller.canUndo
                                  ? controller.undo
                                  : null,
                            ),

                            //--------------------------------------------------
                            // Redo
                            //--------------------------------------------------
                            IconButton.filledTonal(
                              icon: const Icon(Icons.redo),

                              onPressed: controller.canRedo
                                  ? controller.redo
                                  : null,
                            ),

                            const SizedBox(width: 12),

                            //--------------------------------------------------
                            // Pen Settings
                            //--------------------------------------------------
                            IconButton.filledTonal(
                              tooltip: "ابزار قلم",

                              onPressed: () {
                                _showPenDialog(context, controller);
                              },

                              icon: Icon(switch (controller.selectedTool) {
                                ToolType.pen => Icons.edit,

                                ToolType.highlighter => Icons.draw,

                                ToolType.eraser => Icons.auto_fix_off,
                              }, color: controller.penColor),
                            ),

                            const SizedBox(width: 6),

                            // Samsung Notes style handwriting magnifier.
                            IconButton.filledTonal(
                              tooltip: _smartPenPadOpen
                                  ? 'بستن کادر نوشتن با قلم'
                                  : 'نوشتن با قلم در کادر بزرگ',
                              onPressed: _smartPenPadOpen
                                  ? () => _closeSmartPenPad(commit: true)
                                  : _openSmartPenPad,
                              icon: Icon(
                                _smartPenPadOpen
                                    ? Icons.picture_in_picture_alt_rounded
                                    : Icons.edit_note_rounded,
                              ),
                            ),

                            const SizedBox(width: 6),

                            //--------------------------------------------------
                            // Writing Mode Button
                            //--------------------------------------------------
                            IconButton.filledTonal(
                              tooltip: controller.writingMode
                                  ? "خروج از حالت نوشتن"
                                  : "حالت نوشتن",

                              icon: Icon(
                                controller.writingMode
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                              ),

                              onPressed: () async {
                                controller.toggleWritingMode();

                                if (controller.writingMode) {
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
                              },
                            ),

                            const SizedBox(width: 6),

                            //--------------------------------------------------
                            // Pages
                            //--------------------------------------------------
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,

                                borderRadius: BorderRadius.circular(24),
                              ),

                              child: Row(
                                children: [
                                  IconButton(
                                    tooltip: "صفحه قبل",

                                    onPressed: controller.canPrevious
                                        ? () {
                                            if (_smartPenPadOpen) {
                                              _closeSmartPenPad(commit: true);
                                            }
                                            controller.previousPage();
                                          }
                                        : null,

                                    icon: const Icon(Icons.chevron_left),
                                  ),

                                  InkWell(
                                    onTap: () {
                                      _showPages(context, controller);
                                    },

                                    borderRadius: BorderRadius.circular(18),

                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),

                                      child: Text(
                                        "${controller.currentPage + 1} / ${controller.pageCount}",

                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  IconButton(
                                    tooltip: "صفحه بعد",

                                    onPressed: () {
                                      if (_smartPenPadOpen) {
                                        _closeSmartPenPad(commit: true);
                                      }
                                      controller.nextPage();
                                    },

                                    icon: const Icon(Icons.chevron_right),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // IMPORTANT: Positioned must be a direct child of this Stack.
                // بنابراین کادر شناور نوشتن خارج از Column قرار می‌گیرد.
                if (_smartPenPadOpen) _buildSmartPenPad(context),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // Smart Pen Pad
  // ============================================================

  void _openSmartPenPad() {
    _smartAdvanceTimer?.cancel();
    _smartAdvanceTimer = null;
    final controller = context.read<DrawingController>();
    controller.enableDrawingMode();

    setState(() {
      _smartPenEnabled = true;
      _smartPenPadOpen = true;
      _smartPadStrokes.clear();
      _smartPadCurrentStroke = null;
    });
  }

  void _closeSmartPenPad({bool commit = true}) {
    _smartAdvanceTimer?.cancel();
    _smartAdvanceTimer = null;
    if (commit) {
      _commitSmartPadStrokes();
    }

    if (!mounted) return;

    setState(() {
      _smartPenPadOpen = false;
      _smartPenEnabled = false;
      _smartPadStrokes.clear();
      _smartPadCurrentStroke = null;
    });
  }

  List<StrokeModel> _currentPageStrokes() {
    final controller = context.read<DrawingController>();
    return controller.pages[controller.currentPage].strokes;
  }

  // یک Stroke کامل‌شده را مستقل از محل فیزیکی آن در کادر بزرگ،
  // داخل کادر آبی روی کاغذ قرار می‌دهد.
  void _commitSmartStroke(StrokeModel source) {
    if (source.points.isEmpty) return;

    final controller = context.read<DrawingController>();
    final target = _smartPenTarget;

    const double padReferenceWidth = 1000.0;
    const double padReferenceHeight = 520.0;

    final targetLeft = target.left * DrawingPainter.basePageWidth;
    final targetTop = target.top * DrawingPainter.basePageHeight;
    final targetWidth = target.width * DrawingPainter.basePageWidth;
    final targetHeight = target.height * DrawingPainter.basePageHeight;

    final mapped = source.points.map((point) {
      final x = (point.dx / padReferenceWidth).clamp(0.0, 1.0);
      final y = (point.dy / padReferenceHeight).clamp(0.0, 1.0);

      return Offset(targetLeft + x * targetWidth, targetTop + y * targetHeight);
    }).toList();

    if (mapped.isEmpty) return;

    final scale = targetWidth / padReferenceWidth;

    controller.pages[controller.currentPage].strokes.add(
      StrokeModel(
        points: mapped,
        color: source.color,
        width: (source.width * scale).clamp(.5, 20.0),
        type: source.type,
      ),
    );

    controller.requestAutoSave();
    controller.notifyListeners();
  }

  void _commitSmartPadStrokes() {
    if (_smartPadStrokes.isEmpty) return;

    // فقط Strokeهای کامل‌شده‌ای که هنوز روی صفحه درج نشده‌اند.
    for (final stroke in List<StrokeModel>.from(_smartPadStrokes)) {
      _commitSmartStroke(stroke);
    }

    _smartPadStrokes.clear();
    _smartPadCurrentStroke = null;
  }

  void _advanceSmartPenTarget() {
    final target = _smartPenTarget;
    final gap = _smartLineGap;

    // راست به چپ: خانه بعدی سمت چپ خانه فعلی قرار می‌گیرد.
    final nextLeft = target.left - target.width - gap;

    if (nextLeft >= 0.0) {
      setState(() {
        _smartPenTarget = Rect.fromLTWH(
          nextLeft,
          target.top,
          target.width,
          target.height,
        );
        _smartPadCurrentStroke = null;
      });
      return;
    }

    // انتهای خط: از سمت راست خط بعدی شروع کن.
    final nextTop = (target.top + target.height + gap).clamp(
      0.0,
      1.0 - target.height,
    );

    setState(() {
      _smartPenTarget = Rect.fromLTWH(
        (1.0 - target.width).clamp(0.0, 1.0 - target.width),
        nextTop,
        target.width,
        target.height,
      );
      _smartPadCurrentStroke = null;
    });
  }

  void _startSmartPadStroke(Offset point, Size size) {
    final controller = context.read<DrawingController>();

    final x = point.dx.clamp(0.0, size.width);
    final y = point.dy.clamp(0.0, size.height);

    _smartPadCurrentStroke = StrokeModel(
      points: [Offset(x * 1000.0 / size.width, y * 520.0 / size.height)],
      color: controller.penColor,
      width: controller.penWidth,
      type: controller.selectedTool == ToolType.highlighter
          ? StrokeType.highlighter
          : controller.selectedTool == ToolType.eraser
          ? StrokeType.eraser
          : StrokeType.pen,
    );

    _smartPadStrokes.add(_smartPadCurrentStroke!);
    setState(() {});
  }

  void _updateSmartPadStroke(Offset point, Size size) {
    final stroke = _smartPadCurrentStroke;
    if (stroke == null) return;

    final p = Offset(
      point.dx.clamp(0.0, size.width) * 1000.0 / size.width,
      point.dy.clamp(0.0, size.height) * 520.0 / size.height,
    );

    if (stroke.points.isNotEmpty && (stroke.points.last - p).distance < 1.5) {
      return;
    }

    // در حین نوشتن هرگز کادر را جابه‌جا نمی‌کنیم.
    // Stroke باید کامل شود و سپس تصمیم انتقال گرفته شود.
    stroke.points.add(p);
    setState(() {});
  }

  void _endSmartPadStroke(Size size) {
    final stroke = _smartPadCurrentStroke;
    if (stroke == null || stroke.points.isEmpty) return;

    // تصمیم انتقال فقط بعد از کامل شدن Stroke گرفته می‌شود.
    final lastPoint = stroke.points.last;
    final advanceZoneReferenceWidth =
        (_smartPadAdvanceZoneWidth * 1000.0 / size.width);
    final isInAdvanceZone = lastPoint.dx <= advanceZoneReferenceWidth;

    // Stroke بلافاصله روی صفحه ثبت می‌شود، مستقل از اینکه کجای کادر بزرگ نوشته شده.
    _commitSmartStroke(stroke);
    _smartPadStrokes.remove(stroke);
    _smartPadCurrentStroke = null;

    if (isInAdvanceZone) {
      // اگر Stroke تمام شد و باید به خانه بعدی برویم، ۱.۵ ثانیه صبر کن.
      _smartAdvanceTimer?.cancel();
      _smartAdvanceTimer = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted || !_smartPenPadOpen) return;
        _smartAdvanceTimer = null;
        _advanceSmartPenTarget();
      });
    } else {
      setState(() {});
    }
  }

  void _smartMoveTargetPrevious() {
    _smartAdvanceTimer?.cancel();
    _smartAdvanceTimer = null;
    final target = _smartPenTarget;
    final left = target.left + target.width + _smartLineGap;
    setState(() {
      _smartPenTarget = Rect.fromLTWH(
        left.clamp(0.0, 1.0 - target.width),
        target.top,
        target.width,
        target.height,
      );
    });
  }

  void _smartMoveTargetNext() {
    _smartAdvanceTimer?.cancel();
    _smartAdvanceTimer = null;
    _advanceSmartPenTarget();
  }

  void _smartNewLine() {
    _smartAdvanceTimer?.cancel();
    _smartAdvanceTimer = null;
    final target = _smartPenTarget;
    final nextTop = (target.top + target.height + _smartLineGap).clamp(
      0.0,
      1.0 - target.height,
    );
    setState(() {
      _smartPenTarget = Rect.fromLTWH(
        (1.0 - target.width).clamp(0.0, 1.0 - target.width),
        nextTop,
        target.width,
        target.height,
      );
    });
  }

  void _resizeSmartAdvanceZone(double delta) {
    setState(() {
      _smartPadAdvanceZoneWidth = (_smartPadAdvanceZoneWidth + delta).clamp(
        _smartPadAdvanceZoneMin,
        _smartPadAdvanceZoneMax,
      );
    });
  }

  void _smartResizePad(double widthFactor, double heightFactor) {
    final center = _smartPadRect.center;
    final width = (_smartPadRect.width + widthFactor).clamp(
      _smartPadMinWidth,
      _smartPadMaxWidth,
    );
    final height = (_smartPadRect.height + heightFactor).clamp(
      _smartPadMinHeight,
      _smartPadMaxHeight,
    );
    var next = Rect.fromCenter(center: center, width: width, height: height);
    next = Rect.fromLTWH(
      next.left.clamp(0.01, 0.99 - next.width),
      next.top.clamp(0.05, 0.99 - next.height),
      next.width,
      next.height,
    );
    setState(() => _smartPadRect = next);
  }

  void _smartMovePad(double dx, double dy) {
    var next = _smartPadRect.shift(Offset(dx, dy));
    next = Rect.fromLTWH(
      next.left.clamp(0.01, 0.99 - next.width),
      next.top.clamp(0.05, 0.99 - next.height),
      next.width,
      next.height,
    );
    setState(() => _smartPadRect = next);
  }

  void _moveSmartPenTarget(Offset delta, Size paperSize) {
    if (paperSize.width <= 0 || paperSize.height <= 0) return;

    final dx = delta.dx / paperSize.width;
    final dy = delta.dy / paperSize.height;

    var next = _smartPenTarget.shift(Offset(dx, dy));

    final maxLeft = 1.0 - next.width;
    final maxTop = 1.0 - next.height;

    next = Rect.fromLTWH(
      next.left.clamp(0.0, maxLeft),
      next.top.clamp(0.0, maxTop),
      next.width,
      next.height,
    );

    setState(() {
      _smartPenTarget = next;
    });
  }

  void _resizeSmartPenTarget(Offset delta, Size paperSize) {
    if (paperSize.width <= 0 || paperSize.height <= 0) return;

    // GestureDetector.onPanUpdate مقدار Offset می‌دهد، نه double.
    // تغییر اندازه را با هر دو محور انجام می‌دهیم.
    final dw = delta.dx / paperSize.width;
    final dh = delta.dy / paperSize.height;

    final newWidth = (_smartPenTarget.width + dw).clamp(
      _smartTargetMinWidth,
      .75,
    );
    final newHeight = (_smartPenTarget.height + dh).clamp(
      _smartTargetMinHeight,
      .45,
    );

    setState(() {
      _smartPenTarget = Rect.fromLTWH(
        _smartPenTarget.left,
        _smartPenTarget.top,
        newWidth,
        newHeight,
      );
    });
  }

  Widget _buildSmartPenTarget(Size paperSize) {
    final left = _smartPenTarget.left * paperSize.width;
    final top = _smartPenTarget.top * paperSize.height;
    final width = _smartPenTarget.width * paperSize.width;
    final height = _smartPenTarget.height * paperSize.height;

    final controller = context.read<DrawingController>();

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openSmartPenPad,
        onPanUpdate: (details) => _moveSmartPenTarget(details.delta, paperSize),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(.045),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(.70), width: 1.5),
          ),
          child: Stack(
            children: [
              // محتوای قبلی برگه که زیر این کادر قرار دارد.
              // Strokeهای تازه نیز روی آن به صورت بزرگ‌نمایی‌شده دیده می‌شوند.
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _MappedSmartPadPainter(
                      pageStrokes:
                          controller.pages[controller.currentPage].strokes,
                      smartStrokes: _smartPadStrokes,
                      target: _smartPenTarget,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 2,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(.82),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'محل انتقال',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 2,
                bottom: 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) =>
                      _resizeSmartPenTarget(details.delta, paperSize),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.open_in_full,
                      size: 13,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartPenPad(BuildContext context) {
    final controller = context.read<DrawingController>();
    final screen = MediaQuery.sizeOf(context);
    final left = _smartPadRect.left * screen.width;
    final top = _smartPadRect.top * screen.height;
    final width = _smartPadRect.width * screen.width;
    final height = _smartPadRect.height * screen.height;

    // این کنترل‌ها عمداً از IconButton معمولی استفاده نمی‌کنند.
    // چون ممکن است IconButtonTheme / IconTheme پروژه رنگ foreground را
    // شفاف یا همرنگ پس‌زمینه کند. در اینجا رنگ آیکون مستقیماً تعیین می‌شود.
    Widget controlButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
      Color? iconColor,
    }) {
      final effectiveIconColor =
          iconColor ?? Theme.of(context).colorScheme.onSurface;
      return Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 350),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: Icon(icon, size: 23, color: effectiveIconColor),
              ),
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Material(
        elevation: 24,
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // نوار کنترل کادر بزرگ
            GestureDetector(
              onPanStart: (_) => _smartPadDragging = true,
              onPanUpdate: (details) {
                if (!_smartPadDragging) return;
                _smartMovePad(
                  details.delta.dx / screen.width,
                  details.delta.dy / screen.height,
                );
              },
              onPanEnd: (_) => _smartPadDragging = false,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 21,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 4),

                      controlButton(
                        tooltip: 'حرکت به قبلی',
                        onPressed: _smartMoveTargetPrevious,
                        icon: Icons.chevron_right_rounded,
                      ),

                      controlButton(
                        tooltip: 'خط جدید',
                        onPressed: _smartNewLine,
                        icon: Icons.keyboard_return_rounded,
                      ),

                      controlButton(
                        tooltip: 'حرکت به بعدی',
                        onPressed: _smartMoveTargetNext,
                        icon: Icons.chevron_left_rounded,
                      ),

                      const SizedBox(width: 8),

                      controlButton(
                        tooltip: 'کوچک کردن کادر',
                        onPressed: () => _smartResizePad(-.06, -.04),
                        icon: Icons.fullscreen_exit_rounded,
                      ),

                      controlButton(
                        tooltip: 'بزرگ کردن کادر',
                        onPressed: () => _smartResizePad(.06, .04),
                        icon: Icons.fullscreen_rounded,
                      ),

                      controlButton(
                        tooltip: 'بستن کادر و انتقال نوشته‌ها',
                        onPressed: () => _closeSmartPenPad(commit: true),
                        icon: Icons.picture_in_picture_alt_rounded,
                      ),

                      controlButton(
                        tooltip: 'بستن حالت نوشتن',
                        onPressed: () => _closeSmartPenPad(commit: false),
                        icon: Icons.close_rounded,
                        iconColor: const Color(0xFFD32F2F),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.blueGrey.withOpacity(.20)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (event) => _startSmartPadStroke(
                        event.localPosition,
                        constraints.biggest,
                      ),
                      onPointerMove: (event) => _updateSmartPadStroke(
                        event.localPosition,
                        constraints.biggest,
                      ),
                      onPointerUp: (_) =>
                          _endSmartPadStroke(constraints.biggest),
                      onPointerCancel: (_) =>
                          _endSmartPadStroke(constraints.biggest),
                      child: CustomPaint(
                        painter: _SmartPadPainter(
                          pageStrokes:
                              controller.pages[controller.currentPage].strokes,
                          smartStrokes: _smartPadStrokes,
                          target: _smartPenTarget,
                          penColor: controller.penColor,
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: _smartPadAdvanceZoneWidth,
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(.055),
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.blue.withOpacity(.28),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: const Center(
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: Text(
                                        'برای ادامه، قلم را به این قسمت برسانید',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: _smartPadAdvanceZoneWidth - 12,
                              top: 0,
                              bottom: 0,
                              width: 24,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onHorizontalDragUpdate: (details) =>
                                    _resizeSmartAdvanceZone(details.delta.dx),
                                child: Center(
                                  child: Container(
                                    width: 4,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(.55),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.drag_handle,
                                      size: 16,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearPage(BuildContext context) async {
    final controller = context.read<DrawingController>();

    final result = await showDialog<bool>(
      context: context,

      builder: (context) => AlertDialog(
        title: const Text("پاک کردن صفحه"),

        content: const Text("تمام نوشته‌های این صفحه پاک شود؟"),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },

            child: const Text("انصراف"),
          ),

          FilledButton(
            onPressed: () {
              Navigator.pop(context, true);
            },

            child: const Text("پاک کن"),
          ),
        ],
      ),
    );

    if (result == true) {
      if (_smartPenPadOpen) {
        _closeSmartPenPad(commit: false);
      }
      controller.clear();
      setState(() {
        _smartPenEnabled = false;
        _smartPenPadOpen = false;
        _smartPadStrokes.clear();
      });
    }
  }

  void _showPages(BuildContext context, DrawingController controller) {
    showModalBottomSheet(
      context: context,

      showDragHandle: true,

      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.note_add_outlined),

                title: const Text("صفحه جدید"),

                onTap: () {
                  Navigator.pop(context);

                  controller.nextPage();
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete_outline),

                title: const Text("حذف صفحه"),

                onTap: () {
                  Navigator.pop(context);

                  showDeletePageDialog(context, controller);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> showDeletePageDialog(
    BuildContext context,
    DrawingController controller,
  ) async {
    final result = await showDialog<bool>(
      context: context,

      builder: (context) => AlertDialog(
        title: const Text("حذف صفحه"),

        content: const Text("آیا از حذف صفحه مطمئن هستید؟"),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },

            child: const Text("انصراف"),
          ),

          FilledButton(
            onPressed: () {
              Navigator.pop(context, true);
            },

            child: const Text("حذف"),
          ),
        ],
      ),
    );

    if (result == true) {
      controller.removeCurrentPage();
    }
  }

  void _showPenDialog(BuildContext context, DrawingController controller) {
    showModalBottomSheet(
      context: context,

      showDragHandle: true,

      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    "ابزار",

                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  //--------------------------------------------------
                  // Drawing / Text Mode
                  //--------------------------------------------------
                  ToggleButtons(
                    borderRadius: BorderRadius.circular(14),

                    isSelected: [!controller.textMode, controller.textMode],

                    onPressed: (index) {
                      if (index == 0) {
                        controller.enableDrawingMode();
                      } else {
                        controller.enableTextMode();
                      }

                      setState(() {});
                    },

                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),

                        child: Row(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            Icon(Icons.draw),

                            SizedBox(width: 6),

                            Text("قلم"),
                          ],
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),

                        child: Row(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            Icon(Icons.keyboard),

                            SizedBox(width: 6),

                            Text("متن"),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  //--------------------------------------------------
                  // Tools
                  //--------------------------------------------------
                  const Text(
                    "ابزار قلم",

                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,

                    children: [
                      ChoiceChip(
                        label: const Text("قلم"),

                        selected: controller.selectedTool == ToolType.pen,

                        onSelected: (_) {
                          controller.setTool(ToolType.pen);

                          setState(() {});
                        },
                      ),

                      ChoiceChip(
                        label: const Text("هایلایتر"),

                        selected:
                            controller.selectedTool == ToolType.highlighter,

                        onSelected: (_) {
                          controller.setTool(ToolType.highlighter);

                          setState(() {});
                        },
                      ),

                      ChoiceChip(
                        label: const Text("پاک‌کن"),

                        selected: controller.selectedTool == ToolType.eraser,

                        onSelected: (_) {
                          controller.setTool(ToolType.eraser);

                          setState(() {});
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  //--------------------------------------------------
                  // Colors
                  //--------------------------------------------------
                  const Text(
                    "رنگ",

                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,

                    children: [
                      for (final color in [
                        Colors.black,

                        Colors.red,

                        Colors.green,

                        Colors.blue,

                        Colors.orange,

                        Colors.purple,

                        Colors.brown,
                      ])
                        InkWell(
                          onTap: () {
                            controller.setColor(color);

                            setState(() {});
                          },

                          borderRadius: BorderRadius.circular(20),

                          child: CircleAvatar(
                            radius: 16,

                            backgroundColor: color,

                            child: controller.penColor == color
                                ? const Icon(
                                    Icons.check,

                                    size: 16,

                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  //--------------------------------------------------
                  // Width
                  //--------------------------------------------------
                  const Text(
                    "ضخامت",

                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  Slider(
                    value: controller.penWidth,

                    min: 1,

                    max: 20,

                    divisions: 19,

                    label: controller.penWidth.round().toString(),

                    onChanged: (value) {
                      controller.setWidth(value);

                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Uint8List?> _captureCurrentPage() async {
    try {
      final boundary =
          _paperKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        return null;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Capture page error: $e');
      return null;
    }
  }

  Future<void> _saveNote() async {
    if (_smartPenPadOpen) {
      _closeSmartPenPad(commit: true);
    }

    final controller = context.read<DrawingController>();

    try {
      // آخرین متن صفحه فعلی ذخیره شود
      controller.saveCurrentPageText();

      // صفحه فعلی را نگه می‌داریم
      final oldPage = controller.currentPage;

      Uint8List fileBytes;
      String fileName;

      final now = Jalali.now();

      final dateTime =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_'
          '${DateTime.now().hour.toString().padLeft(2, '0')}-'
          '${DateTime.now().minute.toString().padLeft(2, '0')}-'
          '${DateTime.now().second.toString().padLeft(2, '0')}';

      // =====================================================
      // یک صفحه → JPG
      // =====================================================
      if (controller.pageCount == 1) {
        final bytes = await _captureCurrentPage();

        if (bytes == null) {
          throw Exception('تصویر صفحه ایجاد نشد');
        }

        fileBytes = bytes;

        final title = _titleController.text.trim();

        fileName = '${title.isEmpty ? "note" : title}_$dateTime.png';
      }
      // =====================================================
      // چند صفحه → PDF
      // =====================================================
      else {
        final pdf = pw.Document();

        for (int i = 0; i < controller.pageCount; i++) {
          // رفتن به صفحه
          controller.currentPage = i;

          // بارگذاری متن همان صفحه
          controller.loadCurrentPageText();

          controller.notifyListeners();

          // فرصت برای Render
          await Future.delayed(const Duration(milliseconds: 100));

          final bytes = await _captureCurrentPage();

          if (bytes == null) {
            throw Exception('تصویر صفحه ${i + 1} ایجاد نشد');
          }

          final image = pw.MemoryImage(bytes);

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.zero,
              build: (context) {
                return pw.SizedBox(
                  width: PdfPageFormat.a4.width,
                  height: PdfPageFormat.a4.height,
                  child: pw.Image(image, fit: pw.BoxFit.fill),
                );
              },
            ),
          );
        }

        // بازگرداندن صفحه‌ای که کاربر روی آن بود
        controller.currentPage = oldPage;

        controller.loadCurrentPageText();

        controller.notifyListeners();

        final pdfBytes = await pdf.save();

        fileBytes = Uint8List.fromList(pdfBytes);

        final title = _titleController.text.trim();

        fileName = '${title.isEmpty ? "note" : title}_$dateTime.pdf';
      }

      // =====================================================
      // ارسال فایل به صفحه ایجاد صورتجلسه
      // =====================================================

      if (!mounted) return;

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MinuteCreatePage(
            initialFileBytes: fileBytes,
            initialFileName: fileName,
          ),
        ),
      );

      if (!mounted) return;

      if (result != null) {
        // صورتجلسه با موفقیت ایجاد شده
        setState(() {
          _noteSavedToMinute = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text("صورتجلسه با موفقیت ذخیره شد")),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در ذخیره یادداشت\n$e')));
    }
  }

  Future<String?> _pickSavePath({
    required String fileName,
    required String extension,
  }) async {
    return await FilePicker.platform.saveFile(
      dialogTitle: 'ذخیره خروجی',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [extension],
    );
  }

  Future<void> _exportPdf() async {
    if (_smartPenPadOpen) {
      _closeSmartPenPad(commit: true);
    }

    final controller = context.read<DrawingController>();

    try {
      controller.saveCurrentPageText();

      final pdf = pw.Document();

      final oldPage = controller.currentPage;

      for (int i = 0; i < controller.pageCount; i++) {
        controller.goToPage(i);

        await Future.delayed(const Duration(milliseconds: 100));

        final bytes = await _captureCurrentPage();

        if (bytes == null) {
          throw Exception('تصویر صفحه ${i + 1} ایجاد نشد');
        }

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (context) {
              return pw.SizedBox(
                width: PdfPageFormat.a4.width,
                height: PdfPageFormat.a4.height,
                child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.fill),
              );
            },
          ),
        );
      }

      controller.goToPage(oldPage);

      final pdfBytes = await pdf.save();

      // انتخاب پوشه
      final directory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'انتخاب محل ذخیره PDF',
      );

      if (directory == null) {
        return;
      }

      final now = Jalali.now();

      final dateTime =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_'
          '${DateTime.now().hour.toString().padLeft(2, '0')}-'
          '${DateTime.now().minute.toString().padLeft(2, '0')}-'
          '${DateTime.now().second.toString().padLeft(2, '0')}';

      final title = _titleController.text.trim();

      final fileName = '${title.isEmpty ? "note" : title}_$dateTime.pdf';

      final file = File('$directory${Platform.pathSeparator}$fileName');

      await file.writeAsBytes(pdfBytes, flush: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF با موفقیت ذخیره شد\n${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در خروجی PDF\n$e')));
    }
  }

  Future<void> _showAutoSaveHistory() async {
    final history = await _autoSaveService.getHistory();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,

      showDragHandle: true,

      isScrollControlled: true,

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                const Text(
                  'تاریخچه یادداشت‌ها',

                  textAlign: TextAlign.right,

                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                if (history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: Text('هنوز یادداشتی ذخیره نشده است.')),
                  ),

                ...history.map((item) {
                  return Card(
                    elevation: 0,

                    child: ListTile(
                      leading: const Icon(Icons.description_outlined),

                      title: Text(
                        item.title.isEmpty ? 'بدون عنوان' : item.title,
                      ),

                      subtitle: Text(
                        '${item.fileName}\n'
                        '${_formatDateTime(item.updatedAt)}',
                      ),

                      isThreeLine: true,

                      trailing: const Icon(Icons.chevron_left),

                      onTap: () async {
                        Navigator.pop(context);

                        await _restoreHistoryItem(item.id);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime date) {
    final d = date.toLocal();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${d.year}/${two(d.month)}/${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _restoreHistoryItem(String id) async {
    final controller = context.read<DrawingController>();

    final data = await _autoSaveService.load(id);

    if (data == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فایل یادداشت پیدا نشد.')));

      return;
    }

    controller.loadAutoSaveData(data);

    _titleController.text = controller.title;

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('یادداشت بازیابی شد.')));
  }
}

class _SmartPadPainter extends CustomPainter {
  final List<StrokeModel> pageStrokes;
  final List<StrokeModel> smartStrokes;
  final Rect target;
  final Color penColor;

  const _SmartPadPainter({
    required this.pageStrokes,
    required this.smartStrokes,
    required this.target,
    required this.penColor,
  });

  static final double _pageWidth = DrawingPainter.basePageWidth;
  static final double _pageHeight = DrawingPainter.basePageHeight;
  static const double _padWidth = 1000.0;
  static const double _padHeight = 520.0;

  Paint _paintFor(StrokeModel stroke) {
    final paint = Paint()
      ..strokeWidth = stroke.width.clamp(1.0, 20.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    switch (stroke.type) {
      case StrokeType.pen:
        paint.color = stroke.color;
        break;
      case StrokeType.highlighter:
        paint.color = stroke.color.withOpacity(.30);
        break;
      case StrokeType.eraser:
        paint.blendMode = BlendMode.clear;
        break;
    }

    return paint;
  }

  void _drawStroke(
    Canvas canvas,
    StrokeModel stroke,
    List<Offset> points,
    Paint paint,
  ) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      canvas.drawPoints(ui.PointMode.points, points, paint);
    } else {
      canvas.drawPoints(ui.PointMode.polygon, points, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.white, BlendMode.srcOver);

    final targetLeft = target.left * _pageWidth;
    final targetTop = target.top * _pageHeight;
    final targetWidth = target.width * _pageWidth;
    final targetHeight = target.height * _pageHeight;

    // بخش ذره‌بین: فقط محتوای زیر کادر آبی را برمی‌داریم و
    // آن را به اندازه کل کادر بزرگ می‌کنیم.
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    for (final stroke in pageStrokes) {
      if (stroke.points.isEmpty) continue;

      final points = stroke.points
          .map(
            (p) => Offset(
              (p.dx - targetLeft) * size.width / targetWidth,
              (p.dy - targetTop) * size.height / targetHeight,
            ),
          )
          .toList();

      final paint = _paintFor(stroke)
        ..strokeWidth = (stroke.width * size.width / targetWidth).clamp(
          .5,
          24.0,
        );

      _drawStroke(canvas, stroke, points, paint);
    }

    // Strokeهای تازه نوشته‌شده روی نمای ذره‌بین.
    for (final stroke in smartStrokes) {
      if (stroke.points.isEmpty) continue;

      final points = stroke.points
          .map(
            (p) => Offset(
              p.dx * size.width / _padWidth,
              p.dy * size.height / _padHeight,
            ),
          )
          .toList();

      final paint = _paintFor(stroke);
      _drawStroke(canvas, stroke, points, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SmartPadPainter oldDelegate) => true;
}

class _MappedSmartPadPainter extends CustomPainter {
  final List<StrokeModel> pageStrokes;
  final List<StrokeModel> smartStrokes;
  final Rect target;

  const _MappedSmartPadPainter({
    required this.pageStrokes,
    required this.smartStrokes,
    required this.target,
  });

  static final double _pageWidth = DrawingPainter.basePageWidth;
  static final double _pageHeight = DrawingPainter.basePageHeight;
  static const double _padWidth = 1000.0;
  static const double _padHeight = 520.0;

  Paint _paintFor(StrokeModel stroke, Size size, {double scale = 1.0}) {
    final paint = Paint()
      ..strokeWidth = (stroke.width * scale).clamp(.5, 20.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    switch (stroke.type) {
      case StrokeType.pen:
        paint.color = stroke.color;
        break;
      case StrokeType.highlighter:
        paint.color = stroke.color.withOpacity(.30);
        break;
      case StrokeType.eraser:
        paint.blendMode = BlendMode.clear;
        break;
    }

    return paint;
  }

  void _draw(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      canvas.drawPoints(ui.PointMode.points, points, paint);
    } else {
      canvas.drawPoints(ui.PointMode.polygon, points, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final targetLeft = target.left * _pageWidth;
    final targetTop = target.top * _pageHeight;
    final targetWidth = target.width * _pageWidth;
    final targetHeight = target.height * _pageHeight;

    // همان محتوای زیر کادر آبی، در خود کادر کوچک هم قابل مشاهده است.
    for (final stroke in pageStrokes) {
      if (stroke.points.isEmpty) continue;

      final points = stroke.points
          .map(
            (p) => Offset(
              (p.dx - targetLeft) * size.width / targetWidth,
              (p.dy - targetTop) * size.height / targetHeight,
            ),
          )
          .toList();

      _draw(
        canvas,
        points,
        _paintFor(stroke, size, scale: size.width / targetWidth),
      );
    }

    // Strokeهای جدید تا وقتی کادر بزرگ باز است نیز روی کادر کوچک دیده می‌شوند.
    for (final stroke in smartStrokes) {
      if (stroke.points.isEmpty) continue;

      final points = stroke.points
          .map(
            (p) => Offset(
              p.dx * size.width / _padWidth,
              p.dy * size.height / _padHeight,
            ),
          )
          .toList();

      _draw(canvas, points, _paintFor(stroke, size));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MappedSmartPadPainter oldDelegate) => true;
}

enum NoteType { note, meeting, letter, task }

class NoteTypeItem {
  final NoteType type;

  final String title;

  final IconData icon;

  const NoteTypeItem({
    required this.type,

    required this.title,

    required this.icon,
  });
}

const noteTypes = [
  NoteTypeItem(type: NoteType.note, title: "یادداشت", icon: Icons.edit_note),

  NoteTypeItem(type: NoteType.meeting, title: "صورت جلسه", icon: Icons.groups),
];
