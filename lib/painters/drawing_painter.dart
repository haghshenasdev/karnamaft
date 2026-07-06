import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:karnamaft/controllers/drawing_controller.dart';

import '../models/stroke.dart';

class DrawingPainter extends CustomPainter {
  final DrawingController controller;

  DrawingPainter(this.controller) : super(repaint: controller);

  List<StrokeModel> get strokes => controller.strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      switch (stroke.type) {
        case StrokeType.pen:
          paint.color = stroke.color;
          break;

        case StrokeType.highlighter:
          paint.color = stroke.color.withOpacity(0.35);
          break;

        case StrokeType.eraser:
          paint.blendMode = BlendMode.clear;
          break;
      }

      if (stroke.points.length == 1) {
        canvas.drawPoints(PointMode.points, stroke.points, paint);
      } else {
        canvas.drawPoints(PointMode.polygon, stroke.points, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => false;
}
