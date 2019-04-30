import 'package:flutter/material.dart';

///
///  create by zmtzawqlp on 2019/4/30
///

class SpecialTextSpan extends TextSpan {
  /// actual text
  final String actualText;

  /// the start index in all text
  final int start;

  /// the end index in all text
  int get end => start + actualText.length;

  ///extended_text_field
  ///whether delete all actual text when it try to delete SpecialTextSpan(like a image span)
  final bool deleteAll;

  SpecialTextSpan({
    TextStyle style,
    @required String text,
    @required this.actualText,
    @required this.start,
    this.deleteAll,
  })  : assert(text != null),
        assert(actualText != null),
        assert(start != null),
        super(
          style: style,
          text: text,
        );
}
