## 11.1.0

* Migrate to Flutter 3.13.0

## 11.0.2

* Fix issue that wrong cursor position on macos. (https://github.com/fluttercandies/extended_text_field/issues/210)

## 11.0.1

* Fix issue that empty text miss TextStyle. (Fix #41,#42,#43)

## 11.0.0

* Migrate to Flutter 3.10.0
* Refactoring codes and sync codes from 3.10.0

## 10.0.0

* fix issue on ios after flutter version 3.7.0. #191 #198

## 9.1.1

* Add RegExpSpecialTextSpanBuilder to build SpecialTextSpan with RegExp

## 9.1.0

* Migrate to 3.0.0
* Support Scribble Handwriting for iPads

## 9.0.0

* Migrate to 2.10.0
* Add shouldShowSelectionHandles and textSelectionGestureDetectorBuilder call back to define the behavior of handles and toolbar.
* Shortcut support for web and desktop.

## 8.0.2

* Fix  hittest is not right on ExtendedTextField

## 8.0.1

* Fix selectionWidthStyle and selectionHeightStyle are not working.

## 8.0.0

* Support to use keyboard move cursor for SpecialInlineSpan.
* Fix issue that backspace delete two chars.
  
## 7.0.0

* Add [SpecialTextSpan.mouseCursor], [SpecialTextSpan.onEnter] and [SpecialTextSpan.onExit].

## 6.0.0

* Add [TextOverflowWidget.position] to support show overflow at start, middle or end.
* Add [ExtendedText.joinZeroWidthSpace] to make line breaking and overflow style better.
* Breaking change: [SpecialText.getContent] is not include endFlag now.(please check if you call getContent and your endflag length is more than 1)


## 5.0.2

* Fix throw exception when selectWordAtOffset

## 5.0.1

* Fix error when extends SpecialTextSpanBuilder. #30

# 5.0.0

* Support null-safety

## 4.0.3

* Support keyboard copy on web/desktop for both text and text field
* Fix wrong position of caret

## 4.0.2

* Change handleSpecialText to hasSpecialInlineSpanBase
* Add hasPlaceholderSpan

## 4.0.1

* Fix valid value range #23

## 4.0.0

* Merge from Flutter v1.20

## 3.0.0

* Breaking change: fix typos OverflowWidget.

## 2.0.0

* Support OverFlowWidget ExtendedText.
* Breaking change: remove overFlowTextSpan.

## 1.0.0

* Merge code from 1.17.0
* Fix analysis_options

## 0.5.4

* Fix selection issue on ios about selectWordEdge

## 0.5.3

* Fix error about TargetPlatform.macOS

## 0.5.2

* Fix issue that TextPainter was not layout(ExtendedText)

## 0.5.1

* Set limitation of flutter sdk >=1.12.13

## 0.5.0

* Codes base on 1.12.13+hotfix.5
* Breaking change:
  CupertinoExtendedTextSelectionControls => ExtendedCupertinoTextSelectionControls
  MaterialExtendedTextSelectionControls => ExtendedMaterialTextSelectionControls
* Extract method for TextSelection

## 0.4.9

* Workaround about wrong selection position of WidgetSpan

## 0.4.8

* Fix issue that ImageSpan's padding can't be null.
* Add behavior for ImageSpan

## 0.4.7

* Change kMinInteractiveSize to kExtendedMinInteractiveSize

## 0.4.6

* Fix null exception of effectiveOffset in getCaretOffset method

## 0.4.5

* Fix kMinInteractiveSize is missing in high version of flutter

## 0.4.4

* Add common selection library for extended_text and extended_text_field

## 0.4.3

* Set default value('\uFFFC') of actualText for ExtendedWidgetSpan
* Add onTap call back for ImageSpan
* Change return type to TextSpan for SpecialTextSpanBuilder's Build method

## 0.4.2

* Improve codes base on v1.7.8
* Support WidgetSpan (ExtendedWidgetSpan)

## 0.4.1

* Add textSpanNestToArray and textSpanToActualText

## 0.3.5

* Move extended_text_utils from extended_text_field

## 0.3.1

* Remove caretIn parameter(SpecialTextSpan)
* DeleteAll parameter has the same effect as caretIn parameter(SpecialTextSpan)

## 0.3.0

* Add caretIn parameter(whether caret can be move into special text for SpecialTextSpan(like a image span or @xxxx)) for SpecialTextSpan

## 0.2.6

* Add GestureRecognizer for image span

## 0.2.4

* Handle image loaded failed for image span

## 0.2.3

* Remove CachedNetworkImage

## 0.2.2

* Update deafult build method in SpecialTextSpanBuilder

## 0.2.1

* Change cacheImageFolderName from "extenedtext" to "cacheimage"

## 0.2.0

* Add BackgroundTextSpan, support to paint custom background

## 0.1.6

* Override compareTo method in SpecialTextSpan and ImageSpan to
  fix issue that image span or special text span was error rendering

## 0.1.5

* Fix start index is not right in SpecialTextSpanBuilder
* Override == and hashCode for ImageSpan

## 0.1.3

* Override == and hashCode for SpecialTextSpan
* Update build method in SpecialTextSpanBuilder

## 0.1.2

* Add deleteAll parameter for SpecialTextSpan

## 0.1.0

* Add following to support extended_text and extended_text_field
  cached_network_image.dart
  extended_text_utils.dart
  image_span.dart
  special_text_span_base.dart
  special_text_span_builder.dart
