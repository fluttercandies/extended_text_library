import 'package:flutter/material.dart';
//import 'package:transparent_image/transparent_image.dart';
//import 'dart:ui' as ui show instantiateImageCodec, Codec;
import 'dart:ui' as ui show PlaceholderAlignment;

import 'extended_widget_span.dart';

class ImageSpan extends ExtendedWidgetSpan {
  final double width;
  final double height;
  ImageSpan(
    ImageProvider image, {
    Key key,
    @required double imageWidth,
    @required double imageHeight,
    EdgeInsets margin,
    int start: 0,
    ui.PlaceholderAlignment alignment = ui.PlaceholderAlignment.bottom,
    String actualText,
    TextBaseline baseline,
    TextStyle style,
    BoxFit fit: BoxFit.scaleDown,
    ImageLoadingBuilder loadingBuilder,
    ImageFrameBuilder frameBuilder,
    String semanticLabel,
    bool excludeFromSemantics = false,
    Color color,
    BlendMode colorBlendMode,
    AlignmentGeometry imageAlignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    FilterQuality filterQuality = FilterQuality.low,
  })  : assert(image != null),
        assert(imageWidth != null),
        assert(imageHeight != null),
        assert(fit != null),
        width = imageWidth + (margin == null ? 0 : margin.horizontal),
        height = imageHeight + (margin == null ? 0 : margin.vertical),
        super(
          child: Padding(
            padding: margin,
            child: Image(
              key: key,
              image: image,
              width: imageWidth,
              height: imageHeight,
              fit: fit,
              loadingBuilder: loadingBuilder,
              frameBuilder: frameBuilder,
              semanticLabel: semanticLabel,
              excludeFromSemantics: excludeFromSemantics,
              color: color,
              colorBlendMode: colorBlendMode,
              alignment: imageAlignment,
              repeat: repeat,
              centerSlice: centerSlice,
              matchTextDirection: matchTextDirection,
              gaplessPlayback: gaplessPlayback,
              filterQuality: filterQuality,
            ),
          ),
          style: style,
          baseline: baseline,
          alignment: alignment,
          start: start,
          deleteAll: true,
          actualText: actualText,
        );

//  void createImageConfiguration(BuildContext context) {
//    imageSpanResolver.createimageConfiguration(
//        context, imageWidth, imageHeight);
//  }
//
//  void resolveImage({ImageListener listener}) {
//    imageSpanResolver.resolveImage(listener: listener, image: image);
//  }
//
//  void dispose() {
//    imageSpanResolver.dispose();
//  }
//
//  bool paint(Canvas canvas, Offset offset) {
//    Offset imageOffset = offset;
//    if (margin != null) {
//      imageOffset = imageOffset + Offset(margin.left, margin.top);
//    }
//    final Rect imageRect = imageOffset & Size(imageWidth, imageHeight);
//
//    bool handle = beforePaintImage?.call(canvas, imageRect, this) ?? false;
//    if (handle) return true;
//
//    if (imageSpanResolver.imageInfo?.image == null) return false;
//
//    paintImage(
//        canvas: canvas,
//        rect: imageRect,
//        image: imageSpanResolver.imageInfo?.image,
//        fit: fit,
//        alignment: Alignment.center);
//
//    afterPaintImage?.call(canvas, imageRect, this);
//    return true;
//  }
//
//  @override
//  bool operator ==(dynamic other) {
//    if (identical(this, other)) return true;
//    if (other.runtimeType != runtimeType) return false;
//    final ImageSpan typedOther = other;
//    return typedOther.text == text &&
//        typedOther.style == style &&
//        typedOther.actualText == actualText &&
//        typedOther.start == start &&
//        typedOther.image == image &&
//        typedOther.imageHeight == imageHeight &&
//        typedOther.imageWidth == imageWidth &&
//        typedOther.margin == margin &&
//        typedOther.beforePaintImage == beforePaintImage &&
//        typedOther.afterPaintImage == afterPaintImage &&
//        typedOther.fit == fit &&
//        other.clearMemoryCacheIfFailed == clearMemoryCacheIfFailed;
//  }
//
//  @override
//  int get hashCode => hashValues(
//      style,
//      text,
//      actualText,
//      start,
//      deleteAll,
//      image,
//      imageWidth,
//      imageHeight,
//      margin,
//      beforePaintImage,
//      afterPaintImage,
//      fit,
//      clearMemoryCacheIfFailed);
//
//  @override
//  RenderComparison compareTo(InlineSpan other) {
//    if (other is ImageSpan) {
//      if (other.imageHeight != imageHeight ||
//          other.imageWidth != imageWidth ||
//          other.margin != margin ||
//          other.fit != fit) {
//        return RenderComparison.layout;
//      }
//
//      if (other.image != image ||
//          other.beforePaintImage != beforePaintImage ||
//          other.afterPaintImage != afterPaintImage ||
//          other.clearMemoryCacheIfFailed != clearMemoryCacheIfFailed) {
//        return RenderComparison.paint;
//      }
//    }
//
//    // TODO: implement compareTo
//    return super.compareTo(other);
//  }
}

