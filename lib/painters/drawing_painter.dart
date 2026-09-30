import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:karnamaft/controllers/drawing_controller.dart';

import '../models/stroke.dart';

class DrawingPainter extends CustomPainter {
  final DrawingController controller;
  final double zoom;
  final bool landscape;

  DrawingPainter(this.controller, {this.zoom = 1.0, this.landscape = false})
    : super(repaint: controller);

  // ============================================================
  // Page dimensions
  // ============================================================

  static const double basePageWidth = 1000.0;

  static const double portraitRatio = 210 / 297;

  static const double landscapeRatio = 297 / 210;

  double get pageRatio {
    return landscape ? landscapeRatio : portraitRatio;
  }

  double get basePageHeight {
    return basePageWidth / pageRatio;
  }

  List<StrokeModel> get strokes {
    return controller.strokes;
  }

  // ============================================================
  // Paint
  // ============================================================

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final scale = size.width / basePageWidth;

    canvas.save();

    // تبدیل مختصات واقعی صفحه به مختصات Painter
    canvas.scale(scale);

    // ==========================================================
    // IMPORTANT:
    //
    // BlendMode.clear برای پاک‌کن زمانی قابل اعتماد است که
    // strokeها روی یک saveLayer جدا رسم شوند.
    //
    // بدون این لایه، BlendMode.clear در بعضی شرایط Flutter
    // مخصوصاً روی Canvasهای ترکیبی/CustomPaint به‌درستی عمل
    // نمی‌کند.
    // ==========================================================

    final layerBounds = Rect.fromLTWH(0, 0, basePageWidth, basePageHeight);

    canvas.saveLayer(layerBounds, Paint());

    // ==========================================================
    // Draw strokes
    // ==========================================================

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
          paint.blendMode = BlendMode.srcOver;
          break;

        case StrokeType.highlighter:
          paint.color = stroke.color.withOpacity(0.35);
          paint.blendMode = BlendMode.srcOver;
          break;

        case StrokeType.eraser:
          // پاک‌کن باید واقعاً شفاف کند تا محتوای زیر صفحه دیده شود.
          paint.color = Colors.transparent;
          paint.blendMode = BlendMode.clear;
          break;
      }

      // برای نقطه منفرد
      if (stroke.points.length == 1) {
        canvas.drawPoints(PointMode.points, stroke.points, paint);
      } else {
        // برای خطوط
        canvas.drawPoints(PointMode.polygon, stroke.points, paint);
      }
    }

    canvas.restore();

    canvas.restore();
  }

  // ============================================================
  // Repaint
  // ============================================================

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.zoom != zoom ||
        oldDelegate.landscape != landscape;
  }
}
