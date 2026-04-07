import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Точки для адаптивной вёрстки веба (desktop / tablet).
abstract final class WebLayout {
  /// Ширина: нижняя навигация + узкая колонка (как телефон).
  static const double narrowWebMaxBodyWidth = 520;

  /// От этой ширины — боковая [NavigationRail] вместо нижнего бара.
  static const double railBreakpoint = 900;

  /// «Раскрытый» rail с подписями.
  static const double railExtendedBreakpoint = 1200;

  /// Максимальная ширина контента внутри rail-режима.
  static const double desktopContentMaxWidth = 1280;

  static bool get isWeb => kIsWeb;

  static bool useSideNavigation(BuildContext context) {
    if (!kIsWeb) return false;
    return MediaQuery.sizeOf(context).width >= railBreakpoint;
  }

  static bool useExtendedRail(BuildContext context) {
    if (!kIsWeb) return false;
    return MediaQuery.sizeOf(context).width >= railExtendedBreakpoint;
  }

  /// Max width для «колонки телефона» на узком вебе.
  static double? narrowWebMaxWidth(BuildContext context) {
    if (!kIsWeb) return null;
    if (useSideNavigation(context)) return null;
    return narrowWebMaxBodyWidth;
  }
}
