import 'package:flutter/material.dart';

class FormattedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final bool softWrap;
  final TextOverflow overflow;
  final double textScaleFactor;
  final int? maxLines;

  const FormattedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor = 1.0,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle? effectiveTextStyle = style;
    if (style == null || style!.inherit) {
      effectiveTextStyle = defaultTextStyle.style.merge(style);
    }
    if (style == null) {
      effectiveTextStyle = defaultTextStyle.style;
    }

    final spans = _parseFormattedText(text, effectiveTextStyle!);

    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
      textDirection: textDirection,
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
    );
  }

  List<TextSpan> _parseFormattedText(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    int index = 0;
    bool isBold = false;
    bool isItalic = false;

    StringBuffer currentText = StringBuffer();

    void flush() {
      if (currentText.isNotEmpty) {
        spans.add(
          TextSpan(
            text: currentText.toString(),
            style: baseStyle.copyWith(
              fontWeight: isBold ? FontWeight.bold : baseStyle.fontWeight,
              fontStyle: isItalic ? FontStyle.italic : baseStyle.fontStyle,
            ),
          ),
        );
        currentText.clear();
      }
    }

    while (index < text.length) {
      if (text.startsWith('<b>', index)) {
        flush();
        isBold = true;
        index += 3;
      } else if (text.startsWith('</b>', index)) {
        flush();
        isBold = false;
        index += 4;
      } else if (text.startsWith('<i>', index)) {
        flush();
        isItalic = true;
        index += 3;
      } else if (text.startsWith('</i>', index)) {
        flush();
        isItalic = false;
        index += 4;
      } else if (text.startsWith('<strong>', index)) {
        flush();
        isBold = true;
        index += 8;
      } else if (text.startsWith('</strong>', index)) {
        flush();
        isBold = false;
        index += 9;
      } else if (text.startsWith('<em>', index)) {
        flush();
        isItalic = true;
        index += 4;
      } else if (text.startsWith('</em>', index)) {
        flush();
        isItalic = false;
        index += 5;
      } else if (text.startsWith('**', index)) {
        flush();
        isBold = !isBold;
        index += 2;
      } else if (text.startsWith('*', index)) {
        flush();
        isItalic = !isItalic;
        index += 1;
      } else {
        currentText.write(text[index]);
        index++;
      }
    }
    flush();

    return spans;
  }
}
