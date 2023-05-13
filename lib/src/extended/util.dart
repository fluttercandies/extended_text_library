import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ExtendedTextLibraryUtil {
  ExtendedTextLibraryUtil._();
  // it seems TextPainter works for WidgetSpan on 1.17.0
  // code under 1.17.0
  static Offset getCaretOffset(
    TextPosition textPosition,
    TextPainter textPainter,
    bool hasPlaceholderSpan, {
    ValueChanged<double>? caretHeightCallBack,
    Offset? effectiveOffset,
    Rect caretPrototype = Rect.zero,
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) {
    effectiveOffset ??= Offset.zero;

    ///zmt
    /// fix widget span
    if (hasPlaceholderSpan) {
      ///if first index, check by first span
      int offset = textPosition.offset;
      List<TextBox> boxs = textPainter.getBoxesForSelection(
        TextSelection(
            baseOffset: offset,
            extentOffset: offset + 1,
            affinity: textPosition.affinity),
        boxWidthStyle: boxWidthStyle,
        boxHeightStyle: boxHeightStyle,
      );
      if (boxs.isNotEmpty) {
        final Rect rect = boxs.toList().last.toRect();
        caretHeightCallBack?.call(rect.height);
        return rect.topLeft + effectiveOffset;
      } else {
        if (offset <= 0) {
          offset = 1;
        }
        boxs = textPainter.getBoxesForSelection(
          TextSelection(
            baseOffset: offset - 1,
            extentOffset: offset,
            affinity: textPosition.affinity,
          ),
          boxWidthStyle: boxWidthStyle,
          boxHeightStyle: boxHeightStyle,
        );
        if (boxs.isNotEmpty) {
          final Rect rect = boxs.toList().last.toRect();
          caretHeightCallBack?.call(rect.height);
          if (textPosition.offset <= 0) {
            return rect.topLeft + effectiveOffset;
          } else {
            return rect.topRight + effectiveOffset;
          }
        }
      }
    }

    final Offset caretOffset =
        textPainter.getOffsetForCaret(textPosition, caretPrototype) +
            effectiveOffset;
    return caretOffset;
  }

  static bool hitTestChild(
    BoxHitTestResult result,
    RenderBox child,
    Offset effectiveOffset, {
    required Offset position,
  }) {
    final TextParentData textParentData = child.parentData as TextParentData;
    final Matrix4 transform = Matrix4.translationValues(
        textParentData.offset.dx + effectiveOffset.dx,
        textParentData.offset.dy + effectiveOffset.dy,
        0.0)
      ..scale(
        textParentData.scale,
        textParentData.scale,
        textParentData.scale,
      );
    final bool isHit = result.addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        assert(() {
          final Offset manualPosition =
              (position - textParentData.offset - effectiveOffset) /
                  textParentData.scale!;
          return (transformed.dx - manualPosition.dx).abs() <
                  precisionErrorTolerance &&
              (transformed.dy - manualPosition.dy).abs() <
                  precisionErrorTolerance;
        }());
        return child.hitTest(result, position: transformed);
      },
    );
    return isHit;
  }

  static int getInlineOffset(InlineSpan inlineSpan) {
    if (inlineSpan is TextSpan && inlineSpan.text != null) {
      return inlineSpan.text!.length;
    }
    if (inlineSpan is PlaceholderSpan) {
      return 1;
    }
    return 0;
  }
}
