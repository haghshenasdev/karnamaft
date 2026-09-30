import 'stroke.dart';

class NotePage {
  final List<StrokeModel> strokes;
  String text;

  /// مسیر تصویر زمینه فرم/برگه.
  String? backgroundImagePath;

  /// false = عمودی A4، true = افقی A4.
  bool landscape;

  NotePage({
    List<StrokeModel>? strokes,
    this.text = '',
    this.backgroundImagePath,
    this.landscape = false,
  }) : strokes = strokes ?? [];

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'backgroundImagePath': backgroundImagePath,
      'landscape': landscape,
      'strokes': strokes.map((stroke) => stroke.toJson()).toList(),
    };
  }

  factory NotePage.fromJson(Map<String, dynamic> json) {
    return NotePage(
      text: json['text'] as String? ?? '',
      backgroundImagePath: json['backgroundImagePath']?.toString(),
      landscape: json['landscape'] == true,
      strokes: (json['strokes'] as List? ?? [])
          .map((stroke) => StrokeModel.fromJson(Map<String, dynamic>.from(stroke)))
          .toList(),
    );
  }
}
