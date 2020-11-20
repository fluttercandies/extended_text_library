import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ToolbarAction {
  ToolbarAction({
    @required this.onPressed,
    @required this.label,
    this.shouldShow,
  });

  final ActionValidator shouldShow;
  final CallbackWithDelegate onPressed;
  final String label;
}

typedef CallbackWithDelegate = void Function(TextSelectionDelegate delegate);

typedef ActionValidator = bool Function(TextSelectionDelegate delegate);
