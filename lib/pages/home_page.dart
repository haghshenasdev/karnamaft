import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/drawing_controller.dart';
import '../widgets/category_picker/category_picker.dart';
import '../widgets/drawing_canvas.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final TextEditingController _titleController = TextEditingController();

  static const double _paperRatio = 210 / 297;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,

        title: TextField(
          controller: _titleController,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: "عنوان یاداشت ...",
            border: InputBorder.none,
            hintStyle: TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.grey,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: "ذخیره",
            onPressed: () {},
            icon: const Icon(Icons.cloud_done_outlined),
          ),

          PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(value: "clear", child: Text("پاک کردن صفحه")),

              const PopupMenuItem(value: "pdf", child: Text("خروجی PDF")),

              const PopupMenuItem(value: "setting", child: Text("تنظیمات")),
            ],

            onSelected: (v) {
              switch (v) {
                case "clear":
                  _confirmClearPage(context);
                  break;
              }
            },
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            //--------------------------------------------------
            // Header
            //--------------------------------------------------
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
                      final typeWidth = (constraints.maxWidth * 0.34).clamp(
                        120.0,
                        160.0,
                      );

                      return Row(
                        children: [
                          //--------------------------------------------------
                          // نوع
                          //--------------------------------------------------
                          SizedBox(
                            width: typeWidth,
                            child: DropdownMenu<NoteType>(
                              width: typeWidth,
                              label: const Text("نوع"),
                              initialSelection: NoteType.note,
                              menuHeight: 400,
                              dropdownMenuEntries: noteTypes.map((item) {
                                return DropdownMenuEntry<NoteType>(
                                  value: item.type,
                                  label: item.title,
                                  leadingIcon: Icon(item.icon),
                                );
                              }).toList(),
                              onSelected: (value) {
                                // TODO
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          //--------------------------------------------------
                          // دسته بندی
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
            // کاغذ
            //--------------------------------------------------
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double maxWidth = constraints.maxWidth - 40;

                  double maxHeight = constraints.maxHeight - 24;

                  double width = maxWidth;

                  double height = width / _paperRatio;

                  if (height > maxHeight) {
                    height = maxHeight;
                    width = height * _paperRatio;
                  }

                  return Center(
                    child: Card(
                      elevation: 5,
                      color: Colors.white,
                      clipBehavior: Clip.antiAlias,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: SizedBox(
                        width: width,
                        height: height,

                        child: Stack(
                          children: [
                            //--------------------------------------------------
                            // Canvas
                            //--------------------------------------------------
                            Positioned.fill(
                              child: DrawingCanvas(
                                controller: context.read<DrawingController>(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            //--------------------------------------------------
            // Toolbar
            //--------------------------------------------------
            Consumer<DrawingController>(
              builder: (_, controller, __) {
                return Container(
                  height: 54,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),

                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                        color: Colors.black.withOpacity(.08),
                      ),
                    ],
                  ),

                  child: Consumer<DrawingController>(
                    builder: (_, controller, __) {
                      return Row(
                        children: [
                          const SizedBox(width: 8),

                          IconButton.filledTonal(
                            icon: const Icon(Icons.undo),
                            onPressed: controller.canUndo
                                ? controller.undo
                                : null,
                          ),

                          const SizedBox(width: 4),

                          IconButton.filledTonal(
                            icon: const Icon(Icons.redo),
                            onPressed: controller.canRedo
                                ? controller.redo
                                : null,
                          ),

                          const Spacer(),

                          IconButton.filledTonal(
                            onPressed: () {
                              _showPenDialog(context, controller);
                            },

                            icon: Icon(switch (controller.selectedTool) {
                              ToolType.pen => Icons.edit,

                              ToolType.highlighter => Icons.draw,

                              ToolType.eraser => Icons.auto_fix_off,
                            }, color: controller.penColor),
                          ),

                          const SizedBox(width: 12),

                          FilledButton.tonalIcon(
                            onPressed: () {
                              _showPages(context, controller);
                            },

                            icon: const Icon(Icons.article_outlined),

                            label: Text(
                              "${controller.currentPage + 1}/${controller.pageCount}",
                            ),
                          ),

                          const SizedBox(width: 12),

                          IconButton.filled(
                            onPressed: () {},

                            icon: const Icon(Icons.send),
                          ),

                          const SizedBox(width: 8),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),

                  const SizedBox(height: 12),

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

                  const SizedBox(height: 24),

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

                  const SizedBox(height: 24),

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

                    onChanged: (v) {
                      controller.setWidth(v);

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

  Future<void> showDeletePageDialog(
    BuildContext context,
    DrawingController controller,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.delete_outline, size: 36, color: Colors.red),
          title: const Text("حذف صفحه"),
          content: const Text(
            "آیا از حذف این صفحه مطمئن هستید؟\nاین عمل قابل بازگشت نیست.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("انصراف"),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete),
              label: const Text("حذف"),
            ),
          ],
        );
      },
    );

    if (result == true) {
      controller.removeCurrentPage();
    }
  }

  void _showPages(BuildContext context, DrawingController controller) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.chevron_left),
                title: const Text("صفحه قبل"),
                enabled: controller.canPrevious,
                onTap: () {
                  Navigator.pop(context);
                  controller.previousPage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.chevron_right),
                title: const Text("صفحه بعد"),
                onTap: () {
                  Navigator.pop(context);
                  controller.nextPage();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.note_add_outlined),
                title: const Text("صفحه جدید"),
                onTap: () {
                  Navigator.pop(context);

                  // اگر متد جداگانه‌ای برای ایجاد صفحه داری،
                  // اینجا آن را صدا بزن.
                  controller.nextPage();
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("حذف صفحه"),
                onTap: () {
                  showDeletePageDialog(
                    context,
                    context.read<DrawingController>(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmClearPage(BuildContext context) async {
    final controller = context.read<DrawingController>();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("پاک کردن صفحه"),
        content: const Text(
          "آیا از پاک کردن تمام نوشته‌های این صفحه مطمئن هستید؟",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("انصراف"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("پاک کن"),
          ),
        ],
      ),
    );

    if (result == true) {
      controller.clear();
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
