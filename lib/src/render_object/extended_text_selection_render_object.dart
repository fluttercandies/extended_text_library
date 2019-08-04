import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

///
///  create by zmtzawqlp on 2019/8/1
///

abstract class ExtendedTextSelectionRenderObject {
  ValueListenable<bool> get selectionStartInViewport;
  ValueListenable<bool> get selectionEndInViewport;
  List<TextSelectionPoint> getEndpointsForSelection(TextSelection selection);
  Offset getlocalToGlobal(Offset point, {RenderObject ancestor});
  Size getSize();
  double get preferredLineHeight;
  TextPosition getPositionForPoint(Offset globalPosition);
  bool get handleSpecialText;
  InlineSpan get text;
  bool get isAttached;
}
