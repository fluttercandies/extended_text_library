import 'package:flutter/material.dart';

class TextPainterHelper {
  TextPainter? _painter;
  TextPainter? get painter => _painter;

  ///method for [OverFlowTextSpan] and [BackgroundTextSpan]
  TextPainter? layout(TextPainter painter, TextSpan textSpan,
      {bool compareChildren = true}) {
    if (_painter == null ||
        ((compareChildren
                ? _painter!.text != textSpan
                : (_painter!.text as TextSpan).text != textSpan.text) ||
            _painter!.textAlign != painter.textAlign ||
            _painter!.textScaler != painter.textScaler ||
            _painter!.locale != painter.locale)) {
      _painter = TextPainter(
          text: textSpan,
          textAlign: painter.textAlign,
          textScaler: painter.textScaler,
          textDirection: painter.textDirection,
          locale: painter.locale);
    }
    _painter!.layout();

    return _painter;
  }

  ///method for [OverFlowTextSpan]
  ///offset int coordinate system
  Offset? _offset;
  //public
  Offset? get offset => _offset;
  void saveOffset(Offset offset) {
    _offset = offset;
  }

  ///method for [OverFlowTextSpan]
  TextPosition getPositionForOffset(Offset offset) {
    return painter!.getPositionForOffset(offset - _offset!);
  }

  ///method for [OverFlowTextSpan]
  InlineSpan? getSpanForPosition(TextPosition position) {
    return painter!.text!.getSpanForPosition(position);
  }
}
