import 'dart:ui';

import 'package:flutter/rendering.dart';

///
///  create by zmtzawqlp on 2019/7/10
///

abstract class SpecialInlineSpanBase {
  /// actual text
  String get actualText;

  /// the start index in all text
  int get start => textRange.start;

  /// the end index in all text
  int get end => textRange.end;

  TextRange get textRange;

  ///extended_text_field
  ///
  ///if it's true
  ///* delete all actual text when it try to delete a SpecialTextSpan(like a image span)
  ///* caret can't move into special text of SpecialTextSpan(like a image span or @xxxx)
  bool get deleteAll;

  bool equal(SpecialInlineSpanBase other) {
    return other.start == start &&
        other.deleteAll == deleteAll &&
        other.actualText == actualText;
  }

  int get baseHashCode => hashValues(actualText, start, deleteAll);

  RenderComparison baseCompareTo(SpecialInlineSpanBase other) {
    if (other.actualText != actualText) {
      return RenderComparison.paint;
    }

    if (other.start != start) {
      return RenderComparison.layout;
    }

    return RenderComparison.identical;
  }
}
