import 'dart:ui' as ui show PlaceholderAlignment, ParagraphBuilder;

import 'package:flutter/widgets.dart';

import 'special_inline_span_base.dart';

///
///  create by zmtzawqlp on 2019/7/10
///

///support selection for widget Span
class ExtendedWidgetSpan extends WidgetSpan with SpecialInlineSpanBase {
  ExtendedWidgetSpan({
    @required Widget child,
    String actualText= '\uFFFC',
    int start= 0,
    this.deleteAll= true,
    ui.PlaceholderAlignment alignment = ui.PlaceholderAlignment.bottom,
    TextBaseline baseline,
  })  : assert(start != null),
        assert(deleteAll != null),
        actualText = actualText ?? '\uFFFC',
        textRange = TextRange(
            start: start, end: start + (actualText ?? '\uFFFC').length),
        widgetSpanSize = WidgetSpanSize()..size = Size.zero,
        super(child: child, alignment: alignment, baseline: baseline);
  @override
  final String actualText;

  @override
  final bool deleteAll;

  @override
  final TextRange textRange;

  /// store size to calculate selection
  final WidgetSpanSize widgetSpanSize;

  Size get size => widgetSpanSize.size;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    if (super != other) {
      return false;
    }

    if (widgetSpanSize.size != other.widgetSpanSize.size) {
      return false;
    }
    return other is SpecialInlineSpanBase && equal(other);
  }

  @override
  int get hashCode =>
      hashValues(super.hashCode, baseHashCode, widgetSpanSize.size);

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

  @override
  void build(ui.ParagraphBuilder builder,
      {double textScaleFactor = 1.0,
      @required List<PlaceholderDimensions> dimensions}) {
    assert(debugAssertIsValid());
    assert(dimensions != null);
    final bool hasStyle = style != null;
    if (hasStyle) {
      builder.pushStyle(style.getTextStyle(textScaleFactor: textScaleFactor));
    }
    assert(builder.placeholderCount < dimensions.length);
    final PlaceholderDimensions currentDimensions =
        dimensions[builder.placeholderCount];
    widgetSpanSize.size = currentDimensions.size;
    builder.addPlaceholder(
      currentDimensions.size.width,
      currentDimensions.size.height,
      alignment,
      scale: textScaleFactor,
      baseline: currentDimensions.baseline,
      baselineOffset: currentDimensions.baselineOffset,
    );
    if (hasStyle) {
      builder.pop();
    }
  }

  @override
  InlineSpan getSpanForPositionVisitor(
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
  Size size;
}
