import 'package:flutter/material.dart';

class ThemeUtils {
  // 默认主题色
  static const Color defaultColor = const Color(0xFFE5322D);

  // 可选的主题色
  static const List<Color> supportColors = [
    defaultColor,
    Colors.purple,
    Colors.orange,
    Colors.deepPurpleAccent,
    Colors.pinkAccent,
    Colors.blue,
    Colors.amber,
    Colors.green,
    Colors.indigo,
    Colors.cyan,
    Colors.teal,
  ];

  // 当前的内容色
  static Color currentColorTheme = defaultColor;
  // 当前的主题色
  static Color currentPrimaryColor = Colors.white;

  // 当前是否夜间模式
  static bool currentIsDarkState = false;
  // 当前主题日夜模式
  static Brightness currentBrightness = Brightness.dark;
  // 当前卡片颜色
  static Color currentCardColor = const Color(0xffffffff);

}
