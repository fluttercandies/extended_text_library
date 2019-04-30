import 'package:flutter/material.dart';

///
///  create by zmtzawqlp on 2019/4/30
///

class SpecialTextSpan extends TextSpan {
  final String actualText;
  final int start;
  int get end => start + actualText.length;
  SpecialTextSpan({
    TextStyle style,
    @required String text,
    @required this.actualText,
    @required this.start,
  })  : assert(text != null),
        assert(actualText != null),
        assert(start != null),
        super(
          style: style,
          text: text,
        );
}
