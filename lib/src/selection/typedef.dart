import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/material.dart';

//   Default
//   bool _shouldShowSelectionHandles(SelectionChangedCause? cause) {
//   // When the text field is activated by something that doesn't trigger the
//   // selection overlay, we shouldn't show the handles either.
//   if (!_selectionGestureDetectorBuilder.shouldShowSelectionToolbar)
//     return false;

//   if (cause == SelectionChangedCause.keyboard) return false;

//   if (widget.readOnly && _effectiveController.selection.isCollapsed)
//     return false;

//   if (!_isEnabled) return false;

//   if (cause == SelectionChangedCause.longPress) return true;

//   if (_effectiveController.text.isNotEmpty) return true;

//   return false;
// }
typedef ShouldShowSelectionHandlesCallback = bool Function(
  SelectionChangedCause? cause,
  CommonTextSelectionGestureDetectorBuilder selectionGestureDetectorBuilder,
  TextEditingValue editingValue,
);

/// return GestureDetectorBuilder for TextSelection
typedef TextSelectionGestureDetectorBuilderCallback
    = CommonTextSelectionGestureDetectorBuilder Function({
  required ExtendedTextSelectionGestureDetectorBuilderDelegate delegate,
  required Function showToolbar,
  required Function hideToolbar,
  required Function? onTap,
  required BuildContext context,
  required Function? requestKeyboard,
});
