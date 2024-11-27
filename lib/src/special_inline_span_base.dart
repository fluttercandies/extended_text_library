import 'package:flutter/rendering.dart';

///
///  create by zmtzawqlp on 2019/7/10
///

mixin SpecialInlineSpanBase {
  /// actual text
  String get actualText;

  /// the start index in all text
  int get start => textRange.start;

  /// the end index in all text
  int get end => textRange.end;

  TextRange get textRange;

  /// if it's true
  /// delete all actual text when it try to delete a SpecialTextSpan(like a image span)
  /// caret can't move into special text of SpecialTextSpan(like a image span or @xxxx)
  /// extended_text and extended_text_field
  bool get deleteAll;

  bool? get keepVisible;

  bool equal(SpecialInlineSpanBase other) {
    return other.start == start &&
        other.deleteAll == deleteAll &&
        other.actualText == actualText &&
        other.keepVisible == keepVisible;
  }

  int get baseHashCode => Object.hash(
        actualText,
        start,
        deleteAll,
        keepVisible,
      );

  RenderComparison baseCompareTo(SpecialInlineSpanBase other) {
    if (other.actualText != actualText) {
      return RenderComparison.paint;
    }

    if (other.start != start) {
      return RenderComparison.layout;
    }

    return RenderComparison.identical;
  }

  /// showText is the text on screen
  String getSelectedContent(String showText) {
    if (deleteAll) {
      return actualText;
    }
    return showText;
  }
}
