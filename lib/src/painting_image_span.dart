// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'special_inline_span_base.dart';
// import 'special_text_span.dart';

// /// workaround for WidgetSpan
// /// https://github.com/flutter/flutter/issues/47491
// ///
// /// get idea from https://github.com/bytedance/RealRichText about Inline-Image-In-Text
// /// update by zmtzawqlp@live.com

// ///[imageSpanTransparentPlaceholder] width is zero,
// ///so that we can define letterSpacing as Image Span width
// const String imageSpanTransparentPlaceholder = '\u200B';

// ///transparentPlaceholder is transparent text
// //fontsize id define image height
// //size = 30.0/26.0 * fontSize
// ///final double size = 30.0;
// ///fontSize 26 and text height =30.0
// //final double fontSize = 26.0;

// double dpToFontSize(double dp) {
//   return dp / 30.0 * 26.0;
// }

// class _PaintingImageSpan extends SpecialTextSpan {
//   ///image provider
//   final ImageProvider image;

//   final EdgeInsets margin;

//   final double imageWidth;

//   final double imageHeight;

//   ///width include margin
//   final double width;

//   ///height include margin
//   final double height;

//   ///image fit
//   final BoxFit fit;

//   ///resolver
//   final ImageSpanResolver imageSpanResolver;

//   ///when failed to load image, whether clear memory cache
//   ///if ture, image will reload in next time.
//   final bool clearMemoryCacheIfFailed;

//   _PaintingImageSpan(
//     this.image, {
//     @required this.imageWidth,
//     @required this.imageHeight,
//     this.margin,
//     this.fit: BoxFit.scaleDown,
//     String actualText: imageSpanTransparentPlaceholder,
//     int start: 0,
//     this.clearMemoryCacheIfFailed: true,
//     GestureRecognizer recognizer,
//   })  : assert(image != null),
//         assert(imageWidth != null),
//         assert(imageHeight != null),
//         assert(fit != null),
//         imageSpanResolver = ImageSpanResolver(clearMemoryCacheIfFailed),
//         width = imageWidth + (margin == null ? 0 : margin.horizontal),
//         height = imageHeight + (margin == null ? 0 : margin.vertical),
//         super(
//           text: imageSpanTransparentPlaceholder,
//           style: TextStyle(
//             color: Colors.transparent,
//             height: 1,
//             letterSpacing:
//                 imageWidth + (margin == null ? 0 : margin.horizontal),
//             fontSize: dpToFontSize(
//                 imageHeight + (margin == null ? 0 : margin.vertical)),
//           ),
//           actualText: actualText,
//           start: start,
//           deleteAll: true,
//           recognizer: recognizer,
//         );

//   void createImageConfiguration(BuildContext context) {
//     imageSpanResolver.createimageConfiguration(
//         context, imageWidth, imageHeight);
//   }

//   void resolveImage({ImageListener listener}) {
//     imageSpanResolver.resolveImage(listener: listener, image: image);
//   }

//   void dispose() {
//     imageSpanResolver.dispose();
//   }

//   bool paint(Canvas canvas, Offset offset) {
//     Offset imageOffset = offset;
//     if (margin != null) {
//       imageOffset = imageOffset + Offset(margin.left, margin.top);
//     }
//     final Rect imageRect = imageOffset & Size(imageWidth, imageHeight);

//     if (imageSpanResolver.imageInfo?.image == null) return false;

//     paintImage(
//         canvas: canvas,
//         rect: imageRect,
//         image: imageSpanResolver.imageInfo?.image,
//         fit: fit,
//         alignment: Alignment.center);
//     return true;
//   }

//   @override
//   bool operator ==(dynamic other) {
//     if (identical(this, other)) {
//       return true;
//     }
//     if (other.runtimeType != runtimeType) {
//       return false;
//     }

//     return other is _PaintingImageSpan &&
//         other.text == text &&
//         other.style == style &&
//         other.actualText == actualText &&
//         other.start == start &&
//         other.image == image &&
//         other.imageHeight == imageHeight &&
//         other.imageWidth == imageWidth &&
//         other.margin == margin &&
//         other.fit == fit &&
//         other.clearMemoryCacheIfFailed == clearMemoryCacheIfFailed;
//   }

//   @override
//   int get hashCode => hashValues(style, text, actualText, start, deleteAll,
//       image, imageWidth, imageHeight, margin, fit, clearMemoryCacheIfFailed);

//   @override
//   RenderComparison compareTo(InlineSpan other) {
//     if (other is _PaintingImageSpan) {
//       if (other.imageHeight != imageHeight ||
//           other.imageWidth != imageWidth ||
//           other.margin != margin ||
//           other.fit != fit) {
//         return RenderComparison.layout;
//       }

