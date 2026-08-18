import 'stroke.dart';

class NotePage {
  final List<StrokeModel> strokes;

  String text;

  NotePage({List<StrokeModel>? strokes, this.text = ''})
    : strokes = strokes ?? [];

  Map<String, dynamic> toJson() {
    return {
      'text': text,

      'strokes': strokes.map((stroke) => stroke.toJson()).toList(),
    };
  }

  factory NotePage.fromJson(Map<String, dynamic> json) {
    return NotePage(
      text: json['text'] as String? ?? '',

      strokes: (json['strokes'] as List? ?? [])
          .map(
            (stroke) => StrokeModel.fromJson(Map<String, dynamic>.from(stroke)),
          )
          .toList(),
    );
  }
}
