import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'special_inline_span_base.dart';

TextPosition convertTextInputPostionToTextPainterPostion(
    InlineSpan text, TextPosition textPosition) {
  final List<InlineSpan> list = <InlineSpan>[];
  textSpanNestToArray(text, list);
  if (list.isNotEmpty) {
    int caretOffset = textPosition.offset;
    int textOffset = 0;
    for (final InlineSpan ts in list) {
      if (ts is SpecialInlineSpanBase) {
        final int length = (ts as SpecialInlineSpanBase).actualText.length;
        caretOffset -= length - getInlineOffset(ts);
        textOffset += length;
      } else {
        textOffset += getInlineOffset(ts);
      }
      if (textOffset >= textPosition.offset) {
        break;
      }
    }
    if (caretOffset != textPosition.offset) {
      return TextPosition(
          offset: max(0, caretOffset), affinity: textPosition.affinity);
    }
  }
  return textPosition;
}

TextSelection convertTextInputSelectionToTextPainterSelection(
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

TextPosition convertTextPainterPostionToTextInputPostion(
    InlineSpan text, TextPosition textPosition,
    {bool end}) {
  final List<InlineSpan> list = <InlineSpan>[];
  textSpanNestToArray(text, list);
  if (list.isNotEmpty && textPosition != null) {
    int caretOffset = textPosition.offset;
    if (caretOffset <= 0) {
      return textPosition;
    }

    int textOffset = 0;
    for (final InlineSpan ts in list) {
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

          break;
        }
      }
      textOffset += getInlineOffset(ts);
      if (textOffset >= textPosition.offset) {
        break;
      }
    }
    if (caretOffset != textPosition.offset) {
      return TextPosition(offset: caretOffset, affinity: textPosition.affinity);
    }
  }
  return textPosition;
}