//       if (other.image != image ||
//           other.clearMemoryCacheIfFailed != clearMemoryCacheIfFailed) {
//         return RenderComparison.paint;
//       }
//     }

//     var comparison = super.compareTo(other);
//     if (comparison == RenderComparison.identical) {
//       comparison = baseCompareTo(other as SpecialInlineSpanBase);
//     }
//     return comparison;
//   }
// }

// class ImageSpanResolver {
//   ImageListener _listener;
//   ImageStream _imageStream;
//   ImageInfo _imageInfo;
//   ImageInfo get imageInfo => _imageInfo;
//   bool _failed = false;
//   bool get loadFailed => _failed;
//   ImageProvider _image;
//   bool _isListeningToStream = false;
//   ImageConfiguration _imageConfiguration;
//   final bool clearMemoryCacheIfFailed;
//   ImageSpanResolver(this.clearMemoryCacheIfFailed);
// //  void didUpdateWidget(Image oldWidget) {
// //    super.didUpdateWidget(oldWidget);
// //    if (widget.image != oldWidget.image)
// //      _resolveImage();
// //  }

//   void createimageConfiguration(
//       BuildContext context, double imageWidth, double imageHeight) {
//     _imageConfiguration = createLocalImageConfiguration(context,
//         size: (imageWidth != null && imageHeight != null)
//             ? Size(imageWidth, imageHeight)
//             : null);
//   }

//   void resolveImage({ImageListener listener, ImageProvider image}) {
//     assert(_imageConfiguration != null);
//     _image = image;
//     _failed = false;
//     if (listener != null) _listener = listener;
//     final ImageStream newStream = image.resolve(_imageConfiguration);
//     assert(newStream != null);
//     _updateSourceStream(newStream);
//   }

//   void _handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
//     //setState(() {
//     _imageInfo = imageInfo;
//     _listener?.call(imageInfo, synchronousCall);
//     //});
//   }

//   // Update _imageStream to newStream, and moves the stream listener
//   // registration from the old stream to the new stream (if a listener was
//   // registered).
//   void _updateSourceStream(ImageStream newStream) {
//     if (_imageStream?.key == newStream?.key) return;

//     _stopListeningToStream();
//     //if (_isListeningToStream) _imageStream.removeListener(_handleImageChanged);

//     _imageStream = newStream;
//     //if (_isListeningToStream) _imageStream.addListener(_handleImageChanged);
//     _listenToStream();
//   }

//   void _listenToStream() {
//     if (_isListeningToStream) return;
//     _imageStream?.addListener(
//         ImageStreamListener(_handleImageChanged, onError: _loadFailed));
//     _isListeningToStream = true;
//   }

//   void _stopListeningToStream() {
//     if (!_isListeningToStream) return;
//     _imageStream?.removeListener(
//         ImageStreamListener(_handleImageChanged, onError: _loadFailed));
//     _isListeningToStream = false;
//   }

//   void dispose() {
//     //assert(_imageStream != null);
//     _stopListeningToStream();
//     //super.dispose();
//   }

//   void _loadFailed(dynamic exception, StackTrace stackTrace) {
//     if (clearMemoryCacheIfFailed) {
//       _image?.evict();
//     }
//     _failed = true;

//     ///show transparentImage
//     ui.instantiateImageCodec(kTransparentImage).then((ui.Codec codec) {
//       codec.getNextFrame().then((vlaue) {
//         _imageInfo = ImageInfo(image: vlaue.image, scale: 1.0);
//       });
//       _listener?.call(_imageInfo, false);
//     });
//   }
// }

// final Uint8List kTransparentImage = new Uint8List.fromList(<int>[
//   0x89,
//   0x50,
//   0x4E,
//   0x47,
//   0x0D,
//   0x0A,
//   0x1A,
//   0x0A,
//   0x00,
//   0x00,
//   0x00,
//   0x0D,
//   0x49,
//   0x48,
//   0x44,
//   0x52,
//   0x00,
//   0x00,
//   0x00,
//   0x01,
//   0x00,
//   0x00,
//   0x00,
//   0x01,
//   0x08,
//   0x06,
//   0x00,
//   0x00,
//   0x00,
//   0x1F,
//   0x15,
//   0xC4,
//   0x89,
//   0x00,
//   0x00,
//   0x00,
//   0x0A,
//   0x49,
//   0x44,
//   0x41,
//   0x54,
//   0x78,
//   0x9C,
//   0x63,
//   0x00,
//   0x01,
//   0x00,
//   0x00,
//   0x05,
//   0x00,
//   0x01,
//   0x0D,
//   0x0A,
//   0x2D,
//   0xB4,
//   0x00,
//   0x00,
//   0x00,
//   0x00,
//   0x49,
//   0x45,
//   0x4E,
//   0x44,
//   0xAE,
// ]);
