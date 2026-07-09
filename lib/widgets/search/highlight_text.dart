import 'package:flutter/material.dart';

class HighlightText extends StatelessWidget {
  final String text;
  final String keyword;

  final TextStyle? style;

  final TextStyle? highlightStyle;

  final int? maxLines;

  final TextOverflow overflow;

  const HighlightText({
    super.key,
    required this.text,
    required this.keyword,
    this.style,
    this.highlightStyle,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    if (keyword.trim().isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final source = text.toLowerCase();
    final search = keyword.toLowerCase();

    final spans = <TextSpan>[];

    int start = 0;

    while (true) {
      final index = source.indexOf(search, start);

      if (index < 0) {
        spans.add(
          TextSpan(
            text: text.substring(start),
            style: style,
          ),
        );
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: style,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(
            index,
            index + keyword.length,
          ),
          style:
              highlightStyle ??
              TextStyle(
                backgroundColor: Colors.amber.shade300,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
        ),
      );

      start = index + keyword.length;
    }

    return RichText(
      maxLines: maxLines,
      overflow: overflow,
      textDirection: TextDirection.rtl,
      text: TextSpan(children: spans),
    );
  }
}