TextSelection convertTextPainterSelectionToTextInputSelection(
    InlineSpan text, TextSelection selection,
    {bool selectWord = false}) {
  if (selection.isValid) {
    if (selection.isCollapsed) {
      final TextPosition extent =
          convertTextPainterPostionToTextInputPostion(text, selection.extent);
      if (selection.extent != extent) {
        selection = selection.copyWith(
            baseOffset: extent.offset,
            extentOffset: extent.offset,
            affinity: selection.affinity,
            isDirectional: selection.isDirectional);
        return selection;
      }
    } else {
      final TextPosition extent = convertTextPainterPostionToTextInputPostion(
          text, selection.extent,
          end: selectWord ? true : null);

      final TextPosition base = convertTextPainterPostionToTextInputPostion(
          text, selection.base,
          end: selectWord ? false : null);

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

TextPosition makeSureCaretNotInSpecialText(
    InlineSpan text, TextPosition textPosition) {
  final List<InlineSpan> list = <InlineSpan>[];
  textSpanNestToArray(text, list);
  if (list.isNotEmpty && textPosition != null) {
    int caretOffset = textPosition.offset;
    if (caretOffset <= 0) {
      return textPosition;
    }

    int textOffset = 0;
    for (final InlineSpan ts in list) {
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
          break;
        }
      }
      textOffset += getInlineOffset(ts);
      if (textOffset >= textPosition.offset) {
        break;
      }
    }
    if (caretOffset != textPosition.offset) {
      return TextPosition(offset: caretOffset, affinity: textPosition.affinity);
    }
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

///correct caret Offset
///make sure caret is not in text when caretIn is false
TextEditingValue correctCaretOffset(TextEditingValue value, InlineSpan textSpan,
    TextInputConnection textInputConnection,
    {TextSelection newSelection}) {
  final List<InlineSpan> list = <InlineSpan>[];
  textSpanNestToArray(textSpan, list);
  if (list.isEmpty) {
    return value;
  }

  final TextSelection selection = newSelection ?? value.selection;

  if (selection.isValid && selection.isCollapsed) {
    int caretOffset = selection.extentOffset;
    final Iterable<InlineSpan> specialTextSpans = list.where((InlineSpan x) =>
        x is SpecialInlineSpanBase && (x as SpecialInlineSpanBase).deleteAll);
    //correct caret Offset
    ///make sure caret is not in text when deleteAll is true
    for (final InlineSpan ts in specialTextSpans) {
      final SpecialInlineSpanBase specialTs = ts as SpecialInlineSpanBase;

      if (caretOffset >= specialTs.start && caretOffset <= specialTs.end) {
        if (caretOffset >
            (specialTs.end - specialTs.start) / 2.0 + specialTs.start) {
          //move caretOffset to end
          caretOffset = specialTs.end;
        } else {
          caretOffset = specialTs.start;
        }
        break;
      }
    }

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

TextEditingValue handleSpecialTextSpanDelete(
    TextEditingValue value,
    TextEditingValue oldValue,
    InlineSpan oldTextSpan,
    TextInputConnection textInputConnection) {
  final String oldText = oldValue?.text;
  String newText = value?.text;
  final List<InlineSpan> list = <InlineSpan>[];
  textSpanNestToArray(oldTextSpan, list);
  if (list.isNotEmpty) {
    final Iterable<InlineSpan> imageSpans = list.where((InlineSpan x) =>
        x is SpecialInlineSpanBase && (x as SpecialInlineSpanBase).deleteAll);

    ///take care of image span
    if (imageSpans.isNotEmpty &&
        oldText != null &&
        newText != null &&
        oldText.length > newText.length) {
      final int difStart = value.selection.extentOffset;
      //int difEnd = oldText.length - 1;
      // for (; difStart < newText.length; difStart++) {
      //   if (oldText[difStart] != newText[difStart]) {
      //     break;
      //   }
      // }

      int caretOffset = value.selection.extentOffset;
      if (difStart > 0) {
        for (final InlineSpan ts in imageSpans) {
          final SpecialInlineSpanBase specialTs = ts as SpecialInlineSpanBase;

          if (difStart > specialTs.start && difStart < specialTs.end) {
            //difStart = ts.start;
            newText = newText.replaceRange(specialTs.start, difStart, '');
            caretOffset -= difStart - specialTs.start;
            break;
          }
        }
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

bool hasSpecialText(InlineSpan textSpan) {
  final List<InlineSpan> list = <InlineSpan>[];
  textSpanNestToArray(textSpan, list);
  if (list.isEmpty) {
    return false;
  }

  //for performance, make sure your all SpecialTextSpan are only in textSpan.children
  //extended_text_field will only check textSpan.children
  return list.firstWhere((InlineSpan x) => x is SpecialInlineSpanBase,
          orElse: () => null) !=
      null;
}

void textSpanNestToArray(InlineSpan textSpan, List<InlineSpan> list) {
  assert(list != null);
  if (textSpan == null) {
    return;
  }
  list.add(textSpan);
  if (textSpan is TextSpan && textSpan.children != null) {
    for (final InlineSpan ts in textSpan.children) {
      textSpanNestToArray(ts, list);
    }
  }
}

String textSpanToActualText(InlineSpan textSpan
    //,{bool includeSemanticsLabels = true}
    ) {
  final StringBuffer buffer = StringBuffer();
  _visitTextSpan(textSpan, (InlineSpan span) {
//    if (span.semanticsLabel != null && includeSemanticsLabels) {
//      buffer.write(span.semanticsLabel);
//    } else
    {
      String text = getInlineText(span);
      if (span is SpecialInlineSpanBase) {
        text = (span as SpecialInlineSpanBase).actualText;
      }
      buffer.write(text);
    }
    return true;
  });
  return buffer.toString();
}

/// Walks this text span and its descendants in pre-order and calls [visitor]
/// for each span that has text.
bool _visitTextSpan(InlineSpan textSpan, bool visitor(InlineSpan span)) {
  String text = getInlineText(textSpan);
  if (textSpan is SpecialInlineSpanBase) {
    text = (textSpan as SpecialInlineSpanBase).actualText;
  }
  if (text != null) {
    if (!visitor(textSpan)) {
      return false;
    }
  }
  if (textSpan is TextSpan && textSpan.children != null) {
    for (final InlineSpan child in textSpan.children) {
      if (!_visitTextSpan(child, visitor)) {
        return false;
      }
      //if (!child.visitTextSpan(visitor)) return false;
    }
  }
  return true;
}

int getInlineOffset(InlineSpan inlineSpan) {
  if (inlineSpan is TextSpan && inlineSpan.text != null) {
    return inlineSpan.text.length;
  }
  if (inlineSpan is PlaceholderSpan) {
    return 1;
  }
  return 0;
}

String getInlineText(InlineSpan inlineSpan) {
  if (inlineSpan is TextSpan && inlineSpan.text != null) {
    return inlineSpan.text;
  }
  if (inlineSpan is PlaceholderSpan) {
    return '\uFFFC';
  }
  return '';
}
