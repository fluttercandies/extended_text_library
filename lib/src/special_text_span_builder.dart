import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:extended_text_library/src/extended_text_typedef.dart';

abstract class SpecialTextSpanBuilder {
  const SpecialTextSpanBuilder({
    this.prefixSpans,
    this.suffixSpans,
  });

  /// [InlineSpan]s that will be prepended to the spans list.
  final List<InlineSpan> prefixSpans;

  /// [InlineSpan]s that will be appended to the spans list.
  final List<InlineSpan> suffixSpans;

  /// Build text spans to [SpecialText].
  ///
  /// This method implements an text stack inside in order to split between
  /// normal texts and special text that user defined.
  TextSpan build(
    String data, {
    TextStyle textStyle,
    SpecialTextGestureTapCallback onTap,
  }) {
    if (data == null || data == '') {
      return null;
    }
    final List<InlineSpan> inlineList = <InlineSpan>[];
    if (data.isNotEmpty) {
      SpecialText specialText;
      String textStack = '';
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
          specialText = createSpecialText(
            textStack,
            textStyle: textStyle,
            onTap: onTap,
            index: i,
          );
          if (specialText != null) {
            if (textStack.length - specialText.startFlag.toString().length >=
                0) {
              textStack = textStack.substring(
                0,
                textStack.length - specialText.startFlag.toString().length,
              );
              if (textStack.isNotEmpty) {
                inlineList.add(TextSpan(text: textStack, style: textStyle));
              }
            }
            textStack = '';
          }
        }
      }

      if (specialText != null) {
        inlineList.add(
          TextSpan(
            text: specialText.startFlag.toString() + specialText.getContent(),
            style: textStyle,
          ),
        );
      } else if (textStack.isNotEmpty) {
        inlineList.add(TextSpan(text: textStack, style: textStyle));
      }
    } else {
      inlineList.add(TextSpan(text: data, style: textStyle));
    }
    if (prefixSpans != null) {
      inlineList.insertAll(0, prefixSpans);
    }
    if (suffixSpans != null) {
      inlineList.addAll(suffixSpans);
    }
    return TextSpan(children: inlineList, style: textStyle);
  }

  /// Build [SpecialText] based on [startFlag].
  ///
  /// By using the default implementation, you can only use [isMatched] for
  /// conditions in [createSpecialText] method, otherwise the correct special
  /// text cannot spawned because [isMatched] only matches the end of the text
  /// stack (in other words, the start of the special text).
  SpecialText createSpecialText(
    String data, {
    TextStyle textStyle,
    SpecialTextGestureTapCallback onTap,
    int index,
  });

  /// Whether the characters stack's ends with [startFlag].
  ///
  /// Be aware that the default implementation of the [SpecialTextSpanBuilder],
  /// see documents above.
  bool isMatched(String value, Pattern startFlag) {
    return value.endsWithPattern(startFlag);
  }
}

abstract class SpecialText {
  SpecialText(
    this.startFlag,
    this.endFlag,
    this.textStyle, {
    this.onTap,
  })  : assert(startFlag != null),
        _content = StringBuffer();

  final StringBuffer _content;

  /// Start flag of [SpecialText].
  final Pattern startFlag;

  /// End flag of [SpecialText].
  final Pattern endFlag;

  /// [TextStyle] of [SpecialText].
  final TextStyle textStyle;

  /// Tap callback of [SpecialText].
  final SpecialTextGestureTapCallback onTap;

  /// Finish [SpecialText].
  InlineSpan finishText();

  /// Is [SpecialText] end with [endFlag].
  bool isEnd(String value) => value.endsWithPattern(endFlag);

  /// Append text of [SpecialText].
  void appendContent(String value) => _content.write(value);

  /// Get content of [SpecialText].
  String getContent() => _content.toString();

  @override
  String toString() => '$startFlag${getContent()}$endFlag';
}

/// While Dart didn't support [String.endsWith] with [Pattern], this extension
/// implements an method that support with [Pattern].
extension _StringEndsWithRegEx on String {
  bool endsWithPattern(Pattern other) {
    if (other is String) {
      return endsWith(other);
    }
    if (other.allMatches(this).isEmpty) {
      return false;
    }
    final Iterable<Match> matches = other.allMatches(this);
    final Match lastMatch = matches.last;
    final String content = lastMatch.group(
      math.max(lastMatch.groupCount - 1, 0),
    );
    final int index = indexOf(content);
    return content.length + index == length;
  }
}
