import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:karnamaft/controllers/drawing_controller.dart';

import '../models/stroke.dart';

class DrawingPainter extends CustomPainter {
  final DrawingController controller;
  final double zoom;

  DrawingPainter(this.controller, {this.zoom = 1.0})
    : super(repaint: controller);

  static const double basePageWidth = 1000.0;
  static const double paperRatio = 210 / 297;

  static double get basePageHeight => basePageWidth / paperRatio;

  List<StrokeModel> get strokes => controller.strokes;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final scale = size.width / basePageWidth;

    canvas.save();

    canvas.scale(scale);

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) {
        continue;
      }

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

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.controller != controller || oldDelegate.zoom != zoom;
  }
}
