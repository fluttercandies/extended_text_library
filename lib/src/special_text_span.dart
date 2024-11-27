import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'special_inline_span_base.dart';

///
///  create by zmtzawqlp on 2019/4/30
///

class SpecialTextSpan extends TextSpan with SpecialInlineSpanBase {
  SpecialTextSpan({
    TextStyle? style,
    required String text,
    String? actualText,
    int start = 0,
    this.deleteAll = true,
    GestureRecognizer? recognizer,
    List<InlineSpan>? children,
    String? semanticsLabel,
    MouseCursor? mouseCursor,
    PointerEnterEventListener? onEnter,
    PointerExitEventListener? onExit,
    this.keepVisible,
  })  :
        //assert(!(deleteAll && children != null && children.isNotEmpty)),
        actualText = actualText ?? text,
        textRange =
            TextRange(start: start, end: start + (actualText ?? text).length),
        super(
          style: style,
          text: text,
          recognizer: recognizer,
          children: children,
          semanticsLabel: semanticsLabel,
          mouseCursor: mouseCursor,
          onEnter: onEnter,
          onExit: onExit,
        );

  @override
  final String actualText;

  @override
  final bool deleteAll;

  @override
  final TextRange textRange;

  @override
  final bool? keepVisible;
  @override
  bool operator ==(Object other) {
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
  int get hashCode => Object.hash(super.hashCode, baseHashCode);

  @override
  RenderComparison compareTo(InlineSpan other) {
    RenderComparison comparison = super.compareTo(other);
    if (comparison == RenderComparison.identical) {
      comparison = baseCompareTo(other as SpecialInlineSpanBase);
    }
    return comparison;
  }
}
