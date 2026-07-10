import 'package:flutter/material.dart';

class HighlightText extends StatelessWidget {
  final String text;

  final String keyword;

  final TextStyle? style;

  final TextStyle? highlightStyle;

  final int? maxLines;

  final TextOverflow overflow;

  final Color highlightColor;

  final BorderRadius borderRadius;

  final EdgeInsetsGeometry padding;

  const HighlightText({
    super.key,
    required this.text,
    required this.keyword,
    this.style,
    this.highlightStyle,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.highlightColor = const Color(0xfffff176),
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.padding = const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
  });

  @override
  Widget build(BuildContext context) {
    final normalStyle = style ?? DefaultTextStyle.of(context).style;

    if (keyword.trim().isEmpty) {
      return Text(
        text,
        style: normalStyle,
        maxLines: maxLines,
        overflow: overflow,
        textDirection: TextDirection.rtl,
      );
    }

    final source = text.toLowerCase();
    final search = keyword.toLowerCase();

    final spans = <InlineSpan>[];

    int start = 0;

    while (true) {
      final index = source.indexOf(search, start);

      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: normalStyle));
        }
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: normalStyle),
        );
      }

      final match = text.substring(index, index + keyword.length);

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: highlightColor,
              borderRadius: borderRadius,
            ),
            child: Text(
              match,
              style:
                  highlightStyle ??
                  normalStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
            ),
          ),
        ),
      );

      start = index + keyword.length;
    }

    return RichText(
      textDirection: TextDirection.rtl,
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(children: spans, style: normalStyle),
    );
  }
}
