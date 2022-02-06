// ignore_for_file: always_put_control_body_on_new_line, unnecessary_null_comparison

import 'dart:ui' as ui;
import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/material.dart';

/// An interface that paints within a [RenderEditable]'s bounds, above or
/// beneath its text content.
///
/// This painter is typically used for painting auxiliary content that depends
/// on text layout metrics (for instance, for painting carets and text highlight
/// blocks). It can paint independently from its [RenderEditable], allowing it
/// to repaint without triggering a repaint on the entire [RenderEditable] stack
/// when only auxiliary content changes (e.g. a blinking cursor) are present. It
/// will be scheduled to repaint when:
///
///  * It's assigned to a new [RenderEditable] and the [shouldRepaint] method
///    returns true.
///  * Any of the [RenderEditable]s it is attached to repaints.
///  * The [notifyListeners] method is called, which typically happens when the
///    painter's attributes change.
///
/// See also:
///
///  * [RenderEditable.foregroundPainter], which takes a [ExtendedRenderEditablePainter]
///    and sets it as the foreground painter of the [RenderEditable].
///  * [RenderEditable.painter], which takes a [ExtendedRenderEditablePainter]
///    and sets it as the background painter of the [RenderEditable].
///  * [CustomPainter] a similar class which paints within a [RenderCustomPaint].
abstract class ExtendedRenderEditablePainter extends ChangeNotifier {
  /// Determines whether repaint is needed when a new [ExtendedRenderEditablePainter]
  /// is provided to a [RenderEditable].
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false. When [oldDelegate] is null, this method should always return true
  /// unless the new painter initially does not paint anything.
  ///
  /// If the method returns false, then the [paint] call might be optimized
  /// away. However, the [paint] method will get called whenever the
  /// [RenderEditable]s it attaches to repaint, even if [shouldRepaint] returns
  /// false.
  bool shouldRepaint(ExtendedRenderEditablePainter? oldDelegate);

  /// Paints within the bounds of a [RenderEditable].
  ///
  /// The given [Canvas] has the same coordinate space as the [RenderEditable],
  /// which may be different from the coordinate space the [RenderEditable]'s
  /// [TextPainter] uses, when the text moves inside the [RenderEditable].
  ///
  /// Paint operations performed outside of the region defined by the [canvas]'s
  /// origin and the [size] parameter may get clipped, when [RenderEditable]'s
  /// [RenderEditable.clipBehavior] is not [Clip.none].
  void paint(Canvas canvas, Size size,
      ExtendedTextSelectionRenderObject renderEditable);
}

class TextHighlightPainter extends ExtendedRenderEditablePainter {
  TextHighlightPainter({
    TextRange? highlightedRange,
    Color? highlightColor,
  })  : _highlightedRange = highlightedRange,
        _highlightColor = highlightColor;

  final Paint highlightPaint = Paint();

  Color? get highlightColor => _highlightColor;
  Color? _highlightColor;
  set highlightColor(Color? newValue) {
    if (newValue == _highlightColor) return;
    _highlightColor = newValue;
    notifyListeners();
  }

  TextRange? get highlightedRange => _highlightedRange;
  TextRange? _highlightedRange;
  set highlightedRange(TextRange? newValue) {
    if (newValue == _highlightedRange) return;
    _highlightedRange = newValue;
    notifyListeners();
  }

  /// Controls how tall the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxHeightStyle] for details on available styles.
  ui.BoxHeightStyle get selectionHeightStyle => _selectionHeightStyle;
  ui.BoxHeightStyle _selectionHeightStyle = ui.BoxHeightStyle.tight;
  set selectionHeightStyle(ui.BoxHeightStyle value) {
    assert(value != null);
    if (_selectionHeightStyle == value) return;
    _selectionHeightStyle = value;
    notifyListeners();
  }

  /// Controls how wide the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxWidthStyle] for details on available styles.
  ui.BoxWidthStyle get selectionWidthStyle => _selectionWidthStyle;
  ui.BoxWidthStyle _selectionWidthStyle = ui.BoxWidthStyle.tight;
  set selectionWidthStyle(ui.BoxWidthStyle value) {
    assert(value != null);
    if (_selectionWidthStyle == value) return;
    _selectionWidthStyle = value;
    notifyListeners();
  }

  @override
  void paint(Canvas canvas, Size size,
      ExtendedTextSelectionRenderObject renderEditable) {
    final TextRange? range = highlightedRange;
    final Color? color = highlightColor;
    if (range == null || color == null || range.isCollapsed) {
      return;
    }

    highlightPaint.color = color;
    final TextPainter textPainter = renderEditable.textPainter;
    final List<TextBox> boxes = textPainter.getBoxesForSelection(
      TextSelection(baseOffset: range.start, extentOffset: range.end),
      boxHeightStyle: selectionHeightStyle,
      boxWidthStyle: selectionWidthStyle,
    );

    for (final TextBox box in boxes)
      canvas.drawRect(
        box.toRect().shift(renderEditable.paintOffset).intersect(
            Rect.fromLTWH(0, 0, textPainter.width, textPainter.height)),
        highlightPaint,
      );
  }

  @override
  bool shouldRepaint(ExtendedRenderEditablePainter? oldDelegate) {
    if (identical(oldDelegate, this)) return false;
    if (oldDelegate == null)
      return highlightColor != null && highlightedRange != null;
    return oldDelegate is! TextHighlightPainter ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.highlightedRange != highlightedRange ||
        oldDelegate.selectionHeightStyle != selectionHeightStyle ||
        oldDelegate.selectionWidthStyle != selectionWidthStyle;
  }
}
