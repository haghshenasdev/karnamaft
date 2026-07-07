import 'package:flutter/material.dart';
import 'package:karnamaft/controllers/drawing_controller.dart';
import 'package:karnamaft/widgets/category_picker/category_model.dart';
import 'package:karnamaft/widgets/category_picker/category_picker.dart';
import 'package:provider/provider.dart';

import '../widgets/drawing_canvas.dart';
import 'dart:ui';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,

      body: SafeArea(
        child: Column(
          children: [
            //-----------------------------------
            // بالا
            //-----------------------------------
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "نام یادداشت",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 15),

                  SizedBox(
                    width: 180,
                    child: CategoryPicker(
                      selectedItems: [],
                      onChanged: (items) {
                        // setState(() {
                        //   selectedCategories = items;
                        // });
                      },
                    ),
                  ),
                ],
              ),
            ),

            //-----------------------------------
            // کاغذ
            //-----------------------------------
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const ratio = 210 / 297;

                  double maxWidth = constraints.maxWidth - 40;

                  double maxHeight = constraints.maxHeight - 40;

                  double width = maxWidth;

                  double height = width / ratio;

                  if (height > maxHeight) {
                    height = maxHeight;

                    width = height * ratio;
                  }

                  return Center(
                    child: Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 18,
                            color: Colors.black26,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: DrawingCanvas(
                        controller: context.read<DrawingController>(),
                      ),
                    ),
                  );
                },
              ),
            ),

            //-----------------------------------
            // پایین
            //-----------------------------------
            Container(
              height: 75,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Consumer<DrawingController>(
                builder: (_, controller, __) {
                  return Scrollbar(
                    thumbVisibility: true,
                    interactive: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          //-----------------------------------
                          // Undo
                          //-----------------------------------
                          IconButton(
                            tooltip: "Undo",
                            onPressed: controller.canUndo
                                ? controller.undo
                                : null,
                            icon: const Icon(Icons.undo),
                          ),

                          //-----------------------------------
                          // Redo
                          //-----------------------------------
                          IconButton(
                            tooltip: "Redo",
                            onPressed: controller.canRedo
                                ? controller.redo
                                : null,
                            icon: const Icon(Icons.redo),
                          ),

                          const SizedBox(width: 10),

                          //-----------------------------------
                          // پاک کردن صفحه
                          //-----------------------------------
                          IconButton(
                            tooltip: "Clear",
                            onPressed: controller.clear,
                            icon: const Icon(Icons.delete_outline),
                          ),

                          const VerticalDivider(),

                          //-----------------------------------
                          // رنگ ها
                          //-----------------------------------
                          ...[
                            Colors.black,
                            Colors.red,
                            Colors.green,
                            Colors.blue,
                            Colors.orange,
                            Colors.purple,
                            Colors.brown,
                          ].map(
                            (color) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => controller.setColor(color),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: controller.penColor == color
                                          ? Colors.black
                                          : Colors.grey.shade400,
                                      width: controller.penColor == color
                                          ? 3
                                          : 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: controller.penColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                          ),

                          const VerticalDivider(),

                          ToggleButtons(
                            borderRadius: BorderRadius.circular(10),
                            isSelected: [
                              controller.selectedTool == ToolType.pen,
                              controller.selectedTool == ToolType.highlighter,
                              controller.selectedTool == ToolType.eraser,
                            ],
                            onPressed: (index) {
                              switch (index) {
                                case 0:
                                  controller.setTool(ToolType.pen);
                                  break;

                                case 1:
                                  controller.setTool(ToolType.highlighter);
                                  break;

                                case 2:
                                  controller.setTool(ToolType.eraser);
                                  break;
                              }
                            },
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(Icons.edit),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(Icons.draw),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(Icons.auto_fix_off),
                              ),
                            ],
                          ),

                          const SizedBox(width: 15),

                          const Text(
                            "ضخامت",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(
                            width: 140,
                            child: Slider(
                              value: controller.penWidth,
                              min: 1,
                              max: 20,
                              divisions: 19,
                              label: controller.penWidth.toStringAsFixed(0),
                              onChanged: controller.setWidth,
                            ),
                          ),

                          const SizedBox(width: 15),

                          Chip(
                            avatar: const Icon(Icons.edit, size: 18),
                            label: Text(switch (controller.selectedTool) {
                              ToolType.pen => "قلم",
                              ToolType.highlighter => "هایلایتر",
                              ToolType.eraser => "پاک‌کن",
                            }),
                          ),

                          const SizedBox(width: 10),

                          SizedBox(
                            width: 40,
                            child: Center(
                              child: Text(
                                controller.penWidth.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 15),

                          SizedBox(
                            width: 50,
                            child: Center(
                              child: CustomPaint(
                                size: const Size(45, 30),
                                painter: _PenPreviewPainter(
                                  controller.penColor,
                                  controller.penWidth,
                                ),
                              ),
                            ),
                          ),

                          // به جای Spacer
                          const SizedBox(width: 40),

                          //-----------------------------------
                          // صفحات
                          //-----------------------------------
                          IconButton(
                            tooltip: "صفحه قبل",
                            icon: const Icon(Icons.chevron_left),
                            onPressed: controller.canPrevious
                                ? controller.previousPage
                                : null,
                          ),

                          Text(
                            "${controller.currentPage + 1} / ${controller.pageCount}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),

                          IconButton(
                            tooltip: "صفحه بعد",
                            icon: const Icon(Icons.chevron_right),
                            onPressed: controller.nextPage,
                          ),

                          IconButton(
                            tooltip: "صفحه جدید",
                            onPressed: controller.nextPage,
                            icon: const Icon(Icons.note_add_outlined),
                          ),

                          const SizedBox(width: 15),

                          FilledButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.send),
                            label: const Text("ارسال"),
                          ),

                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PenPreviewPainter extends CustomPainter {
  final Color color;

  final double width;

  const _PenPreviewPainter(this.color, this.width);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawLine(
      Offset(5, size.height / 2),
      Offset(size.width - 5, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PenPreviewPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.width != width;
  }
}
