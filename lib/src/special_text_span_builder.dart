import 'package:extended_text_library/src/extended_text_typedef.dart';
import 'package:flutter/material.dart';

abstract class SpecialTextSpanBuilder {
  //build text span to specialText
  TextSpan build(String data,
      {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap}) {
    if (data == '') {
      return const TextSpan(text: '');
    }
    final List<InlineSpan> inlineList = <InlineSpan>[];
    if (data.isNotEmpty) {
      SpecialText? specialText;
      String textStack = '';
      //String text
      for (int i = 0; i < data.length; i++) {
        final String char = data[i];
        textStack += char;
        if (specialText != null) {
          if (!specialText.isEnd(textStack)) {
            specialText.appendContent(char);
          } else {
            inlineList.add(specialText.finishText());
            specialText = null;
            textStack = '';
          }
        } else {
          specialText = createSpecialText(textStack,
              textStyle: textStyle, onTap: onTap, index: i);
          if (specialText != null) {
            if (textStack.length - specialText.startFlag.length >= 0) {
              textStack = textStack.substring(
                  0, textStack.length - specialText.startFlag.length);
              if (textStack.isNotEmpty) {
                inlineList.add(TextSpan(text: textStack, style: textStyle));
              }
            }
            textStack = '';
          }
        }
      }

      if (specialText != null) {
        inlineList.add(TextSpan(
            text: specialText.startFlag + specialText.getContent(),
            style: textStyle));
      } else if (textStack.isNotEmpty) {
        inlineList.add(TextSpan(text: textStack, style: textStyle));
      }
    } else {
      inlineList.add(TextSpan(text: data, style: textStyle));
    }

    return TextSpan(children: inlineList, style: textStyle);
  }

  //build SpecialText base on startflag
  SpecialText? createSpecialText(String flag,
      {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap, int index});

  /// start with SpecialText
  bool isStart(String value, String startFlag) {
    return value.endsWith(startFlag);
  }
}

abstract class SpecialText {
  SpecialText(this.startFlag, this.endFlag, this.textStyle, {this.onTap})
      : _content = StringBuffer();
  final StringBuffer _content;

  ///start flag of SpecialText
  final String startFlag;

  ///end flag of SpecialText
  final String endFlag;

  ///TextStyle of SpecialText
  final TextStyle textStyle;

  ///tap call back of SpecialText
  final SpecialTextGestureTapCallback? onTap;

  ///finish SpecialText
  InlineSpan finishText();

  ///is end of SpecialText
  bool isEnd(String value) {
    return value.endsWith(endFlag);
  }

  ///append text of SpecialText
  void appendContent(String value) {
    _content.write(value);
  }

  ///get content of SpecialText
  String getContent() {
    return _content.toString();
  }

  @override
  String toString() {
    return startFlag + getContent() + endFlag;
  }
}
