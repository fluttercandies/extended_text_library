import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui' as ui show PlaceholderAlignment;

///
///  create by zmtzawqlp on 2019/8/1
///

abstract class ExtendedTextRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TextParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TextParentData> {
  TextPainter get textPainter;
  bool get softWrap;
  TextOverflow get overflow;

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
    for (PlaceholderSpan span in _placeholderSpans) {
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
        List<PlaceholderDimensions>(childCount);
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
        List<PlaceholderDimensions>(childCount);
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
        List<PlaceholderDimensions>(childCount);
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

  // Layout the child inline widgets. We then pass the dimensions of the
  // children to _textPainter so that appropriate placeholders can be inserted
  // into the LibTxt layout. This does not do anything if no inline widgets were
  // specified.
  void layoutChildren(BoxConstraints constraints) {
    if (childCount == 0) {
      return;
    }
    RenderBox child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions =
        List<PlaceholderDimensions>(childCount);
    int childIndex = 0;
    while (child != null) {
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
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: child.size,
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
        baselineOffset: baselineOffset,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    textPainter.setPlaceholderDimensions(placeholderDimensions);
  }

  // Iterate through the laid-out children and set the parentData offsets based
  // off of the placeholders inserted for each child.
  void setParentData() {
    RenderBox child = firstChild;
    int childIndex = 0;

    ///maybe overflow
    while (child != null &&
        childIndex < textPainter.inlinePlaceholderBoxes.length) {
      final TextParentData textParentData = child.parentData;

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
      double constraintWidth = double.infinity}) {
    final bool widthMatters = softWrap || overflow == TextOverflow.ellipsis;
    textPainter.layout(
        minWidth: minWidth,
        maxWidth: widthMatters ? maxWidth : double.infinity);
  }

  void paintWidgets(PaintingContext context, Offset offset) {
    RenderBox child = firstChild;
    int childIndex = 0;

    ///maybe overflow
    while (child != null &&
        childIndex < textPainter.inlinePlaceholderBoxes.length) {
      //assert(childIndex < _textPainter.inlinePlaceholderBoxes.length);

      final TextParentData textParentData = child.parentData;

      final double scale = textParentData.scale;
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

  Offset getCaretOffset(TextPosition textPosition,
      {ValueChanged<double> caretHeightCallBack,
      Offset effectiveOffset,
      bool handleSpecialText: true,
      Rect caretPrototype: Rect.zero}) {
    effectiveOffset ??= Offset.zero;

    ///zmt
    if (handleSpecialText) {
      ///if first index, check by first span
      var offset = textPosition.offset;
      var boxs = textPainter.getBoxesForSelection(TextSelection(
          baseOffset: offset,
          extentOffset: offset + 1,
          affinity: textPosition.affinity));
      if (boxs.length > 0) {
        var rect = boxs.toList().last.toRect();
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
        if (boxs.length > 0) {
          var rect = boxs.toList().last.toRect();
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
}