//class ImageSpanResolver {
//  ImageListener _listener;
//  ImageStream _imageStream;
//  ImageInfo _imageInfo;
//  ImageInfo get imageInfo => _imageInfo;
//  bool _loadFailed = false;
//  bool get loadFailed => _loadFailed;
//  ImageProvider _image;
//  bool _isListeningToStream = false;
//  ImageConfiguration _imageConfiguration;
//  final bool clearMemoryCacheIfFailed;
//  ImageSpanResolver(this.clearMemoryCacheIfFailed);
////  void didUpdateWidget(Image oldWidget) {
////    super.didUpdateWidget(oldWidget);
////    if (widget.image != oldWidget.image)
////      _resolveImage();
////  }
//
//  void createimageConfiguration(
//      BuildContext context, double imageWidth, double imageHeight) {
//    _imageConfiguration = createLocalImageConfiguration(context,
//        size: (imageWidth != null && imageHeight != null)
//            ? Size(imageWidth, imageHeight)
//            : null);
//  }
//
//  void resolveImage({ImageListener listener, ImageProvider image}) {
//    assert(_imageConfiguration != null);
//    _image = image;
//    _loadFailed = false;
//    if (listener != null) _listener = listener;
//    final ImageStream newStream = image.resolve(_imageConfiguration);
//    assert(newStream != null);
//    _updateSourceStream(newStream);
//  }
//
//  void _handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
//    //setState(() {
//    _imageInfo = imageInfo;
//    _listener?.call(imageInfo, synchronousCall);
//    //});
//  }
//
//  // Update _imageStream to newStream, and moves the stream listener
//  // registration from the old stream to the new stream (if a listener was
//  // registered).
//  void _updateSourceStream(ImageStream newStream) {
//    if (_imageStream?.key == newStream?.key) return;
//
//    _stopListeningToStream();
//    //if (_isListeningToStream) _imageStream.removeListener(_handleImageChanged);
//
//    _imageStream = newStream;
//    //if (_isListeningToStream) _imageStream.addListener(_handleImageChanged);
//    _listenToStream();
//  }
//
//  void _listenToStream() {
//    if (_isListeningToStream) return;
//    _imageStream?.addListener(
//        ImageStreamListener(_handleImageChanged, onError: _failed));
//    _isListeningToStream = true;
//  }
//
//  void _stopListeningToStream() {
//    if (!_isListeningToStream) return;
//    _imageStream?.removeListener(
//        ImageStreamListener(_handleImageChanged, onError: _failed));
//    _isListeningToStream = false;
//  }
//
//  void dispose() {
//    //assert(_imageStream != null);
//    _stopListeningToStream();
//    //super.dispose();
//  }
//
//  void _failed(exception, StackTrace stackTrace) {
//    if (clearMemoryCacheIfFailed) {
//      _image?.evict();
//    }
//    _loadFailed = true;
//
//    ///show transparentImage
//    ui.instantiateImageCodec(kTransparentImage).then((ui.Codec codec) {
//      codec.getNextFrame().then((vlaue) {
//        _imageInfo = ImageInfo(image: vlaue.image, scale: 1.0);
//      });
//      _listener?.call(_imageInfo, false);
//    });
//  }
//}
//
/////[rect] rect is not margin
/////if you have handle placeholder or paint image(clip) you can return true,  it will not paint original image,
/////you will have the channce to draw your placeholder before paint image
//typedef BeforePaintTextImage = bool Function(
//    Canvas canvas, Rect rect, ImageSpan imageSpan);
//
/////[rect] rect is not include margin
/////you can paint border,shadow etc at this moment
//typedef AfterPaintTextImage = void Function(
//    Canvas canvas, Rect rect, ImageSpan imageSpan);
