import 'package:flutter/foundation.dart';

import '../../extended_text_library.dart';

class ActionData {
  ActionData({
    @required this.onPressed,
    @required this.label,
    this.shouldShow,
  });

  final ActionValidator shouldShow;
  final CallbackWithDelegate onPressed;
  final String label;
}