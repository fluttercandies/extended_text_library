import 'package:extended_text_library/src/extended_text_typedef.dart';
import 'package:flutter/material.dart';

abstract class SpecialTextSpanBuilder {
  //build text span to specialText
  TextSpan build(String data,
      {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap}) {
    if (data == '') {
      return TextSpan(text: '', style: textStyle);
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
          // always append
          // and remove endflag in getContent method
          specialText.appendContent(char);
          if (specialText.isEnd(textStack)) {
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
  SpecialText? createSpecialText(
    String flag, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
    required int index,
  });

  /// start with SpecialText
  bool isStart(String value, String startFlag) {
    return value.endsWith(startFlag);
  }
}

abstract class SpecialText {
  SpecialText(this.startFlag, this.endFlag, this.textStyle, {this.onTap})
      : _content = StringBuffer();
  final StringBuffer _content;

  /// start flag of SpecialText
  final String startFlag;

  /// end flag of SpecialText
  final String endFlag;

  /// TextStyle of SpecialText
  final TextStyle? textStyle;

  /// tap call back of SpecialText
  final SpecialTextGestureTapCallback? onTap;

  /// finish SpecialText
  InlineSpan finishText();

  /// is end of SpecialText
  bool isEnd(String value) => value.endsWith(endFlag);

  /// append text of SpecialText
  void appendContent(String value) {
    _content.write(value);
  }

  /// get content of SpecialText(not include startFlag and endFlag)
  /// https://github.com/fluttercandies/extended_text/issues/76
  String getContent() {
    String content = _content.toString();
    if (content.endsWith(endFlag)) {
      content = content.substring(
        0,
        content.length - endFlag.length,
      );
    }
    return content;
  }

  @override
  String toString() {
    return startFlag + getContent() + endFlag;
  }
}

abstract class RegExpSpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  List<RegExpSpecialText> get regExps;

  @override
  TextSpan build(String data,
      {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap}) {
    if (data == '') {
      return TextSpan(text: '', style: textStyle);
    }
    final List<InlineSpan> children = <InlineSpan>[];
    if (regExps.isNotEmpty) {
      buildWithRegExp(
        children: children,
        start: 0,
        data: data,
        copyRegExps: regExps.toList(),
        textStyle: textStyle,
        onTap: onTap,
      );
    }

    return TextSpan(children: children, style: textStyle);
  }

  void buildWithRegExp({
    required String data,
    required int start,
    required List<RegExpSpecialText> copyRegExps,
    required List<InlineSpan> children,
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
  }) {
    if (data.isEmpty) {
      return;
    }

    if (copyRegExps.isEmpty) {
      children.add(TextSpan(text: data, style: textStyle));
      return;
    }

    final RegExpSpecialText regExpSpecialText = copyRegExps.first;

    data.splitMapJoin(regExpSpecialText.regExp, onMatch: (Match match) {
      final String matchString = '${match[0]}';
      children.add(regExpSpecialText.finishText(
        start,
        match,
        textStyle: textStyle,
        onTap: onTap,
      ));
      start += matchString.length;
      return '';
    }, onNonMatch: (String notMatch) {
      if (notMatch.isNotEmpty) {
        buildWithRegExp(
          data: notMatch,
          start: start,
          children: children,
          copyRegExps: copyRegExps.toList()..remove(regExpSpecialText),
          textStyle: textStyle,
          onTap: onTap,
        );
        start += notMatch.length;
      }
      return '';
    });
  }

  @override
  SpecialText? createSpecialText(String flag,
      {TextStyle? textStyle,
      SpecialTextGestureTapCallback? onTap,
      required int index}) {
    return null;
  }
}

abstract class RegExpSpecialText {
  RegExp get regExp;

  InlineSpan finishText(
    int start,
    Match match, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
  });
}
