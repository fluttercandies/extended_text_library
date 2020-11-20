import 'dart:io';

import 'package:flutter/material.dart';
import '../../extended_text_library.dart';

abstract class ExtendedTextSelectionControls implements TextSelectionControls {
  factory ExtendedTextSelectionControls(BuildContext context) {
    switch(Theme.of(context).platform) {
      case TargetPlatform.iOS: return ExtendedCupertinoTextSelectionControls();
      default: return ExtendedMaterialTextSelectionControls();
    }
  }

  factory ExtendedTextSelectionControls.withActions(BuildContext context, {List<ToolbarAction> preActions, List<ToolbarAction> postActions}) {
    switch(Theme.of(context).platform) {
      case TargetPlatform.iOS: return ExtendedCupertinoTextSelectionControls.withActions(preActions: preActions, postActions: postActions);
      default: return ExtendedMaterialTextSelectionControls.withActions(preActions: preActions, postActions: postActions);
    }
  }
}
