import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../extended_text_utils.dart';
import 'extended_text_render_box.dart';

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

// Check if the given code unit is a white space or separator
// character.
//
// Includes newline characters from ASCII and separators from the
// [unicode separator category](https://www.compart.com/en/unicode/category/Zs)
// TODO(gspencergoog): replace when we expose this ICU information.
bool isWhitespace(int codeUnit) {
  switch (codeUnit) {
    case 0x9: // horizontal tab
    case 0xA: // line feed
    case 0xB: // vertical tab
    case 0xC: // form feed
    case 0xD: // carriage return
    case 0x1C: // file separator
    case 0x1D: // group separator
    case 0x1E: // record separator
    case 0x1F: // unit separator
    case 0x20: // space
    case 0xA0: // no-break space
    case 0x1680: // ogham space mark
    case 0x2000: // en quad
    case 0x2001: // em quad
    case 0x2002: // en space
    case 0x2003: // em space
    case 0x2004: // three-per-em space
    case 0x2005: // four-er-em space
    case 0x2006: // six-per-em space
    case 0x2007: // figure space
    case 0x2008: // punctuation space
    case 0x2009: // thin space
    case 0x200A: // hair space
    case 0x202F: // narrow no-break space
    case 0x205F: // medium mathematical space
    case 0x3000: // ideographic space
      break;
    default:
      return false;
  }
  return true;
}

/// [ExtendedRenderEditable](https://github.com/fluttercandies/extended_text_field/blob/master/lib/src/extended_render_editable.dart#L104)
/// [ExtendedRenderParagraph](https://github.com/fluttercandies/extended_text/blob/master/lib/src/extended_render_paragraph.dart#L13)
///
/// TextSelection for them
abstract class ExtendedTextSelectionRenderObject extends ExtendedTextRenderBox {
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
  TextSelectionChangedHandler? get onSelectionChanged;
  Offset get paintOffset;
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
  /// {@macro flutter.rendering.editable.select}
  void selectWordsInRange(
      {required Offset from,
      Offset? to,
      required SelectionChangedCause cause}) {
    layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    if (onSelectionChanged != null) {
      final TextPosition firstPosition =
          textPainter.getPositionForOffset(globalToLocal(from - paintOffset));
      final TextSelection firstWord = selectWordAtOffset(firstPosition);
      final TextSelection lastWord = to == null
          ? firstWord
          : selectWordAtOffset(textPainter
              .getPositionForOffset(globalToLocal(to - paintOffset)));

      _handleSelectionChange(
        TextSelection(
          baseOffset: firstWord.base.offset,
          extentOffset: lastWord.extent.offset,
          affinity: firstWord.affinity,
        ),
        cause,
      );
    }
  }

