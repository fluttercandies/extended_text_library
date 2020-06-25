## [2.0.0]

* Support OverFlowWidget [ExtendedText].
* Breaking change: remove overFlowTextSpan.

## [0.5.4]

* fix selection issue on ios about selectWordEdge

## [0.5.3]

* fix error about TargetPlatform.macOS

## [0.5.2]

* fix issue that TextPainter was not layout(ExtendedText)

## [0.5.1]

* set limitation of flutter sdk >=1.12.13

## [0.5.0]

* codes base on 1.12.13+hotfix.5
* breaking change:
  CupertinoExtendedTextSelectionControls => ExtendedCupertinoTextSelectionControls
  MaterialExtendedTextSelectionControls => ExtendedMaterialTextSelectionControls
* extract method for TextSelection

## [0.4.9]

* workaround about wrong selection position of WidgetSpan

## [0.4.8]

* fix issue that ImageSpan's padding can't be null.
* add behavior for ImageSpan

## [0.4.7]

* change kMinInteractiveSize to kExtendedMinInteractiveSize

## [0.4.6]

* fix null exception of effectiveOffset in getCaretOffset method

## [0.4.5]

* fix kMinInteractiveSize is missing in high version of flutter

## [0.4.4]

* add common selection library for extended_text and extended_text_field

## [0.4.3]

* set default value('\uFFFC') of actualText for ExtendedWidgetSpan
* add onTap call back for ImageSpan
* change return type to TextSpan for SpecialTextSpanBuilder's Build method

## [0.4.2]

* improve codes base on v1.7.8
* support WidgetSpan (ExtendedWidgetSpan)

## [0.4.1]

* add textSpanNestToArray and textSpanToActualText

## [0.3.5]

* move extended_text_utils from extended_text_field

## [0.3.1]

* remove caretIn parameter(SpecialTextSpan)
* deleteAll parameter has the same effect as caretIn parameter(SpecialTextSpan)

## [0.3.0]

* add caretIn parameter(whether caret can be move into special text for SpecialTextSpan(like a image span or @xxxx)) for SpecialTextSpan

## [0.2.6]

* add GestureRecognizer for image span

## [0.2.4]

* handle image loaded failed for image span

## [0.2.3]

* remove CachedNetworkImage

## [0.2.2]

* update deafult build method in SpecialTextSpanBuilder

## [0.2.1]

* change cacheImageFolderName from "extenedtext" to "cacheimage"

## [0.2.0]

* add BackgroundTextSpan, support to paint custom background

## [0.1.6]

* override compareTo method in SpecialTextSpan and ImageSpan to
  fix issue that image span or special text span was error rendering

## [0.1.5]

* fix start index is not right in SpecialTextSpanBuilder
* override == and hashCode for ImageSpan

## [0.1.3]

* override == and hashCode for SpecialTextSpan
* update build method in SpecialTextSpanBuilder

## [0.1.2]

* add deleteAll parameter for SpecialTextSpan

## [0.1.0]

* add following to support extended_text and extended_text_field
  cached_network_image.dart
  extended_text_utils.dart
  image_span.dart
  special_text_span_base.dart
  special_text_span_builder.dart
