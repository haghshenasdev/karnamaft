import 'package:flutter/material.dart';
import 'package:karnamaft/models/stroke.dart';
import 'package:provider/provider.dart';

import '../controllers/drawing_controller.dart';
import '../painters/drawing_painter.dart';

class DrawingCanvas extends StatelessWidget {
  final DrawingController controller;

  const DrawingCanvas({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Listener(
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
    );
  }
}