  /// Move the selection to the beginning or end of a word.
  ///
  /// {@macro flutter.rendering.editable.select}
  void selectWordEdge({required SelectionChangedCause cause}) {
    layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    assert(lastTapDownPosition != null);
    if (onSelectionChanged == null) {
      return;
    }
    final TextPosition position = textPainter.getPositionForOffset(
        globalToLocal(lastTapDownPosition! - paintOffset));
    final TextRange word = textPainter.getWordBoundary(position);
    final TextRange lineBoundary = textPainter.getLineBoundary(position);
    final bool endOfLine = lineBoundary.end == position.offset;
    TextSelection selection;

    ///zmt
    if (position.offset - word.start <= 1) {
      selection = TextSelection.collapsed(
          offset: word.start,
          affinity: endOfLine ? position.affinity : TextAffinity.downstream);
    } else {
      selection = TextSelection.collapsed(
          offset: word.end,
          affinity: endOfLine ? position.affinity : TextAffinity.upstream);
    }

    selection = hasSpecialInlineSpanBase
        ? convertTextPainterSelectionToTextInputSelection(text!, selection)
        : selection;

    _handleSelectionChange(selection, cause);
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
  void selectPositionAt(
      {required Offset from,
      Offset? to,
      required SelectionChangedCause cause}) {
    layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    if (onSelectionChanged != null) {
      TextPosition? fromPosition =
          textPainter.getPositionForOffset(globalToLocal(from - paintOffset));
      TextPosition? toPosition = to == null
          ? null
          : textPainter.getPositionForOffset(globalToLocal(to - paintOffset));

      //zmt
      if (hasSpecialInlineSpanBase) {
        fromPosition =
            convertTextPainterPostionToTextInputPostion(text!, fromPosition);
        toPosition =
            convertTextPainterPostionToTextInputPostion(text!, toPosition);
      }

      int baseOffset = fromPosition!.offset;
      int extentOffset = fromPosition.offset;

      if (toPosition != null) {
        baseOffset = math.min(fromPosition.offset, toPosition.offset);
        extentOffset = math.max(fromPosition.offset, toPosition.offset);
      }

      final TextSelection newSelection = TextSelection(
        baseOffset: baseOffset,
        extentOffset: extentOffset,
        affinity: fromPosition.affinity,
      );
      // Call [onSelectionChanged] only when the selection actually changed.
      _handleSelectionChange(newSelection, cause);
    }
  }

  // Call through to onSelectionChanged.
  void _handleSelectionChange(
    TextSelection nextSelection,
    SelectionChangedCause cause,
  ) {
    // Changes made by the keyboard can sometimes be "out of band" for listening
    // components, so always send those events, even if we didn't think it
    // changed.
    if (nextSelection == selection && cause != SelectionChangedCause.keyboard) {
      return;
    }
    if (onSelectionChanged != null) {
      onSelectionChanged!(nextSelection, cause);
    }
  }

  TextSelection selectWordAtOffset(TextPosition position) {
    assert(
        textLayoutLastMaxWidth == constraints.maxWidth &&
            textLayoutLastMinWidth == constraints.minWidth,
        'Last width ($textLayoutLastMinWidth, $textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).');
    final TextRange word = textPainter.getWordBoundary(position);
    TextSelection? selection;
    // When long-pressing past the end of the text, we want a collapsed cursor.
    if (position.offset >= word.end) {
      selection = TextSelection.fromPosition(position);
    }
    // If text is obscured, the entire sentence should be treated as one word.
    else if (obscureText) {
      selection = TextSelection(baseOffset: 0, extentOffset: plainText.length);
    }
    // If the word is a space, on iOS try to select the previous word instead.
    // On Android try to select the previous word instead only if the text is read only.
    else if (text?.toPlainText() != null &&
        isWhitespace(text!.toPlainText().codeUnitAt(position.offset)) &&
        position.offset > 0) {
      final TextRange? previousWord = _getPreviousWord(word.start);
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          selection = TextSelection(
            baseOffset: previousWord!.start,
            extentOffset: position.offset,
          );
          break;
        case TargetPlatform.android:
          if (readOnly) {
            selection = TextSelection(
              baseOffset: previousWord!.start,
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
    selection ??= TextSelection(baseOffset: word.start, extentOffset: word.end);

    /// zmt
    return hasSpecialInlineSpanBase
        ? convertTextPainterSelectionToTextInputSelection(text!, selection,
            selectWord: true)
        : selection;
  }

  TextRange? _getPreviousWord(int offset) {
    while (offset >= 0) {
      final TextRange range =
          textPainter.getWordBoundary(TextPosition(offset: offset));
      if (!range.isValid || range.isCollapsed) {
        return null;
      }
      if (!_onlyWhitespace(range)) {
        return range;
      }
      offset = range.start - 1;
    }
    return null;
  }

  // Check if the given text range only contains white space or separator
  // characters.
  //
  // Includes newline characters from ASCII and separators from the
  // [unicode separator category](https://www.compart.com/en/unicode/category/Zs)
  // TODO(jonahwilliams): replace when we expose this ICU information.
  bool _onlyWhitespace(TextRange range) {
    for (int i = range.start; i < range.end; i++) {
      final int codeUnit = plainText.codeUnitAt(i);
      if (!isWhitespace(codeUnit)) {
        return false;
      }
    }
    return true;
  }

  void paintHandleLayers(PaintingContext context,
      Function(PaintingContext context, Offset offset) paint) {
    if (selection == null ||
        startHandleLayerLink == null ||
        endHandleLayerLink == null) {
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
    if (_listenerAttached) {
      RawKeyboard.instance.removeListener(_handleKeyEvent);
    }
    super.detach();
  }

  /// Whether the editable is currently focused.
  bool get hasFocus => _hasFocus;
  bool _hasFocus = false;
  bool _listenerAttached = false;
  set hasFocus(bool value) {
    if (_hasFocus == value) {
      return;
    }
    _hasFocus = value;
    if (_hasFocus) {
      assert(!_listenerAttached);
      RawKeyboard.instance.addListener(_handleKeyEvent);
      _listenerAttached = true;
    } else {
      assert(_listenerAttached);
      RawKeyboard.instance.removeListener(_handleKeyEvent);
      _listenerAttached = false;
    }
    markNeedsSemanticsUpdate();
  }

  // multiline text field when selecting using the keyboard.
  int _cursorResetLocation = -1;

  // Whether we should reset the location of the cursor in the case the user
  // tries to select vertically past the end or beginning of the field. If they
  // do, then we need to keep the old cursor location so that we can go back to
  // it if they change their minds. Only used for resetting selection up and
  // down in a multiline text field when selecting using the keyboard.
  bool _wasSelectingVerticallyWithKeyboard = false;

  Rect get caretPrototype;

  /// The object that controls the text selection, used by this render object
  /// for implementing cut, copy, and paste keyboard shortcuts.
  ///
  /// It must not be null. It will make cut, copy and paste functionality work
  /// with the most recently set [TextSelectionDelegate].
  TextSelectionDelegate? get textSelectionDelegate;

  static final Set<LogicalKeyboardKey> _movementKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
  };

  static final Set<LogicalKeyboardKey> _shortcutKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyC,
    LogicalKeyboardKey.keyV,
    LogicalKeyboardKey.keyX,
    LogicalKeyboardKey.delete,
    LogicalKeyboardKey.backspace,
  };

  static final Set<LogicalKeyboardKey> _nonModifierKeys = <LogicalKeyboardKey>{
    ..._shortcutKeys,
    ..._movementKeys,
  };

  static final Set<LogicalKeyboardKey> _modifierKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.alt,
  };

  static final Set<LogicalKeyboardKey> _macOsModifierKeys =
      <LogicalKeyboardKey>{
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.alt,
  };

  static final Set<LogicalKeyboardKey> _interestingKeys = <LogicalKeyboardKey>{
    ..._modifierKeys,
    ..._macOsModifierKeys,
    ..._nonModifierKeys,
  };

  void _handleKeyEvent(RawKeyEvent keyEvent) {
    if (kIsWeb) {
      // On web platform, we should ignore the key because it's processed already.
      return;
    }

    if (keyEvent is! RawKeyDownEvent || onSelectionChanged == null) {
      return;
    }
    final Set<LogicalKeyboardKey> keysPressed =
        LogicalKeyboardKey.collapseSynonyms(RawKeyboard.instance.keysPressed);
    final LogicalKeyboardKey key = keyEvent.logicalKey;

    final bool isMacOS = keyEvent.data is RawKeyEventDataMacOs;
    if (!_nonModifierKeys.contains(key) ||
        keysPressed
                .difference(isMacOS ? _macOsModifierKeys : _modifierKeys)
                .length >
            1 ||
        keysPressed.difference(_interestingKeys).isNotEmpty) {
      // If the most recently pressed key isn't a non-modifier key, or more than
      // one non-modifier key is down, or keys other than the ones we're interested in
      // are pressed, just ignore the keypress.
      return;
    }

    // TODO(ianh): It seems to be entirely possible for the selection to be null here, but
    // all the keyboard handling functions assume it is not.
    assert(selection != null);

    final bool isWordModifierPressed =
        isMacOS ? keyEvent.isAltPressed : keyEvent.isControlPressed;
    final bool isLineModifierPressed =
        isMacOS ? keyEvent.isMetaPressed : keyEvent.isAltPressed;
    final bool isShortcutModifierPressed =
        isMacOS ? keyEvent.isMetaPressed : keyEvent.isControlPressed;
    if (_movementKeys.contains(key)) {
      _handleMovement(key,
          wordModifier: isWordModifierPressed,
          lineModifier: isLineModifierPressed,
          shift: keyEvent.isShiftPressed);
    } else if (isShortcutModifierPressed && _shortcutKeys.contains(key)) {
      // _handleShortcuts depends on being started in the same stack invocation
      // as the _handleKeyEvent method
      _handleShortcuts(key);
    } else if (key == LogicalKeyboardKey.delete) {
      _handleDelete(forward: true);
    } else if (key == LogicalKeyboardKey.backspace) {
      _handleDelete(forward: false);
    }
  }

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
      return isWhitespace(currentString.codeUnitAt(0));
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
          !isWhitespace(
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

  void _handleMovement(
    LogicalKeyboardKey key, {
    required bool wordModifier,
    required bool lineModifier,
    required bool shift,
  }) {
    if (selection == null || textSelectionDelegate == null) {
      return;
    }
    if (wordModifier && lineModifier) {
      // If both modifiers are down, nothing happens on any of the platforms.
      return;
    }
    assert(selection != null);

    TextSelection newSelection = selection!;

    final bool rightArrow = key == LogicalKeyboardKey.arrowRight;
    final bool leftArrow = key == LogicalKeyboardKey.arrowLeft;
    final bool upArrow = key == LogicalKeyboardKey.arrowUp;
    final bool downArrow = key == LogicalKeyboardKey.arrowDown;

    if ((rightArrow || leftArrow) && !(rightArrow && leftArrow)) {
      // Jump to begin/end of word.
      if (wordModifier) {
        // If control/option is pressed, we will decide which way to look for a
        // word based on which arrow is pressed.
        if (leftArrow) {
          // When going left, we want to skip over any whitespace before the word,
          // so we go back to the first non-whitespace before asking for the word
          // boundary, since _selectWordAtOffset finds the word boundaries without
          // including whitespace.
          final int startPoint =
              previousCharacter(newSelection.extentOffset, plainText, false);
          final TextSelection textSelection =
              selectWordAtOffset(TextPosition(offset: startPoint));
          newSelection =
              newSelection.copyWith(extentOffset: textSelection.baseOffset);
        } else {
          // When going right, we want to skip over any whitespace after the word,
          // so we go forward to the first non-whitespace character before asking
          // for the word bounds, since _selectWordAtOffset finds the word
          // boundaries without including whitespace.
          final int startPoint =
              nextCharacter(newSelection.extentOffset, plainText, false);
          final TextSelection textSelection =
              selectWordAtOffset(TextPosition(offset: startPoint));
          newSelection =
              newSelection.copyWith(extentOffset: textSelection.extentOffset);
        }
      } else if (lineModifier) {
        // If control/command is pressed, we will decide which way to expand to
        // the beginning/end of the line based on which arrow is pressed.
        if (leftArrow) {
          // When going left, we want to skip over any whitespace before the line,
          // so we go back to the first non-whitespace before asking for the line
          // bounds, since _selectLineAtOffset finds the line boundaries without
          // including whitespace (like the newline).
          final int startPoint =
              previousCharacter(newSelection.extentOffset, plainText, false);
          final TextSelection textSelection =
              _selectLineAtOffset(TextPosition(offset: startPoint));
          newSelection.copyWith(extentOffset: textSelection.baseOffset);
        } else {
          // When going right, we want to skip over any whitespace after the line,
          // so we go forward to the first non-whitespace character before asking
          // for the line bounds, since _selectLineAtOffset finds the line
          // boundaries without including whitespace (like the newline).
          final int startPoint =
              nextCharacter(newSelection.extentOffset, plainText, false);
          final TextSelection textSelection =
              _selectLineAtOffset(TextPosition(offset: startPoint));
          newSelection =
              newSelection.copyWith(extentOffset: textSelection.extentOffset);
        }
      } else {
        if (rightArrow && newSelection.extentOffset < plainText.length) {
          final int nextExtent =
              nextCharacter(newSelection.extentOffset, plainText);
          final int distance = nextExtent - newSelection.extentOffset;
          newSelection = newSelection.copyWith(extentOffset: nextExtent);
          if (shift) {
            _cursorResetLocation += distance;
          }
        } else if (leftArrow && newSelection.extentOffset > 0) {
          final int previousExtent =
              previousCharacter(newSelection.extentOffset, plainText);
          final int distance = newSelection.extentOffset - previousExtent;
          newSelection = newSelection.copyWith(extentOffset: previousExtent);
          if (shift) {
            _cursorResetLocation -= distance;
          }
        }
      }
    }

    // Handles moving the cursor vertically as well as taking care of the
    // case where the user moves the cursor to the end or beginning of the text
    // and then back up or down.
    if (downArrow || upArrow) {
      // The caret offset gives a location in the upper left hand corner of
      // the caret so the middle of the line above is a half line above that
      // point and the line below is 1.5 lines below that point.
      final double preferredLineHeight = textPainter.preferredLineHeight;
      final double verticalOffset =
          upArrow ? -0.5 * preferredLineHeight : 1.5 * preferredLineHeight;

      final Offset caretOffset = textPainter.getOffsetForCaret(
          TextPosition(offset: newSelection.extentOffset), caretPrototype);
      final Offset caretOffsetTranslated =
          caretOffset.translate(0.0, verticalOffset);
      final TextPosition position =
          textPainter.getPositionForOffset(caretOffsetTranslated);

      // To account for the possibility where the user vertically highlights
      // all the way to the top or bottom of the text, we hold the previous
      // cursor location. This allows us to restore to this position in the
      // case that the user wants to unhighlight some text.
      if (position.offset == newSelection.extentOffset) {
        if (downArrow) {
          newSelection = newSelection.copyWith(extentOffset: plainText.length);
        } else if (upArrow) {
          newSelection = newSelection.copyWith(extentOffset: 0);
        }
        _wasSelectingVerticallyWithKeyboard = shift;
      } else if (_wasSelectingVerticallyWithKeyboard && shift) {
        newSelection =
            newSelection.copyWith(extentOffset: _cursorResetLocation);
        _wasSelectingVerticallyWithKeyboard = false;
      } else {
        newSelection = newSelection.copyWith(extentOffset: position.offset);
        _cursorResetLocation = newSelection.extentOffset;
      }
    }

    // Just place the collapsed selection at the end or beginning of the region
    // if shift isn't down.
    if (!shift) {
      // We want to put the cursor at the correct location depending on which
      // arrow is used while there is a selection.
      int newOffset = newSelection.extentOffset;
      if (!selection!.isCollapsed) {
        if (leftArrow) {
          newOffset = newSelection.baseOffset < newSelection.extentOffset
              ? newSelection.baseOffset
              : newSelection.extentOffset;
        } else if (rightArrow) {
          newOffset = newSelection.baseOffset > newSelection.extentOffset
              ? newSelection.baseOffset
              : newSelection.extentOffset;
        }
      }
      newSelection =
          TextSelection.fromPosition(TextPosition(offset: newOffset));
    }

    // Update the text selection delegate so that the engine knows what we did.
    textSelectionDelegate!.userUpdateTextEditingValue(
      textSelectionDelegate!.textEditingValue.copyWith(selection: newSelection),
      SelectionChangedCause.keyboard,
    );

    _handleSelectionChange(
      newSelection,
      SelectionChangedCause.keyboard,
    );
  }

  // Handles shortcut functionality including cut, copy, paste and select all
  // using control/command + (X, C, V, A).
  Future<void> _handleShortcuts(LogicalKeyboardKey key) async {
    if (textSelectionDelegate == null) {
      return;
    }
    assert(_shortcutKeys.contains(key), 'shortcut key $key not recognized.');
    if (key == LogicalKeyboardKey.keyC) {
      if (!selection!.isCollapsed) {
        Clipboard.setData(
            ClipboardData(text: selection!.textInside(plainText)));
      }
      return;
    }
    if (key == LogicalKeyboardKey.keyX) {
      if (!selection!.isCollapsed) {
        Clipboard.setData(
            ClipboardData(text: selection!.textInside(plainText)));
        textSelectionDelegate!.userUpdateTextEditingValue(
          TextEditingValue(
            text: selection!.textBefore(plainText) +
                selection!.textAfter(plainText),
            selection: TextSelection.collapsed(offset: selection!.start),
          ),
          SelectionChangedCause.keyboard,
        );
      }
      return;
    }
    if (key == LogicalKeyboardKey.keyV) {
      // Snapshot the input before using `await`.
      // See https://github.com/flutter/flutter/issues/11427
      final TextEditingValue value = textSelectionDelegate!.textEditingValue;
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null) {
        textSelectionDelegate!.userUpdateTextEditingValue(
          TextEditingValue(
            text: value.selection.textBefore(value.text) +
                data.text! +
                value.selection.textAfter(value.text),
            selection: TextSelection.collapsed(
                offset: value.selection.start + data.text!.length),
          ),
          SelectionChangedCause.keyboard,
        );
      }
      return;
    }
    if (key == LogicalKeyboardKey.keyA) {
      _handleSelectionChange(
        selection!.copyWith(
          baseOffset: 0,
          extentOffset: textSelectionDelegate!.textEditingValue.text.length,
        ),
        SelectionChangedCause.keyboard,
      );
      return;
    }
  }

  void _handleDelete({
    required bool forward,
  }) {
    if (textSelectionDelegate == null) {
      return;
    }
    final TextSelection selection =
        textSelectionDelegate!.textEditingValue.selection;
    final String text = textSelectionDelegate!.textEditingValue.text;
    if (readOnly || !selection.isValid) {
      return;
    }
    String textBefore = selection.textBefore(text);
    String textAfter = selection.textAfter(text);
    int cursorPosition = math.min(selection.start, selection.end);
    // If not deleting a selection, delete the next/previous character.
    if (selection.isCollapsed) {
      if (!forward && textBefore.isNotEmpty) {
        final int characterBoundary =
            previousCharacter(textBefore.length, textBefore);
        textBefore = textBefore.substring(0, characterBoundary);
        cursorPosition = characterBoundary;
      }
      if (forward && textAfter.isNotEmpty) {
        final int deleteCount = nextCharacter(0, textAfter);
        textAfter = textAfter.substring(deleteCount);
      }
    }
    final TextSelection newSelection =
        TextSelection.collapsed(offset: cursorPosition);
    if (selection != newSelection) {
      _handleSelectionChange(
        newSelection,
        SelectionChangedCause.keyboard,
      );
    }
    textSelectionDelegate!.userUpdateTextEditingValue(
      TextEditingValue(
        text: textBefore + textAfter,
        selection: newSelection,
      ),
      SelectionChangedCause.keyboard,
    );
  }

  TextSelection _selectLineAtOffset(TextPosition position) {
    assert(
        textLayoutLastMaxWidth == constraints.maxWidth &&
            textLayoutLastMinWidth == constraints.minWidth,
        'Last width ($textLayoutLastMinWidth, $textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).');
    final TextRange line = textPainter.getLineBoundary(position);
    TextSelection? selection;
    if (position.offset >= line.end)
      selection = TextSelection.fromPosition(position);

    if (selection == null) {
      // If text is obscured, the entire string should be treated as one line.
      if (obscureText) {
        return TextSelection(baseOffset: 0, extentOffset: plainText.length);
      }
      selection = TextSelection(baseOffset: line.start, extentOffset: line.end);
    }

    return hasSpecialInlineSpanBase
        ? convertTextPainterSelectionToTextInputSelection(text!, selection,
            selectWord: true)
        : selection;
  }
}
