import 'dart:ui' as ui show PlaceholderAlignment, ParagraphBuilder;

import 'package:flutter/widgets.dart';

import 'special_inline_span_base.dart';

///
///  create by zmtzawqlp on 2019/7/10
///

///support selection for widget Span
class ExtendedWidgetSpan extends WidgetSpan with SpecialInlineSpanBase {
  ExtendedWidgetSpan({
    required Widget child,
    String? actualText = '\uFFFC',
    int start = 0,
    this.deleteAll = true,
    ui.PlaceholderAlignment alignment = ui.PlaceholderAlignment.bottom,
    TextBaseline? baseline,
    TextStyle? style,
    this.hide = false,
    this.keepVisible,
  })  : actualText = actualText ?? '\uFFFC',
        textRange = TextRange(
            start: start, end: start + (actualText ?? '\uFFFC').length),
        widgetSpanSize = WidgetSpanSize()..size = Size.zero,
        super(
          child: child,
          alignment: alignment,
          baseline: baseline,
          style: style,
        );
  @override
  final String actualText;

  @override
  final bool deleteAll;

  @override
  final TextRange textRange;

  @override
  final bool? keepVisible;

  /// store size to calculate selection
  final WidgetSpanSize widgetSpanSize;

  Size? get size => widgetSpanSize.size;

  /// for overflow
  final bool hide;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    if (super != other) {
      return false;
    }

    return other is ExtendedWidgetSpan &&
        hide == other.hide &&
        widgetSpanSize.size == other.widgetSpanSize.size &&
        equal(other);
  }

  @override
  int get hashCode => Object.hash(
        super.hashCode,
        baseHashCode,
        widgetSpanSize.size,
        hide,
      );

  @override
  RenderComparison compareTo(InlineSpan other) {
    RenderComparison comparison = super.compareTo(other);
    if (comparison == RenderComparison.identical) {
      if (widgetSpanSize.size !=
          (other as ExtendedWidgetSpan).widgetSpanSize.size) {
        return RenderComparison.layout;
      }
    }
    if (comparison == RenderComparison.identical) {
      comparison = baseCompareTo(other as SpecialInlineSpanBase);
    }

    return comparison;
  }

  /// Adds a placeholder box to the paragraph builder if a size has been
  /// calculated for the widget.
  ///
  /// Sizes are provided through `dimensions`, which should contain a 1:1
  /// in-order mapping of widget to laid-out dimensions. If no such dimension
  /// is provided, the widget will be skipped.
  ///
  /// The `textScaler` will be applied to the laid-out size of the widget.
  @override
  void build(
    ui.ParagraphBuilder builder, {
    TextScaler textScaler = TextScaler.noScaling,
    List<PlaceholderDimensions>? dimensions,
  }) {
    assert(debugAssertIsValid());
    assert(dimensions != null);
    final bool hasStyle = style != null;
    if (hasStyle) {
      builder.pushStyle(style!.getTextStyle(textScaler: textScaler));
    }
    assert(builder.placeholderCount < dimensions!.length);
    final PlaceholderDimensions currentDimensions =
        dimensions![builder.placeholderCount];
    // zmtzawqlp
    widgetSpanSize.size = currentDimensions.size;
    builder.addPlaceholder(
      currentDimensions.size.width,
      currentDimensions.size.height,
      alignment,
      baseline: currentDimensions.baseline,
      baselineOffset: currentDimensions.baselineOffset,
    );
    if (hasStyle) {
      builder.pop();
    }
  }

  @override
  InlineSpan? getSpanForPositionVisitor(
      TextPosition position, Accumulator offset) {
    final TextAffinity affinity = position.affinity;
    final int targetOffset = position.offset;
    final int endOffset = offset.value + 1;
    if (offset.value == targetOffset && affinity == TextAffinity.downstream ||
        offset.value < targetOffset && targetOffset < endOffset ||
        endOffset == targetOffset && affinity == TextAffinity.upstream) {
      return this;
    }
    offset.increment(1);
    return null;
  }

  @override
  InlineSpan getSpanForPosition(TextPosition position) {
    return this;
  }
}

class WidgetSpanSize {
  Size? size;
}
