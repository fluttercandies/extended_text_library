import 'package:flutter/widgets.dart';

import 'extended_text_utils.dart';

extension StringE on String {
  String joinChar([String char = zeroWidthSpace]) =>
      Characters(this).join(char);
}
