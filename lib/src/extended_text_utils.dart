import 'dart:math';
import 'dart:ui' as ui;

import 'package:extended_text_library/src/background_text_span.dart';
import 'package:extended_text_library/src/extended_widget_span.dart';
import 'package:extended_text_library/src/special_inline_span_base.dart';
import 'package:extended_text_library/src/special_text_span.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

extension ExtendedTextLibraryExtension on String {
  String joinChar([String char = ExtendedTextLibraryUtils.zeroWidthSpace]) =>
      Characters(this).join(char);
}

class ExtendedTextLibraryUtils {
  ExtendedTextLibraryUtils._();

  static const String zeroWidthSpace = '\u{200B}';
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
    final Offset? offset = textParentData.offset;
    if (offset == null) {
      return false;
    }
    final Matrix4 transform = Matrix4.translationValues(
        offset.dx + effectiveOffset.dx, offset.dy + effectiveOffset.dy, 0.0);
    final bool isHit = result.addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        assert(() {
          final Offset manualPosition = position - offset - effectiveOffset;
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

  static TextPosition convertTextInputPostionToTextPainterPostion(
      InlineSpan text, TextPosition textPosition) {
    int caretOffset = textPosition.offset;
    int textOffset = 0;
    text.visitChildren((InlineSpan ts) {
      if (ts is SpecialInlineSpanBase) {
        final int length = (ts as SpecialInlineSpanBase).actualText.length;
        caretOffset -= length - getInlineOffset(ts);
        textOffset += length;
      } else {
        textOffset += getInlineOffset(ts);
      }
      if (textOffset >= textPosition.offset) {
        return false;
      }
      return true;
    });
    if (caretOffset != textPosition.offset) {
      return TextPosition(
          offset: max(0, caretOffset), affinity: textPosition.affinity);
    }

    return textPosition;
  }

  static TextSelection convertTextInputSelectionToTextPainterSelection(
      InlineSpan text, TextSelection selection) {
    if (selection.isValid) {
      if (selection.isCollapsed) {
        final TextPosition extent =
            convertTextInputPostionToTextPainterPostion(text, selection.extent);
        if (selection.extent != extent) {
          selection = selection.copyWith(
              baseOffset: extent.offset,
              extentOffset: extent.offset,
              affinity: selection.affinity,
              isDirectional: selection.isDirectional);
          return selection;
        }
      } else {
        final TextPosition extent =
            convertTextInputPostionToTextPainterPostion(text, selection.extent);

        final TextPosition base =
            convertTextInputPostionToTextPainterPostion(text, selection.base);

        if (selection.extent != extent || selection.base != base) {
          selection = selection.copyWith(
              baseOffset: base.offset,
              extentOffset: extent.offset,
              affinity: selection.affinity,
              isDirectional: selection.isDirectional);
          return selection;
        }
      }
    }

    return selection;
  }

  static TextPosition? convertTextPainterPostionToTextInputPostion(
      InlineSpan text, TextPosition? textPosition,
      {bool? end}) {
    if (textPosition != null) {
      int caretOffset = textPosition.offset;
      if (caretOffset <= 0) {
        return textPosition;
      }
      int textOffset = 0;
      text.visitChildren((InlineSpan ts) {
        if (ts is SpecialInlineSpanBase) {
          final SpecialInlineSpanBase specialTs = ts as SpecialInlineSpanBase;
          final int length = specialTs.actualText.length;
          caretOffset += length - getInlineOffset(ts);

          ///make sure caret is not in text when deleteAll is true
          if (specialTs.deleteAll &&
              caretOffset >= specialTs.start &&
              caretOffset <= specialTs.end) {
            if (end != null) {
              caretOffset = end ? specialTs.end : specialTs.start;
            } else {
              if (caretOffset >
                  (specialTs.end - specialTs.start) / 2.0 + specialTs.start) {
                //move caretOffset to end
                caretOffset = specialTs.end;
              } else {
                caretOffset = specialTs.start;
              }
            }
            return false;
          }
        }
        textOffset += getInlineOffset(ts);

        if (textOffset >= textPosition.offset) {
          return false;
        }
        return true;
      });

      if (caretOffset != textPosition.offset) {
        return TextPosition(
            offset: caretOffset, affinity: textPosition.affinity);
      }
    }
    return textPosition;
  }

  static TextSelection convertTextPainterSelectionToTextInputSelection(
      InlineSpan text, TextSelection selection,
      {bool selectWord = false}) {
    if (selection.isValid) {
      if (selection.isCollapsed) {
        final TextPosition? extent =
            convertTextPainterPostionToTextInputPostion(text, selection.extent);
        if (selection.extent != extent) {
          selection = selection.copyWith(
              baseOffset: extent!.offset,
              extentOffset: extent.offset,
              affinity: selection.affinity,
              isDirectional: selection.isDirectional);
          return selection;
        }
      } else {
        final TextPosition? extent =
            convertTextPainterPostionToTextInputPostion(text, selection.extent,
                end: selectWord ? true : null);

        final TextPosition? base = convertTextPainterPostionToTextInputPostion(
            text, selection.base,
            end: selectWord ? false : null);

        if (selection.extent != extent || selection.base != base) {
          selection = selection.copyWith(
              baseOffset: base!.offset,
              extentOffset: extent!.offset,
              affinity: selection.affinity,
              isDirectional: selection.isDirectional);
          return selection;
        }
      }
    }

    return selection;
  }

  static TextPosition makeSureCaretNotInSpecialText(
      InlineSpan text, TextPosition textPosition) {
    int caretOffset = textPosition.offset;
    if (caretOffset <= 0) {
      return textPosition;
    }

    int textOffset = 0;
    text.visitChildren((InlineSpan ts) {
      if (ts is SpecialInlineSpanBase) {
        final SpecialInlineSpanBase specialTs = ts as SpecialInlineSpanBase;

        ///make sure caret is not in text when deleteAll is true
        if (specialTs.deleteAll &&
            caretOffset >= specialTs.start &&
            caretOffset <= specialTs.end) {
          if (caretOffset >
              (specialTs.end - specialTs.start) / 2.0 + specialTs.start) {
            //move caretOffset to end
            caretOffset = specialTs.end;
          } else {
            caretOffset = specialTs.start;
          }
          return false;
        }
      }
      textOffset += getInlineOffset(ts);
      if (textOffset >= textPosition.offset) {
        return false;
      }
      return true;
    });

    if (caretOffset != textPosition.offset) {
      return TextPosition(offset: caretOffset, affinity: textPosition.affinity);
    }

    return textPosition;
  }

//double getImageSpanCorrectPosition(
//    ExtendedWidgetSpan widgetSpan, TextDirection direction) {
//  // var correctPosition = image.width / 2.0;
//  //if (direction == TextDirection.rtl) correctPosition = -correctPosition;
//  return 15.0;
//  //return correctPosition;
//}

  /// correct caret Offset
  /// make sure caret is not in text when caretIn is false
  static TextEditingValue correctCaretOffset(
    TextEditingValue value,
    InlineSpan textSpan,
    TextInputConnection? textInputConnection, {
    TextEditingValue? oldValue,
  }) {
    final TextSelection selection = value.selection;

    if (selection.isValid && selection.isCollapsed) {
      int caretOffset = selection.extentOffset;

      // move to previous or next
      // https://github.com/fluttercandies/extended_text_field/issues/210
      bool? movePrevious;
      if (oldValue != null) {
        final TextSelection oldSelection = oldValue.selection;
        if (oldSelection.isValid && oldSelection.isCollapsed) {
          final int moveOffset = selection.baseOffset - oldSelection.baseOffset;

          if (moveOffset < 0) {
            movePrevious = true;
          } else if (moveOffset > 0) {
            movePrevious = false;
          }
        }
      }

      // correct caret Offset
      // make sure caret is not in text when deleteAll is true
      //
      textSpan.visitChildren((InlineSpan span) {
        if (span is SpecialInlineSpanBase &&
            (span as SpecialInlineSpanBase).deleteAll) {
          final SpecialInlineSpanBase specialTs = span as SpecialInlineSpanBase;
          if (caretOffset >= specialTs.start && caretOffset <= specialTs.end) {
            if (movePrevious != null) {
              if (movePrevious) {
                caretOffset = specialTs.start;
              } else {
                caretOffset = specialTs.end;
              }
            } else {
              if (caretOffset >
                  (specialTs.end - specialTs.start) / 2.0 + specialTs.start) {
                //move caretOffset to end
                caretOffset = specialTs.end;
              } else {
                caretOffset = specialTs.start;
              }
            }

            return false;
          }
        }
        return true;
      });

      ///tell textInput caretOffset is changed.
      if (caretOffset != selection.baseOffset) {
        value = value.copyWith(
            selection: selection.copyWith(
                baseOffset: caretOffset, extentOffset: caretOffset));
        textInputConnection?.setEditingState(value);
      }
    }
    return value;
  }

  static TextEditingValue handleSpecialTextSpanDelete(
      TextEditingValue value,
      TextEditingValue? oldValue,
      InlineSpan oldTextSpan,
      TextInputConnection? textInputConnection) {
    final String? oldText = oldValue?.text;
    String newText = value.text;

    ///take care of image span
    if (oldText != null && oldText.length > newText.length) {
      final int difStart = value.selection.extentOffset;
      //int difEnd = oldText.length - 1;
      // for (; difStart < newText.length; difStart++) {
      //   if (oldText[difStart] != newText[difStart]) {
      //     break;
      //   }
      // }

      int caretOffset = value.selection.extentOffset;
      if (difStart > 0) {
        oldTextSpan.visitChildren((InlineSpan span) {
          if (span is SpecialInlineSpanBase &&
              (span as SpecialInlineSpanBase).deleteAll) {
            final SpecialInlineSpanBase specialTs =
                span as SpecialInlineSpanBase;
            if (difStart > specialTs.start && difStart < specialTs.end) {
              //difStart = ts.start;
              newText = newText.replaceRange(specialTs.start, difStart, '');
              caretOffset -= difStart - specialTs.start;
              return false;
            }
          }
          return true;
        });

        if (newText != value.text) {
          value = TextEditingValue(
              text: newText,
              selection: value.selection.copyWith(
                  baseOffset: caretOffset,
                  extentOffset: caretOffset,
                  affinity: value.selection.affinity,
                  isDirectional: value.selection.isDirectional));
          textInputConnection?.setEditingState(value);
        }
      }
    }

    return value;
  }

//bool hasSpecialText(List<TextSpan> value) {
//  if (value == null) return false;
//
//  for (var textSpan in value) {
//    if (textSpan is SpecialTextSpan) return true;
//    if (hasSpecialText(textSpan.children)) {
//      return true;
//    }
//  }
//  return false;
//}

  static bool hasSpecialText(InlineSpan textSpan) {
    return hasT<SpecialInlineSpanBase>(textSpan);
  }

  static bool hasT<T>(InlineSpan? textSpan) {
    if (textSpan == null) {
      return false;
    }
    if (textSpan is T) {
      return true;
    }
    if (textSpan is TextSpan && textSpan.children != null) {
      for (final InlineSpan ts in textSpan.children!) {
        final bool has = hasT<T>(ts);
        if (has) {
          return true;
        }
      }
    }
    return false;
  }

// void textSpanNestToArray(InlineSpan? textSpan, List<InlineSpan> list) {
//   if (textSpan == null) {
//     return;
//   }
//   list.add(textSpan);
//   if (textSpan is TextSpan && textSpan.children != null) {
//     for (final InlineSpan ts in textSpan.children!) {
//       textSpanNestToArray(ts, list);
//     }
//   }
// }
// List<InlineSpan> textSpanNestToArray(InlineSpan inlineSpan,
//     {bool Function(InlineSpan element)? test}) {
//   final List<InlineSpan> list = <InlineSpan>[];
//   inlineSpan.visitChildren((InlineSpan span) {
//     if (test?.call(span) ?? true) {
//       list.add(span);
//     }
//     return true;
//   });

//   return list;
// }

  static String textSpanToActualText(InlineSpan textSpan) {
    final StringBuffer buffer = StringBuffer();

    textSpan.visitChildren((InlineSpan span) {
      if (span is SpecialInlineSpanBase) {
        buffer.write((span as SpecialInlineSpanBase).actualText);
      } else {
        // ignore: invalid_use_of_protected_member
        span.computeToPlainText(buffer);
      }
      return true;
    });
    return buffer.toString();
  }

  /// Walks this text span and its descendants in pre-order and calls [visitor]
  /// for each span that has text.
// bool _visitTextSpan(InlineSpan textSpan, bool visitor(InlineSpan span)) {
//   String? text = getInlineText(textSpan);
//   if (textSpan is SpecialInlineSpanBase) {
//     text = (textSpan as SpecialInlineSpanBase).actualText;
//   }
//   if (text != null) {
//     if (!visitor(textSpan)) {
//       return false;
//     }
//   }
//   if (textSpan is TextSpan && textSpan.children != null) {
//     for (final InlineSpan child in textSpan.children!) {
//       if (!_visitTextSpan(child, visitor)) {
//         return false;
//       }
//       //if (!child.visitTextSpan(visitor)) return false;
//     }
//   }
//   return true;
// }

  static int getInlineOffset(InlineSpan inlineSpan) {
    if (inlineSpan is TextSpan && inlineSpan.text != null) {
      return inlineSpan.text!.length;
    }
    if (inlineSpan is PlaceholderSpan) {
      return 1;
    }
    return 0;
  }

// String? getInlineText(InlineSpan inlineSpan) {
//   if (inlineSpan is TextSpan && inlineSpan.text != null) {
//     return inlineSpan.text;
//   }
//   if (inlineSpan is PlaceholderSpan) {
//     return '\uFFFC';
//   }
//   return '';
// }

  /// join char into text
  static InlineSpan joinChar(
    InlineSpan value,
    Accumulator offset,
    String char,
  ) {
    late InlineSpan output;
    String? actualText;

    bool deleteAll = false;
    if (value is SpecialInlineSpanBase) {
      final SpecialInlineSpanBase base = value as SpecialInlineSpanBase;
      actualText = base.actualText;
      deleteAll = base.deleteAll;
    } else {
      deleteAll = false;
    }
    if (value is TextSpan) {
      List<InlineSpan>? children;
      final int start = offset.value;
      String? text = value.text;
      actualText ??= text;
      if (actualText != null) {
        actualText = actualText.joinChar();
        offset.increment(actualText.length);
      }

      if (text != null) {
        text = text.joinChar();
      }

      if (value.children != null) {
        children = <InlineSpan>[];
        for (final InlineSpan child in value.children!) {
          children.add(joinChar(child, offset, char));
        }
      }

      if (value is BackgroundTextSpan) {
        output = BackgroundTextSpan(
          background: value.background,
          clipBorderRadius: value.clipBorderRadius,
          paintBackground: value.paintBackground,
          text: text ?? '',
          actualText: actualText,
          start: start,
          style: value.style,
          recognizer: value.recognizer,
          deleteAll: deleteAll,
          semanticsLabel: value.semanticsLabel,
        );
      } else {
        output = SpecialTextSpan(
          text: text ?? '',
          actualText: actualText,
          children: children,
          start: start,
          style: value.style,
          recognizer: value.recognizer,
          deleteAll: deleteAll,
          semanticsLabel: value.semanticsLabel,
        );
      }
    } else if (value is WidgetSpan) {
      output = ExtendedWidgetSpan(
        child: value.child,
        start: offset.value,
        alignment: value.alignment,
        style: value.style,
        baseline: value.baseline,
        actualText: actualText,
      );

      offset.increment(actualText?.length ?? 1);
    } else {
      output = value;
    }

    return output;
  }

// move by keyboard left -1 and right +1
// make sure keyboard left/right support for SpecialInlineSpan
  static TextSelection convertKeyboardMoveSelection(
    InlineSpan text,
    TextSelection selection,
  ) {
    if (selection.isValid) {
      if (selection.isCollapsed) {
        final TextPosition? extent = convertKeyboardMoveTextPostion(
          text,
          selection.extent,
        );
        if (selection.extent != extent) {
          selection = selection.copyWith(
              baseOffset: extent!.offset,
              extentOffset: extent.offset,
              affinity: selection.affinity,
              isDirectional: selection.isDirectional);
          return selection;
        }
      } else {
        final TextPosition? extent = convertKeyboardMoveTextPostion(
          text,
          selection.extent,
        );

        final TextPosition? base = convertKeyboardMoveTextPostion(
          text,
          selection.base,
        );

        if (selection.extent != extent || selection.base != base) {
          selection = selection.copyWith(
              baseOffset: base!.offset,
              extentOffset: extent!.offset,
              affinity: selection.affinity,
              isDirectional: selection.isDirectional);
          return selection;
        }
      }
    }

    return selection;
  }

  /// move by keyboard left -1 and right +1
  /// make sure keyboard left/right support for SpecialInlineSpan
  static TextPosition? convertKeyboardMoveTextPostion(
    InlineSpan text,
    TextPosition? textPosition,
  ) {
    if (textPosition != null) {
      int caretOffset = textPosition.offset;
      if (caretOffset <= 0) {
        return textPosition;
      }
      int textOffset = 0;
      text.visitChildren((InlineSpan ts) {
        if (ts is SpecialInlineSpanBase) {
          final SpecialInlineSpanBase specialTs = ts as SpecialInlineSpanBase;
          final int length = specialTs.actualText.length;
          textOffset += length;

          ///make sure caret is not in text when deleteAll is true
          if (specialTs.deleteAll &&
              caretOffset >= specialTs.start &&
              caretOffset <= specialTs.end) {
            if (caretOffset == specialTs.start ||
                caretOffset == specialTs.end) {
              return false;
            } else if (caretOffset == specialTs.start + 1) {
              caretOffset = specialTs.end;
            } else if (caretOffset == specialTs.end - 1) {
              caretOffset = specialTs.start;
            }
            return false;
          }
        } else {
          textOffset += getInlineOffset(ts);
        }

        if (textOffset >= textPosition.offset) {
          return false;
        }
        return true;
      });

      if (caretOffset != textPosition.offset) {
        return TextPosition(
            offset: caretOffset, affinity: textPosition.affinity);
      }
    }
    return textPosition;
  }
}
