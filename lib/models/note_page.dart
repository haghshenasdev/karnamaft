import 'stroke.dart';

class NotePage {
  final List<StrokeModel> strokes;

  String text;

  NotePage({
    List<StrokeModel>? strokes,
    this.text = '',
  }) : strokes = strokes ?? [];
}