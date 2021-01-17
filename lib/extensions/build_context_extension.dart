///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2020/3/16 16:05
///
import 'package:flutter/material.dart';

extension BuildContextExtension on BuildContext {
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  IconThemeData get iconTheme => theme.iconTheme;

  Color get themeColor => theme.accentColor;
}
