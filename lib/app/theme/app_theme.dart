import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

abstract final class AppTheme {
  static final light = ShadThemeData(brightness: Brightness.light);

  static final dark = ShadThemeData(brightness: Brightness.dark);
}
