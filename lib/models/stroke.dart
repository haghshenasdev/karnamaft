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

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((point) => {'x': point.dx, 'y': point.dy}).toList(),

      'color': color.value,

      'width': width,

      'type': type.name,
    };
  }

  factory StrokeModel.fromJson(Map<String, dynamic> json) {
    final points = (json['points'] as List)
        .map(
          (point) => Offset(
            (point['x'] as num).toDouble(),
            (point['y'] as num).toDouble(),
          ),
        )
        .toList();

    return StrokeModel(
      points: points,

      color: Color((json['color'] as num).toInt()),

      width: (json['width'] as num).toDouble(),

      type: StrokeType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => StrokeType.pen,
      ),
    );
  }
}
