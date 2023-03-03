// ignore_for_file: unnecessary_null_comparison, always_put_control_body_on_new_line

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

///
///  create by zmtzawqlp on 2019/8/1
///
///
/// Signature for the callback that reports when the user changes the selection
/// (including the cursor location).
///
/// Used by [ExtendedRenderEditable.onSelectionChanged].
typedef TextSelectionChangedHandler = void Function(
    TextSelection selection, SelectionChangedCause cause);

/// [ExtendedRenderEditable](https://github.com/fluttercandies/extended_text_field/blob/master/lib/src/extended_render_editable.dart#L104)
/// [ExtendedRenderParagraph](https://github.com/fluttercandies/extended_text/blob/master/lib/src/extended_render_paragraph.dart#L13)
///
/// TextSelection for them
/// flutter/packages/flutter/lib/src/rendering/editable.dart
abstract class ExtendedTextSelectionRenderObject extends ExtendedTextRenderBox
    implements TextLayoutMetrics {
  ValueListenable<bool> get selectionStartInViewport;
  ValueListenable<bool> get selectionEndInViewport;
  List<TextSelectionPoint>? getEndpointsForSelection(TextSelection selection);

  TextSelection? selection;

  double get preferredLineHeight;
  TextPosition getPositionForPoint(Offset globalPosition);
  InlineSpan? get text;
  bool get isAttached;
  TextDirection get textDirection;
  LayerLink? startHandleLayerLink;
  LayerLink? endHandleLayerLink;
  //TextSelectionChangedHandler? get onSelectionChanged;
  bool get obscureText;
  Color? selectionColor;
  List<ui.TextBox>? get selectionRects;
  bool get readOnly;
  late TapGestureRecognizer _tap;
  late LongPressGestureRecognizer _longPress;

  /// selection
  Offset? lastTapDownPosition;

  Offset? lastSecondaryTapDownPosition;

  /// Whether the [handleEvent] will propagate pointer events to selection
  /// handlers.
  ///
  /// If this property is true, the [handleEvent] assumes that this renderer
  /// will be notified of input gestures via [handleTapDown], [handleTap],
  /// [handleDoubleTap], and [handleLongPress].
  ///
  /// If there are any gesture recognizers in the text span, the [handleEvent]
  /// will still propagate pointer events to those recognizers.
  ///
  /// The default value of this property is false.
  bool get ignorePointer;

  /// Tracks the position of a secondary tap event.
  ///
  /// Should be called before attempting to change the selection based on the
  /// position of a secondary tap.
  void handleSecondaryTapDown(TapDownDetails details) {
    lastTapDownPosition = details.globalPosition;
    lastSecondaryTapDownPosition = details.globalPosition;
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [TapGestureRecognizer.onTapDown]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to tap
  /// down events by calling this method.
  void handleTapDown(TapDownDetails details) {
    lastTapDownPosition = details.globalPosition;
  }

  void _handleTapDown(TapDownDetails details) {
    assert(!ignorePointer);
    handleTapDown(details);
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [TapGestureRecognizer.onTap]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to tap
  /// events by calling this method.
  void handleTap() {
    selectPosition(cause: SelectionChangedCause.tap);
  }

  void _handleTap() {
    assert(!ignorePointer);
    handleTap();
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [LongPressGestureRecognizer.onLongPress]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to long
  /// press events by calling this method.
  void handleLongPress() {
    selectWord(cause: SelectionChangedCause.longPress);
  }

  void _handleLongPress() {
    assert(!ignorePointer);
    handleLongPress();
  }

  /// Select a word around the location of the last tap down.
  ///
  /// {@macro flutter.rendering.editable.select}
  void selectWord({required SelectionChangedCause cause}) {
    selectWordsInRange(from: lastTapDownPosition!, cause: cause);
  }

  /// Selects the set words of a paragraph in a given range of global positions.
  ///
  /// The first and last endpoints of the selection will always be at the
  /// beginning and end of a word respectively.
  ///
  /// {@macro flutter.rendering.RenderEditable.selectPosition}
  void selectWordsInRange(
      {required Offset from,
      Offset? to,
      required SelectionChangedCause cause}) {
    assert(cause != null);
    assert(from != null);
    _computeTextMetricsIfNeeded();
    final TextPosition firstPosition =
        textPainter.getPositionForOffset(globalToLocal(from - paintOffset));
    final TextSelection firstWord = _getWordAtOffset(firstPosition);
    final TextSelection lastWord = to == null
        ? firstWord
        : _getWordAtOffset(
            textPainter.getPositionForOffset(globalToLocal(to - paintOffset)));

    setSelection(
      TextSelection(
        baseOffset: firstWord.base.offset,
        extentOffset: lastWord.extent.offset,
        affinity: firstWord.affinity,
      ),
      cause,
    );
  }

  void selectWordEdge({required SelectionChangedCause cause}) {
    assert(cause != null);
    _computeTextMetricsIfNeeded();
    assert(lastTapDownPosition != null);
    final TextPosition position = textPainter.getPositionForOffset(
        globalToLocal(lastTapDownPosition! - paintOffset));
    final TextRange word = textPainter.getWordBoundary(position);
    late TextSelection newSelection;
    if (position.offset <= word.start) {
      newSelection = TextSelection.collapsed(offset: word.start);
    } else {
      newSelection = TextSelection.collapsed(
          offset: word.end, affinity: TextAffinity.upstream);
    }

    /// zmt
    newSelection = hasSpecialInlineSpanBase
        ? convertTextPainterSelectionToTextInputSelection(text!, newSelection)
        : newSelection;
    setSelection(newSelection, cause);
  }

  /// Move selection to the location of the last tap down.
  ///
  /// {@template flutter.rendering.editable.select}
  /// This method is mainly used to translatef user inputs in global positions
  /// into a [TextSelection]. When used in conjunction with a [EditableText],
  /// the selection change is fed back into [TextEditingController.selection].
  ///
  /// If you have a [TextEditingController], it's generally easier to
  /// programmatically manipulate its `value` or `selection` directly.
  /// {@endtemplate}
  void selectPosition({required SelectionChangedCause cause}) {
    selectPositionAt(from: lastTapDownPosition!, cause: cause);
  }

  /// Select text between the global positions [from] and [to].
  ///
  /// [from] corresponds to the [TextSelection.baseOffset], and [to] corresponds
  /// to the [TextSelection.extentOffset].
  void selectPositionAt(
      {required Offset from,
      Offset? to,
      required SelectionChangedCause cause}) {
    assert(cause != null);
    assert(from != null);
    layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    TextPosition fromPosition =
        textPainter.getPositionForOffset(globalToLocal(from - paintOffset));
    TextPosition? toPosition = to == null
        ? null
        : textPainter.getPositionForOffset(globalToLocal(to - paintOffset));
    //zmt
    if (hasSpecialInlineSpanBase) {
      fromPosition =
          convertTextPainterPostionToTextInputPostion(text!, fromPosition)!;
      toPosition =
          convertTextPainterPostionToTextInputPostion(text!, toPosition);
    }
    final int baseOffset = fromPosition.offset;
    final int extentOffset = toPosition?.offset ?? fromPosition.offset;

    final TextSelection newSelection = TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
      affinity: fromPosition.affinity,
    );
    setSelection(newSelection, cause);
  }

  TextSelection _getWordAtOffset(TextPosition position) {
    final TextSelection Function() getWordAtOffset = () {
      debugAssertLayoutUpToDate();
      final TextRange word = textPainter.getWordBoundary(position);
      // When long-pressing past the end of the text, we want a collapsed cursor.
      if (position.offset >= word.end)
        return TextSelection.fromPosition(position);
      // If text is obscured, the entire sentence should be treated as one word.
      if (obscureText) {
        return TextSelection(baseOffset: 0, extentOffset: plainText.length);
        // On iOS, select the previous word if there is a previous word, or select
        // to the end of the next word if there is a next word. Select nothing if
        // there is neither a previous word nor a next word.
        //
        // If the platform is Android and the text is read only, try to select the
        // previous word if there is one; otherwise, select the single whitespace at
        // the position.
      } else if (TextLayoutMetrics.isWhitespace(
              plainText.codeUnitAt(position.offset)) &&
          position.offset > 0) {
        assert(defaultTargetPlatform != null);
        final TextRange? previousWord = _getPreviousWord(word.start);
        switch (defaultTargetPlatform) {
          case TargetPlatform.iOS:
            if (previousWord == null) {
              final TextRange? nextWord = _getNextWord(word.start);
              if (nextWord == null) {
                return TextSelection.collapsed(offset: position.offset);
              }
              return TextSelection(
                baseOffset: position.offset,
                extentOffset: nextWord.end,
              );
            }
            return TextSelection(
              baseOffset: previousWord.start,
              extentOffset: position.offset,
            );
          case TargetPlatform.android:
            if (readOnly) {
              if (previousWord == null) {
                return TextSelection(
                  baseOffset: position.offset,
                  extentOffset: position.offset + 1,
                );
              }
              return TextSelection(
                baseOffset: previousWord.start,
                extentOffset: position.offset,
              );
            }
            break;
          case TargetPlatform.fuchsia:
          case TargetPlatform.macOS:
          case TargetPlatform.linux:
          case TargetPlatform.windows:
            break;
        }
      }

      return TextSelection(baseOffset: word.start, extentOffset: word.end);
    };

    final TextSelection selection = getWordAtOffset();

    /// zmt
    return hasSpecialInlineSpanBase
        ? convertTextPainterSelectionToTextInputSelection(text!, selection,
            selectWord: true)
        : selection;
  }

  TextRange? _getNextWord(int offset) {
    while (true) {
      final TextRange range =
          textPainter.getWordBoundary(TextPosition(offset: offset));
      if (range == null || !range.isValid || range.isCollapsed) return null;
      if (!_onlyWhitespace(range)) return range;
      offset = range.end;
    }
  }

  TextRange? _getPreviousWord(int offset) {
    while (offset >= 0) {
      final TextRange range =
          textPainter.getWordBoundary(TextPosition(offset: offset));
      if (range == null || !range.isValid || range.isCollapsed) return null;
      if (!_onlyWhitespace(range)) return range;
      offset = range.start - 1;
    }
    return null;
  }

  // Check if the given text range only contains white space or separator
  // characters.
  //
  // Includes newline characters from ASCII and separators from the
  // [unicode separator category](https://www.compart.com/en/unicode/category/Zs)
  // TODO(zanderso): replace when we expose this ICU information.
  bool _onlyWhitespace(TextRange range) {
    for (int i = range.start; i < range.end; i++) {
      final int codeUnit = text!.codeUnitAt(i)!;
      if (!TextLayoutMetrics.isWhitespace(codeUnit)) {
        return false;
      }
    }
    return true;
  }

  void paintHandleLayers(PaintingContext context,
      Function(PaintingContext context, Offset offset) paint) {
    if (selection == null) {
      return;
    }
    final List<TextSelectionPoint>? endpoints =
        getEndpointsForSelection(selection!);

    if (endpoints == null || endpoints.isEmpty) {
      return;
    }

    Offset startPoint = endpoints[0].point;
    startPoint = Offset(
      startPoint.dx.clamp(0.0, size.width),
      startPoint.dy.clamp(0.0, size.height),
    );
    context.pushLayer(
      LeaderLayer(link: startHandleLayerLink!, offset: startPoint),
      paint,
      Offset.zero,
    );
    if (endpoints.length == 2) {
      Offset endPoint = endpoints[1].point;
      endPoint = Offset(
        endPoint.dx.clamp(0.0, size.width),
        endPoint.dy.clamp(0.0, size.height),
      );
      context.pushLayer(
        LeaderLayer(link: endHandleLayerLink!, offset: endPoint),
        paint,
        Offset.zero,
      );
    }
  }

  void paintSelection(Canvas canvas, Offset effectiveOffset) {
    if (selectionRects == null || selectionColor == null) {
      return;
    }
    assert(textLayoutLastMaxWidth == constraints.maxWidth,
        'Last width ($textLayoutLastMaxWidth) not the same as max width constraint (${constraints.maxWidth}).');
    //assert(selectionRects != null);
    final Paint paint = Paint()..color = selectionColor!;
    for (final ui.TextBox box in selectionRects!)
      canvas.drawRect(box.toRect().shift(effectiveOffset), paint);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _tap = TapGestureRecognizer(debugOwner: this)
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap;
    _longPress = LongPressGestureRecognizer(debugOwner: this)
      ..onLongPress = _handleLongPress;
  }

  @override
  void detach() {
    _tap.dispose();
    _longPress.dispose();
    super.detach();
  }

  /// Whether the editable is currently focused.
  bool get hasFocus => _hasFocus;
  bool _hasFocus = false;

  set hasFocus(bool value) {
    if (_hasFocus == value) {
      return;
    }
    _hasFocus = value;

    markNeedsSemanticsUpdate();
  }

  Rect get caretPrototype;

  /// The object that controls the text selection, used by this render object
  /// for implementing cut, copy, and paste keyboard shortcuts.
  ///
  /// It must not be null. It will make cut, copy and paste functionality work
  /// with the most recently set [TextSelectionDelegate].
  TextSelectionDelegate? get textSelectionDelegate;

  /// Returns the index into the string of the next character boundary after the
  /// given index.
  ///
  /// The character boundary is determined by the characters package, so
  /// surrogate pairs and extended grapheme clusters are considered.
  ///
  /// The index must be between 0 and string.length, inclusive. If given
  /// string.length, string.length is returned.
  ///
  /// Setting includeWhitespace to false will only return the index of non-space
  /// characters.
  @visibleForTesting
  static int nextCharacter(int index, String string,
      [bool includeWhitespace = true]) {
    assert(index >= 0 && index <= string.length);
    if (index == string.length) {
      return string.length;
    }

    int count = 0;
    final Characters remaining =
        string.characters.skipWhile((String currentString) {
      if (count <= index) {
        count += currentString.length;
        return true;
      }
      if (includeWhitespace) {
        return false;
      }
      return TextLayoutMetrics.isWhitespace(currentString.codeUnitAt(0));
    });
    return string.length - remaining.toString().length;
  }

  /// Returns the index into the string of the previous character boundary
  /// before the given index.
  ///
  /// The character boundary is determined by the characters package, so
  /// surrogate pairs and extended grapheme clusters are considered.
  ///
  /// The index must be between 0 and string.length, inclusive. If index is 0,
  /// 0 will be returned.
  ///
  /// Setting includeWhitespace to false will only return the index of non-space
  /// characters.
  @visibleForTesting
  static int previousCharacter(int index, String string,
      [bool includeWhitespace = true]) {
    assert(index >= 0 && index <= string.length);
    if (index == 0) {
      return 0;
    }

    int count = 0;
    int? lastNonWhitespace;
    for (final String currentString in string.characters) {
      if (!includeWhitespace &&
          !TextLayoutMetrics.isWhitespace(
              currentString.characters.first.toString().codeUnitAt(0))) {
        lastNonWhitespace = count;
      }
      if (count + currentString.length >= index) {
        return includeWhitespace ? count : lastNonWhitespace ?? 0;
      }
      count += currentString.length;
    }
    return 0;
  }

  // Start TextLayoutMetrics.

  /// {@macro flutter.services.TextLayoutMetrics.getLineAtOffset}
  @override
  TextSelection getLineAtOffset(TextPosition position) {
    debugAssertLayoutUpToDate();
    final TextRange line = textPainter.getLineBoundary(position);
    // If text is obscured, the entire string should be treated as one line.
    if (obscureText) {
      return TextSelection(baseOffset: 0, extentOffset: plainText.length);
    }
    return TextSelection(baseOffset: line.start, extentOffset: line.end);
  }

  /// {@macro flutter.painting.TextPainter.getWordBoundary}
  @override
  TextRange getWordBoundary(TextPosition position) {
    return textPainter.getWordBoundary(position);
  }

  /// {@macro flutter.services.TextLayoutMetrics.getTextPositionAbove}
  @override
  TextPosition getTextPositionAbove(TextPosition position) {
    // The caret offset gives a location in the upper left hand corner of
    // the caret so the middle of the line above is a half line above that
    // point and the line below is 1.5 lines below that point.
    final double preferredLineHeight = textPainter.preferredLineHeight;
    final double verticalOffset = -0.5 * preferredLineHeight;
    return _getTextPositionVertical(position, verticalOffset);
  }

  /// {@macro flutter.services.TextLayoutMetrics.getTextPositionBelow}
  @override
  TextPosition getTextPositionBelow(TextPosition position) {
    // The caret offset gives a location in the upper left hand corner of
    // the caret so the middle of the line above is a half line above that
    // point and the line below is 1.5 lines below that point.
    final double preferredLineHeight = textPainter.preferredLineHeight;
    final double verticalOffset = 1.5 * preferredLineHeight;
    return _getTextPositionVertical(position, verticalOffset);
  }

  /// Returns the TextPosition above or below the given offset.
  TextPosition _getTextPositionVertical(
      TextPosition position, double verticalOffset) {
    final Offset caretOffset =
        getCaretOffset(position, caretPrototype: caretPrototype);
    final Offset caretOffsetTranslated =
        caretOffset.translate(0.0, verticalOffset);
    return textPainter.getPositionForOffset(caretOffsetTranslated);
  }

  // End TextLayoutMetrics.

  /// Assert that the last layout still matches the constraints.
  void debugAssertLayoutUpToDate() {
    assert(
      textLayoutLastMaxWidth == constraints.maxWidth &&
          textLayoutLastMinWidth == constraints.minWidth,
      'Last width ($textLayoutLastMinWidth, $textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).',
    );
  }

  /// Returns the smallest [Rect], in the local coordinate system, that covers
  /// the text within the [TextRange] specified.
  ///
  /// This method is used to calculate the approximate position of the IME bar
  /// on iOS.
  ///
  /// Returns null if [TextRange.isValid] is false for the given `range`, or the
  /// given `range` is collapsed.
  Rect? getRectForComposingRange(TextRange range) {
    if (!range.isValid || range.isCollapsed) return null;
    _computeTextMetricsIfNeeded();

    final List<ui.TextBox> boxes = textPainter.getBoxesForSelection(
      TextSelection(baseOffset: range.start, extentOffset: range.end),
      boxHeightStyle: selectionHeightStyle,
      boxWidthStyle: selectionWidthStyle,
    );

    return boxes
        .fold(
          null,
          (Rect? accum, TextBox incoming) =>
              accum?.expandToInclude(incoming.toRect()) ?? incoming.toRect(),
        )
        ?.shift(paintOffset);
  }

  // Computes the text metrics if `_textPainter`'s layout information was marked
  // as dirty.
  //
  // This method must be called in `RenderEditable`'s public methods that expose
  // `_textPainter`'s metrics. For instance, `systemFontsDidChange` sets
  // _textPainter._paragraph to null, so accessing _textPainter's metrics
  // immediately after `systemFontsDidChange` without first calling this method
  // may crash.
  //
  // This method is also called in various paint methods (`RenderEditable.paint`
  // as well as its foreground/background painters' `paint`). It's needed
  // because invisible render objects kept in the tree by `KeepAlive` may not
  // get a chance to do layout but can still paint.
  // See https://github.com/flutter/flutter/issues/84896.
  //
  // This method only re-computes layout if the underlying `_textPainter`'s
  // layout cache is invalidated (by calling `TextPainter.markNeedsLayout`), or
  // the constraints used to layout the `_textPainter` is different. See
  // `TextPainter.layout`.
  void _computeTextMetricsIfNeeded() {
    assert(constraints != null);
    layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
  }

  void _setTextEditingValue(
      TextEditingValue newValue, SelectionChangedCause cause) {
    textSelectionDelegate?.userUpdateTextEditingValue(newValue, cause);
  }

  void setSelection(TextSelection nextSelection, SelectionChangedCause cause) {
    if (textSelectionDelegate == null) {
      return;
    }
    if (nextSelection.isValid) {
      // The nextSelection is calculated based on _plainText, which can be out
      // of sync with the textSelectionDelegate.textEditingValue by one frame.
      // This is due to the render editable and editable text handle pointer
      // event separately. If the editable text changes the text during the
      // event handler, the render editable will use the outdated text stored in
      // the _plainText when handling the pointer event.
      //
      // If this happens, we need to make sure the new selection is still valid.
      final int textLength =
          textSelectionDelegate!.textEditingValue.text.length;
      nextSelection = nextSelection.copyWith(
        baseOffset: math.min(nextSelection.baseOffset, textLength),
        extentOffset: math.min(nextSelection.extentOffset, textLength),
      );
    }
    _setTextEditingValue(
      textSelectionDelegate!.textEditingValue
          .copyWith(selection: nextSelection),
      cause,
    );
  }

  // TODO(ianh): in theory, [selection] could become null between when
  void handleSetSelection(TextSelection selection) {
    setSelection(selection, SelectionChangedCause.keyboard);
  }

  TextSelection? getActualSelection(
      {TextRange? newRange, TextSelection? newSelection}) {
    TextSelection? value = newSelection ?? selection;
    if (newRange != null) {
      value =
          TextSelection(baseOffset: newRange.start, extentOffset: newRange.end);
    }

    return hasSpecialInlineSpanBase
        ? convertTextInputSelectionToTextPainterSelection(text!, value!)
        : value;
  }

  /// Returns a list of rects that bound the given selection.
  ///
  /// See [TextPainter.getBoxesForSelection] for more details.
  List<Rect> getBoxesForSelectionRects(TextSelection selection) {
    _computeTextMetricsIfNeeded();
    return textPainter
        .getBoxesForSelection(selection)
        .map((TextBox textBox) => textBox.toRect().shift(paintOffset))
        .toList();
  }
}
