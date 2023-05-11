import 'package:extended_text_library/src/special_text_span.dart';
import 'package:extended_text_library/src/text_painter_helper.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class BackgroundTextSpan extends SpecialTextSpan {
  BackgroundTextSpan({
    TextStyle? style,
    required String text,
    GestureRecognizer? recognizer,
    required this.background,
    this.clipBorderRadius,
    this.paintBackground,
    String? actualText,
    int start = 0,
    bool deleteAll = false,
    String? semanticsLabel,
  })  : _textPainterHelper = TextPainterHelper(),
        super(
          style: style,
          text: text,
          recognizer: recognizer,
          actualText: actualText,
          start: start,
          deleteAll: deleteAll,
          semanticsLabel: semanticsLabel,
        );

  /// The paint drawn as a background for the text.
  ///
  /// The value should ideally be cached and reused each time if multiple text
  /// styles are created with the same paint settings. Otherwise, each time it
  /// will appear like the style changed, which will result in unnecessary
  /// updates all the way through the framework.
  ///
  /// workaround for 24335 issue
  /// https://github.com/flutter/flutter/issues/24335
  /// https://github.com/flutter/flutter/issues/24337
  /// we will draw background by ourself
  final Paint background;

  ///clip BorderRadius
  final BorderRadius? clipBorderRadius;

  ///paint background by yourself
  final PaintBackground? paintBackground;

  ///helper for textPainter
  final TextPainterHelper _textPainterHelper;

  TextPainter? layout(TextPainter painter) {
    return _textPainterHelper.layout(painter, this, compareChildren: false);
  }

  ///rect: all text size
  void paint(Canvas canvas, Offset offset, Rect rect,
      {Offset? endOffset, TextPainter? wholeTextPainter}) {
    assert(_textPainterHelper.painter != null);

    if (paintBackground != null) {
      final bool handle = paintBackground!(
          this, canvas, offset, _textPainterHelper.painter, rect,
          endOffset: endOffset, wholeTextPainter: wholeTextPainter);
      if (handle) {
        return;
      }
    }

    final Rect textRect = offset & _textPainterHelper.painter!.size;

    ///top-right
    if (endOffset != null) {
      final Rect firstLineRect = offset &
          Size(rect.right - offset.dx, _textPainterHelper.painter!.height);

      if (clipBorderRadius != null) {
        canvas.save();
        canvas.clipPath(Path()
          ..addRRect(BorderRadius.only(
                  topLeft: clipBorderRadius!.topLeft,
                  bottomLeft: clipBorderRadius!.bottomLeft)
              .resolve(_textPainterHelper.painter!.textDirection)
              .toRRect(firstLineRect)));
      }

      ///start
      canvas.drawRect(firstLineRect, background);

      if (clipBorderRadius != null) {
        canvas.restore();
      }

      ///endOffset.y has deviation,so we calculate with text height
      ///print(((endOffset.dy - offset.dy) / _painter.height));
      final int fullLinesAndLastLine =
          ((endOffset.dy - offset.dy) / _textPainterHelper.painter!.height)
              .round();

      double y = offset.dy;
      for (int i = 0; i < fullLinesAndLastLine; i++) {
        y += _textPainterHelper.painter!.height;
        //last line
        if (i == fullLinesAndLastLine - 1) {
          final Rect lastLineRect = Offset(0.0, y) &
              Size(endOffset.dx, _textPainterHelper.painter!.height);
          if (clipBorderRadius != null) {
            canvas.save();
            canvas.clipPath(Path()
              ..addRRect(BorderRadius.only(
                      topRight: clipBorderRadius!.topRight,
                      bottomRight: clipBorderRadius!.bottomRight)
                  .resolve(_textPainterHelper.painter!.textDirection)
                  .toRRect(lastLineRect)));
          }
          canvas.drawRect(lastLineRect, background);
          if (clipBorderRadius != null) {
            canvas.restore();
          }
        } else {
          ///draw full line
          canvas.drawRect(
              Offset(0.0, y) &
                  Size(rect.width, _textPainterHelper.painter!.height),
              background);
        }
      }
    } else {
      if (clipBorderRadius != null) {
        canvas.save();
        canvas.clipPath(Path()
          ..addRRect(clipBorderRadius!
              .resolve(_textPainterHelper.painter!.textDirection)
              .toRRect(textRect)));
      }

      canvas.drawRect(textRect, background);

      if (clipBorderRadius != null) {
        canvas.restore();
      }
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is BackgroundTextSpan &&
        other.text == text &&
        other.style == style &&
        other.recognizer == recognizer &&
        other.background == background &&
        other.clipBorderRadius == clipBorderRadius &&
        other.paintBackground == paintBackground;
  }

  @override
  int get hashCode => Object.hash(
        style,
        text,
        recognizer,
        background,
        clipBorderRadius,
        paintBackground,
      );

  @override
  RenderComparison compareTo(InlineSpan other) {
    if (other is BackgroundTextSpan) {
      if (other.background != background ||
          other.clipBorderRadius != clipBorderRadius ||
          other.paintBackground != paintBackground) {
        return RenderComparison.paint;
      }
    }

    return super.compareTo(other);
  }
}

///if you don't want use default, please return true.
///endOffset is the text top-right Offfset
///allTextPainter is the text painter of extended text.
///painter is current background text painter
typedef PaintBackground = bool Function(BackgroundTextSpan backgroundTextSpan,
    Canvas canvas, Offset offset, TextPainter? painter, Rect rect,
    {Offset? endOffset, TextPainter? wholeTextPainter});
