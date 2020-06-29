//import 'package:extended_text_library/src/painting_image_span.dart';
import 'dart:math' as math;
import 'dart:ui' as ui show PlaceholderAlignment;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

///
///  create by zmtzawqlp on 2019/8/1
///

/// [ExtendedRenderEditable](https://github.com/fluttercandies/extended_text_field/blob/master/lib/src/extended_render_editable.dart#L104)
/// [ExtendedRenderParagraph](https://github.com/fluttercandies/extended_text/blob/master/lib/src/extended_render_paragraph.dart#L13)
///
/// Widget Span for them
abstract class ExtendedTextRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TextParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TextParentData>,
        RelayoutWhenSystemFontsChangeMixin {
  TextPainter get textPainter;
  bool get softWrap;
  TextOverflow get overflow;
  double textLayoutLastMaxWidth;
  double textLayoutLastMinWidth;
  double get caretMargin;
  bool get isMultiline;
  bool get forceLine;
  String get plainText;
  Offset get effectiveOffset;
  //only for [ExtendedText]
  Widget get overflowWidget;
  int get textChildCount =>
      overflowWidget != null ? childCount - 1 : childCount;

  List<PlaceholderSpan> _placeholderSpans;

  void extractPlaceholderSpans(InlineSpan span) {
    _placeholderSpans = <PlaceholderSpan>[];
    span.visitChildren((InlineSpan span) {
      if (span is PlaceholderSpan) {
        final PlaceholderSpan placeholderSpan = span;
        _placeholderSpans.add(placeholderSpan);
      }
      return true;
    });
  }

  // Intrinsics cannot be calculated without a full layout for
  // alignments that require the baseline (baseline, aboveBaseline,
  // belowBaseline).
  bool _canComputeIntrinsics() {
    for (final PlaceholderSpan span in _placeholderSpans) {
      switch (span.alignment) {
        case ui.PlaceholderAlignment.baseline:
        case ui.PlaceholderAlignment.aboveBaseline:
        case ui.PlaceholderAlignment.belowBaseline:
          {
            assert(
                RenderObject.debugCheckingIntrinsics,
                'Intrinsics are not available for PlaceholderAlignment.baseline, '
                'PlaceholderAlignment.aboveBaseline, or PlaceholderAlignment.belowBaseline,');
            return false;
          }
        case ui.PlaceholderAlignment.top:
        case ui.PlaceholderAlignment.middle:
        case ui.PlaceholderAlignment.bottom:
          {
            continue;
          }
      }
    }
    return true;
  }

  void _computeChildrenWidthWithMaxIntrinsics(double height) {
    RenderBox child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions =
        List<PlaceholderDimensions>(textChildCount);
    int childIndex = 0;
    while (child != null) {
      // Height and baseline is irrelevant as all text will be laid
      // out in a single line.
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: Size(child.getMaxIntrinsicWidth(height), height),
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    textPainter.setPlaceholderDimensions(placeholderDimensions);
  }

  void _computeChildrenWidthWithMinIntrinsics(double height) {
    RenderBox child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions =
        List<PlaceholderDimensions>(textChildCount);
    int childIndex = 0;
    while (child != null) {
      final double intrinsicWidth = child.getMinIntrinsicWidth(height);
      final double intrinsicHeight =
          child.getMinIntrinsicHeight(intrinsicWidth);
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: Size(intrinsicWidth, intrinsicHeight),
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    textPainter.setPlaceholderDimensions(placeholderDimensions);
  }

  void _computeChildrenHeightWithMinIntrinsics(double width) {
    RenderBox child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions =
        List<PlaceholderDimensions>(textChildCount);
    int childIndex = 0;
    while (child != null) {
      final double intrinsicHeight = child.getMinIntrinsicHeight(width);
      final double intrinsicWidth = child.getMinIntrinsicWidth(intrinsicHeight);
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: Size(intrinsicWidth, intrinsicHeight),
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    textPainter.setPlaceholderDimensions(placeholderDimensions);
  }

  double _computeIntrinsicHeight(double width) {
    if (!_canComputeIntrinsics()) {
      return 0.0;
    }
    _computeChildrenHeightWithMinIntrinsics(width);
    layoutText(minWidth: width, maxWidth: width);
    return textPainter.height;
  }

  // Placeholder dimensions representing the sizes of child inline widgets.
  //
  // These need to be cached because the text painter's placeholder dimensions
  // will be overwritten during intrinsic width/height calculations and must be
  // restored to the original values before final layout and painting.
  List<PlaceholderDimensions> _placeholderDimensions;

  // Layout the child inline widgets. We then pass the dimensions of the
  // children to _textPainter so that appropriate placeholders can be inserted
  // into the LibTxt layout. This does not do anything if no inline widgets were
  // specified.
  void layoutChildren(BoxConstraints constraints) {
    if (childCount == 0) {
      return;
    }
    RenderBox child = firstChild;
    _placeholderDimensions = List<PlaceholderDimensions>(textChildCount);
    int childIndex = 0;
    while (child != null && childIndex < _placeholderDimensions.length) {
      // Only constrain the width to the maximum width of the paragraph.
      // Leave height unconstrained, which will overflow if expanded past.
      child.layout(
          BoxConstraints(
            maxWidth: constraints.maxWidth,
          ),
          parentUsesSize: true);
      double baselineOffset;
      switch (_placeholderSpans[childIndex].alignment) {
        case ui.PlaceholderAlignment.baseline:
          {
            baselineOffset = child
                .getDistanceToBaseline(_placeholderSpans[childIndex].baseline);
            break;
          }
        default:
          {
            baselineOffset = null;
            break;
          }
      }
      _placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: child.size,
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
        baselineOffset: baselineOffset,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    textPainter.setPlaceholderDimensions(_placeholderDimensions);
  }

  //layoutText for extended_text
  void layoutTextWithConstraints(BoxConstraints constraints) {
    textPainter.setPlaceholderDimensions(_placeholderDimensions);
    layoutText(
      minWidth: constraints.minWidth,
      maxWidth: constraints.maxWidth,
      forceLayout: true,
    );
  }

  // Iterate through the laid-out children and set the parentData offsets based
  // off of the placeholders inserted for each child.
  void setParentData() {
    RenderBox child = firstChild;
    int childIndex = 0;

    ///maybe overflow
    while (child != null &&
        childIndex < textPainter.inlinePlaceholderBoxes.length) {
      final TextParentData textParentData = child.parentData as TextParentData;

      textParentData.offset = Offset(
          textPainter.inlinePlaceholderBoxes[childIndex].left,
          textPainter.inlinePlaceholderBoxes[childIndex].top);
      textParentData.scale = textPainter.inlinePlaceholderScales[childIndex];
      child = childAfter(child);
      childIndex += 1;
    }
  }

  void layoutText(
      {double minWidth = 0.0,
      double maxWidth = double.infinity,
      bool forceLayout = false}) {
    assert(maxWidth != null && minWidth != null);

    if (textLayoutLastMaxWidth == maxWidth &&
        textLayoutLastMinWidth == minWidth &&
        !forceLayout) {
      return;
    }
    final bool widthMatters =
        softWrap || overflow == TextOverflow.ellipsis || isMultiline;
    final double availableMaxWidth = math.max(0.0, maxWidth - caretMargin);
    final double availableMinWidth = math.min(minWidth, availableMaxWidth);
    final double textMaxWidth =
        widthMatters ? availableMaxWidth : double.infinity;
    final double textMinWidth =
        forceLine ? availableMaxWidth : availableMinWidth;
    textPainter.layout(
      minWidth: textMinWidth,
      maxWidth: textMaxWidth,
    );
    textLayoutLastMinWidth = minWidth;
    textLayoutLastMaxWidth = maxWidth;
  }

  void paintWidgets(PaintingContext context, Offset offset, {Path clip}) {
    RenderBox child = firstChild;
    int childIndex = 0;

    ///maybe overflow
    while (child != null &&
        childIndex < textPainter.inlinePlaceholderBoxes.length) {
      //assert(childIndex < _textPainter.inlinePlaceholderBoxes.length);

      final TextParentData textParentData = child.parentData as TextParentData;

      final double scale = textParentData.scale;

      final Rect rect = (offset + textParentData.offset) & child.size;
      if (clip != null && !clip.contains(rect.centerLeft)) {
        break;
      }
      context.pushTransform(
        needsCompositing,
        offset + textParentData.offset,
        Matrix4.diagonal3Values(scale, scale, scale),
        (PaintingContext context, Offset offset) {
          context.paintChild(
            child,
            offset,
          );
        },
      );
      child = childAfter(child);
      childIndex += 1;
    }
  }

  // void paintImages(Canvas canvas, PaintingImageSpan ts, Offset offset) {
  //   ///imageSpanTransparentPlaceholder \u200B has no width, and we define image width by
  //   ///use letterSpacing,so the actual top-left offset of image should be subtract letterSpacing(width)/2.0
  //   Offset imageSpanOffset = offset - Offset(ts.width / 2.0, 0.0);

  //   if (!ts.paint(canvas, imageSpanOffset)) {
  //     //image not ready
  //     ts.resolveImage(listener: (ImageInfo imageInfo, bool synchronousCall) {
  //       if (synchronousCall)
  //         ts.paint(canvas, imageSpanOffset);
  //       else {
  //         if (owner == null || !owner.debugDoingPaint) {
  //           markNeedsPaint();
  //         }
  //       }
  //     });
  //   }
  // }

  // @override
  // void detach() {
  //   super.detach();
  //   _disposePaintingImageSpan(<InlineSpan>[textPainter.text]);
  // }

  // void _disposePaintingImageSpan(List<InlineSpan> textSpan) {
  //   textSpan.forEach((ts) {
  //     if (ts is PaintingImageSpan) {
  //       ts.dispose();
  //     } else if (ts is TextSpan && ts.children != null) {
  //       _disposePaintingImageSpan(ts.children);
  //     }
  //   });
  // }

  // it seems TextPainter works for WidgetSpan on 1.17.0
  // code under 1.17.0
  Offset getCaretOffset(TextPosition textPosition,
      {ValueChanged<double> caretHeightCallBack,
      Offset effectiveOffset,
      bool handleSpecialText = true,
      Rect caretPrototype = Rect.zero}) {
    effectiveOffset ??= Offset.zero;

    ///zmt
    if (handleSpecialText) {
      ///if first index, check by first span
      int offset = textPosition.offset;
      List<TextBox> boxs = textPainter.getBoxesForSelection(TextSelection(
          baseOffset: offset,
          extentOffset: offset + 1,
          affinity: textPosition.affinity));
      if (boxs.isNotEmpty) {
        final Rect rect = boxs.toList().last.toRect();
        caretHeightCallBack?.call(rect.height);
        return rect.topLeft + effectiveOffset;
      } else {
        if (offset <= 0) {
          offset = 1;
        }
        boxs = textPainter.getBoxesForSelection(TextSelection(
            baseOffset: offset - 1,
            extentOffset: offset,
            affinity: textPosition.affinity));
        if (boxs.isNotEmpty) {
          final Rect rect = boxs.toList().last.toRect();
          caretHeightCallBack?.call(rect.height);
          if (textPosition.offset <= 0) {
            return rect.topLeft + effectiveOffset;
          } else {
            return rect.topRight + effectiveOffset;
          }
        }
      }
    }

    final Offset caretOffset =
        textPainter.getOffsetForCaret(textPosition, caretPrototype) +
            effectiveOffset;
    return caretOffset;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TextParentData)
      child.parentData = TextParentData();
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(width);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (!_canComputeIntrinsics()) {
      return 0.0;
    }
    _computeChildrenWidthWithMinIntrinsics(height);
    layoutText(); // layout with infinite width.
    return textPainter.minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (!_canComputeIntrinsics()) {
      return 0.0;
    }
    _computeChildrenWidthWithMaxIntrinsics(height);
    layoutText(); // layout with infinite width.
    return textPainter.maxIntrinsicWidth;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!debugNeedsLayout);
    assert(constraints != null);
    assert(constraints.debugAssertIsValid());
    layoutTextWithConstraints(constraints);
    // todo(garyq): Since our metric for ideographic baseline is currently
    // inaccurate and the non-alphabetic baselines are based off of the
    // alphabetic baseline, we use the alphabetic for now to produce correct
    // layouts. We should eventually change this back to pass the `baseline`
    // property when the ideographic baseline is properly implemented
    // (https://github.com/flutter/flutter/issues/22625).
    return textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  }

  /// Marks the render object as needing to be laid out again and have its text
  /// metrics recomputed.
  ///
  /// Implies [markNeedsLayout].
  @protected
  void markNeedsTextLayout() {
    textLayoutLastMaxWidth = null;
    textLayoutLastMinWidth = null;
    markNeedsLayout();
  }

  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    textPainter.markNeedsLayout();
    textLayoutLastMaxWidth = null;
    textLayoutLastMinWidth = null;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    RenderBox child = firstChild;
    int childIndex = 0;
    while (child != null &&
        childIndex < textPainter.inlinePlaceholderBoxes.length) {
      final bool isHit = hitTestChild(result, child, position: position);
      if (isHit) {
        return true;
      }
      child = childAfter(child);
      childIndex += 1;
    }
    return false;
  }

  bool hitTestChild(
    BoxHitTestResult result,
    RenderBox child, {
    Offset position,
  }) {
    final TextParentData textParentData = child.parentData as TextParentData;
    final Matrix4 transform = Matrix4.translationValues(
        textParentData.offset.dx + effectiveOffset.dx,
        textParentData.offset.dy + effectiveOffset.dy,
        0.0)
      ..scale(textParentData.scale, textParentData.scale, textParentData.scale);
    final bool isHit = result.addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        assert(() {
          final Offset manualPosition =
              (position - textParentData.offset - effectiveOffset) /
                  textParentData.scale;
          return (transformed.dx - manualPosition.dx).abs() <
                  precisionErrorTolerance &&
              (transformed.dy - manualPosition.dy).abs() <
                  precisionErrorTolerance;
        }());
        return child.hitTest(result, position: transformed);
      },
    );
    return isHit;
  }
}
