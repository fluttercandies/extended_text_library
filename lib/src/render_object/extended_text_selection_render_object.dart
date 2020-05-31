import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

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

/// [ExtendedRenderEditable](https://github.com/fluttercandies/extended_text_field/blob/master/lib/src/extended_render_editable.dart#L104)
/// [ExtendedRenderParagraph](https://github.com/fluttercandies/extended_text/blob/master/lib/src/extended_render_paragraph.dart#L13)
///
/// TextSelection for them
abstract class ExtendedTextSelectionRenderObject extends ExtendedTextRenderBox {
  ValueListenable<bool> get selectionStartInViewport;
  ValueListenable<bool> get selectionEndInViewport;
  List<TextSelectionPoint> getEndpointsForSelection(TextSelection selection);
  TextSelection get selection;

  double get preferredLineHeight;
  TextPosition getPositionForPoint(Offset globalPosition);
  bool get handleSpecialText;
  InlineSpan get text;
  bool get isAttached;
  TextDirection get textDirection;
  LayerLink get startHandleLayerLink;
  LayerLink get endHandleLayerLink;
  TextSelectionChangedHandler get onSelectionChanged;
  Offset get paintOffset;
  bool get obscureText;
  Color get selectionColor;
  List<ui.TextBox> get selectionRects;

  // This affinity should never be null.
  TextAffinity fallbackAffinity = TextAffinity.downstream;

  ///selection
  Offset lastTapDownPosition;

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [TapGestureRecognizer.onTapDown]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to tap
  /// down events by calling this method.
  void handleTapDown(TapDownDetails details) {
    lastTapDownPosition = details.globalPosition;
  }

  /// Select a word around the location of the last tap down.
  ///
  /// {@macro flutter.rendering.editable.select}
  void selectWord({@required SelectionChangedCause cause}) {
    selectWordsInRange(from: lastTapDownPosition, cause: cause);
  }

  /// Selects the set words of a paragraph in a given range of global positions.
  ///
  /// The first and last endpoints of the selection will always be at the
  /// beginning and end of a word respectively.
  ///
  /// {@macro flutter.rendering.editable.select}
  void selectWordsInRange(
      {@required Offset from,
      Offset to,
      @required SelectionChangedCause cause}) {
    assert(cause != null);
    assert(from != null);
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
  void selectWordEdge({@required SelectionChangedCause cause}) {
    assert(cause != null);
    layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    assert(lastTapDownPosition != null);
    if (onSelectionChanged == null) {
      return;
    }
    final TextPosition position = textPainter
        .getPositionForOffset(globalToLocal(lastTapDownPosition - paintOffset));
    setFallbackAffinity(position.affinity);
    final TextRange word = textPainter.getWordBoundary(position);
    final TextRange lineBoundary = textPainter.getLineBoundary(position);
    final bool endOfLine =
        lineBoundary?.end == position.offset && position.affinity != null;
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

    selection = handleSpecialText
        ? convertTextPainterSelectionToTextInputSelection(text, selection)
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
  void selectPosition({@required SelectionChangedCause cause}) {
    selectPositionAt(from: lastTapDownPosition, cause: cause);
  }

  /// Select text between the global positions [from] and [to].
  void selectPositionAt(
      {@required Offset from,
      Offset to,
      @required SelectionChangedCause cause}) {
    assert(cause != null);
    assert(from != null);
    layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    if (onSelectionChanged != null) {
      TextPosition fromPosition =
          textPainter.getPositionForOffset(globalToLocal(from - paintOffset));
      TextPosition toPosition = to == null
          ? null
          : textPainter.getPositionForOffset(globalToLocal(to - paintOffset));

      //zmt
      if (handleSpecialText) {
        fromPosition =
            convertTextPainterPostionToTextInputPostion(text, fromPosition);
        toPosition =
            convertTextPainterPostionToTextInputPostion(text, toPosition);
      }

      int baseOffset = fromPosition.offset;
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
      setFallbackAffinity(newSelection.affinity);
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
      onSelectionChanged(nextSelection, cause);
    }
  }

  TextSelection selectWordAtOffset(TextPosition position) {
    assert(
        textLayoutLastMaxWidth == constraints.maxWidth &&
            textLayoutLastMinWidth == constraints.minWidth,
        'Last width ($textLayoutLastMinWidth, $textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).');
    final TextRange word = textPainter.getWordBoundary(position);
    // zmt
    TextSelection selection;
    // When long-pressing past the end of the text, we want a collapsed cursor.
    if (position.offset >= word.end) {
      selection = TextSelection.fromPosition(position);
    } else {
      // If text is obscured, the entire sentence should be treated as one word.
      if (obscureText) {
        selection =
            TextSelection(baseOffset: 0, extentOffset: plainText.length);
      }
      selection = TextSelection(baseOffset: word.start, extentOffset: word.end);
    }

    return handleSpecialText
        ? convertTextPainterSelectionToTextInputSelection(text, selection,
            selectWord: true)
        : selection;
  }

  // Sets the fallback affinity to the affinity of the selection.
  void setFallbackAffinity(
    TextAffinity affinity,
  ) {
    assert(affinity != null);
    // Engine-computed selections will always compute affinity when necessary.
    // Cache this affinity in the case where the platform supplied selection
    // does not provide an affinity.
    fallbackAffinity = affinity;
  }

  void paintHandleLayers(PaintingContext context,
      Function(PaintingContext context, Offset offset) paint) {
    if (startHandleLayerLink == null || endHandleLayerLink == null) {
      return;
    }

    final List<TextSelectionPoint> endpoints = getEndpointsForSelection(selection);

    if (endpoints == null || endpoints.isEmpty) {
      return;
    }

    Offset startPoint = endpoints[0].point;
    startPoint = Offset(
      startPoint.dx.clamp(0.0, size.width) as double,
      startPoint.dy.clamp(0.0, size.height) as double,
    );
    context.pushLayer(
      LeaderLayer(link: startHandleLayerLink, offset: startPoint),
      paint,
      Offset.zero,
    );
    if (endpoints.length == 2) {
      Offset endPoint = endpoints[1].point;
      endPoint = Offset(
        endPoint.dx.clamp(0.0, size.width) as double,
        endPoint.dy.clamp(0.0, size.height)as double,
      );
      context.pushLayer(
        LeaderLayer(link: endHandleLayerLink, offset: endPoint),
        paint,
        Offset.zero,
      );
    }
  }

  void paintSelection(Canvas canvas, Offset effectiveOffset) {
    assert(textLayoutLastMaxWidth == constraints.maxWidth,
        'Last width ($textLayoutLastMaxWidth) not the same as max width constraint (${constraints.maxWidth}).');
    assert(selectionRects != null);
    final Paint paint = Paint()..color = selectionColor;
    for (final ui.TextBox box in selectionRects)
      canvas.drawRect(box.toRect().shift(effectiveOffset), paint);
  }
}
