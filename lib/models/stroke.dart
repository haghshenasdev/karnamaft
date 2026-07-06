import 'dart:ui';

enum StrokeType { pen, highlighter, eraser }

class StrokeModel {
  StrokeModel({
    required this.points,
    required this.color,
    required this.width,
    this.type = StrokeType.pen,
  });

  final List<Offset> points;

  final Color color;

  final double width;

  final StrokeType type;
}
