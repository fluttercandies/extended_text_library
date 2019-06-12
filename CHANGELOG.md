## [0.3.8]

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
