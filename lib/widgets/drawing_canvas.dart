import 'dart:ui';

import 'package:flutter/material.dart';

import '../controllers/drawing_controller.dart';
import '../painters/drawing_painter.dart';

class DrawingCanvas extends StatelessWidget {
  final DrawingController controller;

  const DrawingCanvas({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return IgnorePointer(
          //---------------------------------------
          // وقتی حالت متن فعال است،
          // Canvas هیچ رویدادی دریافت نمی‌کند.
          //---------------------------------------
          ignoring: controller.textMode,

          child: Listener(
            behavior: HitTestBehavior.opaque,

            onPointerDown: (event) {
              controller.start(event.localPosition);
            },

            onPointerMove: (event) {
              controller.update(event.localPosition);
            },

            onPointerUp: (_) {
              controller.end();
            },

            child: RepaintBoundary(
              child: CustomPaint(
                painter: DrawingPainter(controller),
                size: Size.infinite,
                isComplex: true,
                willChange: true,
              ),
            ),
          ),
        );
      },
    );
  }
}
