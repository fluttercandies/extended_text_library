import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'special_inline_span_base.dart';

///
///  create by zmtzawqlp on 2019/4/30
///

class SpecialTextSpan extends TextSpan with SpecialInlineSpanBase {
  SpecialTextSpan({
    TextStyle style,
    @required String text,
    @required String actualText,
    int start = 0,
    this.deleteAll = true,
    GestureRecognizer recognizer,
  })  : assert(start != null),
        assert(text != null),
        assert(deleteAll != null),
        actualText = actualText ?? text,
        textRange =
            TextRange(start: start, end: start + (actualText ?? text).length),
        super(
          style: style,
          text: text,
          recognizer: recognizer,
        );

  @override
  final String actualText;

  @override
  final bool deleteAll;

  @override
  final TextRange textRange;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    if (super != other) {
      return false;
    }
    return other is SpecialInlineSpanBase && equal(other);
  }

  @override
  int get hashCode => hashValues(super.hashCode, baseHashCode);

  @override
  RenderComparison compareTo(InlineSpan other) {
    RenderComparison comparison = super.compareTo(other);
    if (comparison == RenderComparison.identical) {
      comparison = baseCompareTo(other as SpecialInlineSpanBase);
    }
    return comparison;
  }
}
