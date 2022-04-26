//import 'package:extended_text_library/src/painting_image_span.dart';
// ignore_for_file: unnecessary_null_comparison, always_put_control_body_on_new_line

import 'dart:math' as math;
import 'dart:ui' as ui show PlaceholderAlignment, BoxWidthStyle, BoxHeightStyle;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../special_inline_span_base.dart';

///
///  create by zmtzawqlp on 2019/8/1
///

/// [ExtendedRenderEditable](https://github.com/fluttercandies/extended_text_field/blob/master/lib/src/extended_render_editable.dart#L104)
/// [ExtendedRenderParagraph](https://github.com/fluttercandies/extended_text/blob/master/lib/src/extended_render_paragraph.dart#L13)
///
/// Widget Span for them
/// flutter/packages/flutter/lib/src/rendering/paragraph.dart
abstract class ExtendedTextRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TextParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TextParentData>,
        RelayoutWhenSystemFontsChangeMixin {
  TextPainter get textPainter;
  ui.BoxWidthStyle get selectionWidthStyle;
  ui.BoxHeightStyle get selectionHeightStyle;
  bool get softWrap;
  TextOverflow get overflow;
  double? textLayoutLastMaxWidth;
  double? textLayoutLastMinWidth;
  double get caretMargin;
  bool get isMultiline;
  bool get forceLine;
  String get plainText;
  Offset get effectiveOffset;
  // only for [ExtendedText]
  Widget? get overflowWidget;
  // only for [ExtendedTextField]
  Offset get paintOffset;
  int get textChildCount =>
      overflowWidget != null ? childCount - 1 : childCount;
  bool get hasPlaceholderSpan => _placeholderSpans.isNotEmpty;
  bool _hasSpecialInlineSpanBase = false;
  bool get hasSpecialInlineSpanBase => _hasSpecialInlineSpanBase;
  late List<PlaceholderSpan> _placeholderSpans;
  List<PlaceholderSpan> get placeholderSpans => _placeholderSpans;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  double get textScaleFactor => textPainter.textScaleFactor;
  set textScaleFactor(double value) {
    assert(value != null);
    if (textPainter.textScaleFactor == value) return;
    textPainter.textScaleFactor = value;
    markNeedsTextLayout();
  }

  void extractPlaceholderSpans(InlineSpan? span) {
    _placeholderSpans = <PlaceholderSpan>[];
    span?.visitChildren((InlineSpan span) {
      if (span is PlaceholderSpan) {
        final PlaceholderSpan placeholderSpan = span;
        _placeholderSpans.add(placeholderSpan);
      }
      if (span is SpecialInlineSpanBase) {
        _hasSpecialInlineSpanBase = true;
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
    RenderBox? child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions =
        List<PlaceholderDimensions>.filled(
            textChildCount, PlaceholderDimensions.empty,
            growable: false);
    int childIndex = 0;
    while (child != null && childIndex < textChildCount) {
      // Height and baseline is irrelevant as all text will be laid
      // out in a single line. Therefore, using 0.0 as a dummy for the height.
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: Size(child.getMaxIntrinsicWidth(double.infinity), 0.0),
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    textPainter.setPlaceholderDimensions(placeholderDimensions);
  }

  void _computeChildrenWidthWithMinIntrinsics(double height) {
    RenderBox? child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions =
        List<PlaceholderDimensions>.filled(
            textChildCount, PlaceholderDimensions.empty,
            growable: false);
    int childIndex = 0;
    while (child != null && childIndex < textChildCount) {
      // Height and baseline is irrelevant; only looking for the widest word or
      // placeholder. Therefore, using 0.0 as a dummy for height.
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: Size(child.getMinIntrinsicWidth(double.infinity), 0.0),
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    textPainter.setPlaceholderDimensions(placeholderDimensions);
  }

  void _computeChildrenHeightWithMinIntrinsics(double width) {
    RenderBox? child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions =
        List<PlaceholderDimensions>.filled(
            textChildCount, PlaceholderDimensions.empty,
            growable: false);
    int childIndex = 0;
    // Takes textScaleFactor into account because the content of the placeholder
    // span will be scaled up when it paints.
    width = width / textScaleFactor;
    while (child != null && childIndex < textChildCount) {
      final Size size = child.getDryLayout(BoxConstraints(maxWidth: width));
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: size,
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    textPainter.setPlaceholderDimensions(placeholderDimensions);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // Hit test text spans.
    late final bool hitText;
    final TextPosition textPosition =
        textPainter.getPositionForOffset(position - paintOffset);
    final InlineSpan? span = textPainter.text!.getSpanForPosition(textPosition);
    if (span != null && span is HitTestTarget) {
      result.add(HitTestEntry(span as HitTestTarget));
      hitText = true;
    } else {
      hitText = false;
    }

    RenderBox? child = firstChild;
    int childIndex = 0;
    while (child != null &&
        childIndex < textPainter.inlinePlaceholderBoxes!.length) {
      final bool isHit = hitTestChild(result, child, position: position);
      if (isHit) {
        return true;
      }
      child = childAfter(child);
      childIndex += 1;
    }
    return hitText;
  }

  bool hitTestChild(
    BoxHitTestResult result,
    RenderBox child, {
    required Offset position,
  }) {
    final TextParentData textParentData = child.parentData as TextParentData;
    final Matrix4 transform = Matrix4.translationValues(
        textParentData.offset.dx + effectiveOffset.dx,
        textParentData.offset.dy + effectiveOffset.dy,
        0.0)
      ..scale(
        textParentData.scale,
        textParentData.scale,
        textParentData.scale,
      );
    final bool isHit = result.addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        assert(() {
          final Offset manualPosition =
              (position - textParentData.offset - effectiveOffset) /
                  textParentData.scale!;
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
  List<PlaceholderDimensions>? _placeholderDimensions;
  List<PlaceholderDimensions>? get placeholderDimensions =>
      _placeholderDimensions;
  // Layout the child inline widgets. We then pass the dimensions of the
  // children to _textPainter so that appropriate placeholders can be inserted
  // into the LibTxt layout. This does not do anything if no inline widgets were
  // specified.
  void layoutChildren(
    BoxConstraints constraints, {
    List<int>? hideWidgets,
    TextPainter? textPainter,
    bool dry = false,
  }) {
    if (childCount == 0) {
      return;
    }
    RenderBox? child = firstChild;
    _placeholderDimensions = List<PlaceholderDimensions>.filled(
        textChildCount, PlaceholderDimensions.empty,
        growable: false);
    // Only constrain the width to the maximum width of the paragraph.
    // Leave height unconstrained, which will overflow if expanded past.
    BoxConstraints boxConstraints =
        BoxConstraints(maxWidth: constraints.maxWidth);
    // The content will be enlarged by textScaleFactor during painting phase.
    // We reduce constraints by textScaleFactor, so that the content will fit
    // into the box once it is enlarged.
    boxConstraints = boxConstraints / textScaleFactor;
    int childIndex = 0;
    while (child != null && childIndex < textChildCount) {
      double? baselineOffset;
      final Size childSize;

      if (!dry) {
        // Only constrain the width to the maximum width of the paragraph.
        // Leave height unconstrained, which will overflow if expanded past.
        child.layout(
          hideWidgets != null && hideWidgets.contains(childIndex)
              ? const BoxConstraints(maxWidth: 0)
              : boxConstraints,
          parentUsesSize: true,
        );
        childSize = child.size;
        switch (_placeholderSpans[childIndex].alignment) {
          case ui.PlaceholderAlignment.baseline:
            baselineOffset = child.getDistanceToBaseline(
              _placeholderSpans[childIndex].baseline!,
            );
            break;
          case ui.PlaceholderAlignment.aboveBaseline:
          case ui.PlaceholderAlignment.belowBaseline:
          case ui.PlaceholderAlignment.bottom:
          case ui.PlaceholderAlignment.middle:
          case ui.PlaceholderAlignment.top:
            baselineOffset = null;
            break;
        }
      } else {
        assert(_placeholderSpans[childIndex].alignment !=
            ui.PlaceholderAlignment.baseline);
        childSize = child.getDryLayout(boxConstraints);
      }

      _placeholderDimensions![childIndex] = PlaceholderDimensions(
        size: childSize,
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
        baselineOffset: baselineOffset,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    (textPainter ?? this.textPainter)
        .setPlaceholderDimensions(_placeholderDimensions);
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
    RenderBox? child = firstChild;
    int childIndex = 0;

    // maybe overflow
    while (child != null &&
        childIndex < textPainter.inlinePlaceholderBoxes!.length) {
      final TextParentData textParentData = child.parentData as TextParentData;

      textParentData.offset = Offset(
        textPainter.inlinePlaceholderBoxes![childIndex].left,
        textPainter.inlinePlaceholderBoxes![childIndex].top,
      );
      textParentData.scale = textPainter.inlinePlaceholderScales![childIndex];
      child = childAfter(child);
      childIndex += 1;
    }
  }

  void layoutText(
      {double minWidth = 0.0,
      double maxWidth = double.infinity,
      bool forceLayout = false}) {
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

  void paintWidgets(PaintingContext context, Offset offset,
      {Rect? overFlowRect}) {
    RenderBox? child = firstChild;
    int childIndex = 0;

    ///maybe overflow
    while (child != null &&
        childIndex < textPainter.inlinePlaceholderBoxes!.length) {
      //assert(childIndex < _textPainter.inlinePlaceholderBoxes.length);

      final TextParentData textParentData = child.parentData as TextParentData;

      final double? scale = textParentData.scale;

      final Rect rect = (offset + textParentData.offset) & child.size;
      bool overlaps = false;
      if (overFlowRect != null) {
        if (overFlowRect.overlaps(rect)) {
          final Rect intersectRect = overFlowRect.intersect(rect);
          overlaps = intersectRect.size > const Offset(1, 1);
        }
      }

      if (!overlaps) {
        context.pushTransform(
          needsCompositing,
          offset + textParentData.offset,
          Matrix4.diagonal3Values(scale!, scale, scale),
          (PaintingContext context, Offset offset) {
            context.paintChild(
              child!,
              offset,
            );
          },
        );
      }

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
  Offset getCaretOffset(
    TextPosition textPosition, {
    ValueChanged<double>? caretHeightCallBack,
    Offset? effectiveOffset,
    Rect caretPrototype = Rect.zero,
  }) {
    effectiveOffset ??= Offset.zero;

    ///zmt
    /// fix widget span
    if (hasPlaceholderSpan) {
      ///if first index, check by first span
      int offset = textPosition.offset;
      List<TextBox> boxs = textPainter.getBoxesForSelection(
        TextSelection(
            baseOffset: offset,
            extentOffset: offset + 1,
            affinity: textPosition.affinity),
        boxWidthStyle: selectionWidthStyle,
        boxHeightStyle: selectionHeightStyle,
      );
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
  void computeTextMetricsIfNeeded() {
    assert(constraints != null);
    layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
  }
}
