import 'dart:math';

import 'image_span.dart';
import 'special_text_span.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

TextPosition convertTextInputPostionToTextPainterPostion(
    TextSpan text, TextPosition textPosition) {
  List<TextSpan> list = List<TextSpan>();
  textSpanNestToArray(text, list);
  if (list.length > 0) {
    int caretOffset = textPosition.offset;
    int textOffset = 0;
    for (TextSpan ts in list) {
      if (ts is SpecialTextSpan) {
        var length = ts.actualText.length;
        caretOffset -= (length - ts.toPlainText().length);
        textOffset += length;
      } else {
        if (ts.text != null) {
          textOffset += ts.text.length;
        }
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
    TextSpan text, TextSelection selection) {
  if (selection.isValid) {
    if (selection.isCollapsed) {
      var extent =
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
      var extent =
          convertTextInputPostionToTextPainterPostion(text, selection.extent);

      var base =
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
    TextSpan text, TextPosition textPosition) {
  List<TextSpan> list = List<TextSpan>();
  textSpanNestToArray(text, list);
  if (list.length > 0 && textPosition != null) {
    int caretOffset = textPosition.offset;
    if (caretOffset <= 0) return textPosition;

    int textOffset = 0;
    for (TextSpan ts in list) {
      if (ts is SpecialTextSpan) {
        var length = ts.actualText.length;
        caretOffset += (length - ts.toPlainText().length);

        ///make sure caret is not in text when caretIn is false
        if (ts.deleteAll && caretOffset > ts.start && caretOffset < ts.end) {
          if (caretOffset > (ts.end - ts.start) / 2.0 + ts.start) {
            //move caretOffset to end
            caretOffset = ts.end;
          } else {
            caretOffset = ts.start;
          }
          break;
        }
      }
      if (ts.text != null) {
        textOffset += ts.text.length;
      }
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
    TextSpan text, TextSelection selection) {
  if (selection.isValid) {
    if (selection.isCollapsed) {
      var extent =
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
      var extent =
          convertTextPainterPostionToTextInputPostion(text, selection.extent);

      var base =
          convertTextPainterPostionToTextInputPostion(text, selection.base);

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
    TextSpan text, TextPosition textPosition) {
  List<TextSpan> list = List<TextSpan>();
  textSpanNestToArray(text, list);
  if (list.length > 0 && textPosition != null) {
    int caretOffset = textPosition.offset;
    if (caretOffset <= 0) return textPosition;

    int textOffset = 0;
    for (TextSpan ts in list) {
      if (ts is SpecialTextSpan) {
        ///make sure caret is not in text when caretIn is false
        if (ts.deleteAll && caretOffset > ts.start && caretOffset < ts.end) {
          if (caretOffset > (ts.end - ts.start) / 2.0 + ts.start) {
            //move caretOffset to end
            caretOffset = ts.end;
          } else {
            caretOffset = ts.start;
          }
          break;
        }
      }
      if (ts.text != null) {
        textOffset += ts.text.length;
      }
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

double getImageSpanCorrectPosition(ImageSpan image, TextDirection direction) {
  var correctPosition = image.width / 2.0;
  //if (direction == TextDirection.rtl) correctPosition = -correctPosition;

  return correctPosition;
}

///correct caret Offset
///make sure caret is not in text when caretIn is false
TextEditingValue correctCaretOffset(TextEditingValue value, TextSpan textSpan,
    TextInputConnection textInputConnection,
    {TextSelection newSelection}) {
  List<TextSpan> list = List<TextSpan>();
  textSpanNestToArray(textSpan, list);
  if (list.length == 0) return value;

  TextSelection selection = newSelection ?? value.selection;

  if (selection.isValid && selection.isCollapsed) {
    int caretOffset = selection.extentOffset;
    var specialTextSpans =
        list.where((x) => x is SpecialTextSpan && x.deleteAll);
    //correct caret Offset
    //make sure caret is not in text when caretIn is false
    for (SpecialTextSpan ts in specialTextSpans) {
      if (caretOffset > ts.start && caretOffset < ts.end) {
        if (caretOffset > (ts.end - ts.start) / 2.0 + ts.start) {
          //move caretOffset to end
          caretOffset = ts.end;
        } else {
          caretOffset = ts.start;
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
    TextSpan oldTextSpan,
    TextInputConnection textInputConnection) {
  var oldText = oldValue?.text;
  var newText = value?.text;
  List<TextSpan> list = List<TextSpan>();
  textSpanNestToArray(oldTextSpan, list);
  if (list.length > 0) {
    var imageSpans = list.where((x) => (x is SpecialTextSpan && x.deleteAll));

    ///take care of image span
    if (imageSpans.length > 0 &&
        oldText != null &&
        newText != null &&
        oldText.length > newText.length) {
      int difStart = 0;
      //int difEnd = oldText.length - 1;
      for (; difStart < newText.length; difStart++) {
        if (oldText[difStart] != newText[difStart]) {
          break;
        }
      }

      int caretOffset = value.selection.extentOffset;
      if (difStart > 0) {
        for (SpecialTextSpan ts in imageSpans) {
          if (difStart > ts.start && difStart < ts.end) {
            //difStart = ts.start;
            newText = newText.replaceRange(ts.start, difStart, "");
            caretOffset -= (difStart - ts.start);
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

bool hasSpecialText(TextSpan textSpan) {
  List<TextSpan> list = List<TextSpan>();
  textSpanNestToArray(textSpan, list);
  if (list.length == 0) return false;

  //for performance, make sure your all SpecialTextSpan are only in textSpan.children
  //extended_text_field will only check textSpan.children
  return list.firstWhere((x) => x is SpecialTextSpan, orElse: () => null) !=
      null;
}

void textSpanNestToArray(TextSpan textSpan, List<TextSpan> list) {
  assert(list != null);
  if (textSpan == null) return;
  list.add(textSpan);
  if (textSpan.children != null)
    textSpan.children.forEach((ts) => textSpanNestToArray(textSpan, list));
}

String textSpanToActualText(TextSpan textSpan
    //,{bool includeSemanticsLabels = true}
    ) {
  final StringBuffer buffer = StringBuffer();
  _visitTextSpan(textSpan, (TextSpan span) {
//    if (span.semanticsLabel != null && includeSemanticsLabels) {
//      buffer.write(span.semanticsLabel);
//    } else
    {
      var text = span.text;
      if (span is SpecialTextSpan) {
        text = span.actualText;
      }
      buffer.write(text);
    }
    return true;
  });
  return buffer.toString();
}

/// Walks this text span and its descendants in pre-order and calls [visitor]
/// for each span that has text.
bool _visitTextSpan(TextSpan textSpan, bool visitor(TextSpan span)) {
  var text = textSpan.text;
  if (textSpan is SpecialTextSpan) {
    text = textSpan.actualText;
  }
  if (text != null) {
    if (!visitor(textSpan)) return false;
  }
  if (textSpan.children != null) {
    for (TextSpan child in textSpan.children) {
      if (!_visitTextSpan(child, visitor)) return false;
      //if (!child.visitTextSpan(visitor)) return false;
    }
  }
  return true;
}
