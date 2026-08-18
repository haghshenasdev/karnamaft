import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:karnamaft/pages/minute_create_page.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:provider/provider.dart';

import '../controllers/drawing_controller.dart';
import '../models/note_page.dart';
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

class _HomePageState extends State<HomePage> {
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

  @override
  void dispose() {
    _titleController.dispose();

    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
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
          IconButton(
            tooltip: "ذخیره",
            onPressed: _saveNote,
            icon: const Icon(Icons.cloud_done_outlined),
          ),

          IconButton(
            tooltip: "یادداشت جدید",

            onPressed: () {},

            icon: const Icon(Icons.note_add_outlined),
          ),

          IconButton(
            tooltip: "تاریخچه",

            onPressed: () {},

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
            return Column(
              children: [
                //--------------------------------------------------
                // Header : Type + Category
                //--------------------------------------------------
                if (!controller.writingMode)
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

                                    dropdownMenuEntries: noteTypes.map((item) {
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
                        final double paperWidth = maxWritingPageWidth * _zoom;

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

                                  physics: const NeverScrollableScrollPhysics(),

                                  child: Center(
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
                                          width: paperWidth,
                                          height: paperHeight,
                                          color: Colors.white,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Consumer<DrawingController>(
                                                builder:
                                                    (context, controller, _) {
                                                      return NoteEditor(
                                                        controller: controller
                                                            .noteController,
                                                        enabled:
                                                            controller.textMode,
                                                        onChanged: controller
                                                            .savePageText,
                                                      );
                                                    },
                                              ),

                                              DrawingCanvas(
                                                controller: controller,
                                                zoom: _zoom,
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
                                        controller: controller.noteController,
                                        enabled: controller.textMode,
                                        onChanged: controller.savePageText,
                                      );
                                    },
                                  ),

                                  DrawingCanvas(controller: controller),
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

                  child: Row(
                    children: [
                      const SizedBox(width: 6),

                      //--------------------------------------------------
                      // Undo
                      //--------------------------------------------------
                      IconButton.filledTonal(
                        icon: const Icon(Icons.undo),

                        onPressed: controller.canUndo ? controller.undo : null,
                      ),

                      //--------------------------------------------------
                      // Redo
                      //--------------------------------------------------
                      IconButton.filledTonal(
                        icon: const Icon(Icons.redo),

                        onPressed: controller.canRedo ? controller.redo : null,
                      ),

                      const Spacer(),

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

                        onPressed: controller.toggleWritingMode,
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
                                  ? controller.previousPage
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

                              onPressed: controller.nextPage,

                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 6),

                      //--------------------------------------------------
                      // Send
                      //--------------------------------------------------
                      IconButton.filled(
                        tooltip: "ارسال",

                        onPressed: () {},

                        icon: const Icon(Icons.send),
                      ),

                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ],
            );
          },
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
      controller.clear();
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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MinuteCreatePage(
            initialFileBytes: fileBytes,
            initialFileName: fileName,
          ),
        ),
      );
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
