/// Material 主题桥（DESIGN.md §2.1：main.dart 只从这里取主题）。
///
/// `TThemeBuilder`（TDesign 1.1.0 官方快速开始用法）把 Token 映射为完整
/// `ThemeData`，并把 `TThemeData` 作为 ThemeExtension 装入主题——
/// 因此 `context.tTheme` 会随浅/深亮度自动取到对应那套 Token。
/// TD 内置视觉不继承 Material 主题；改样式先改 Token，不反向雕 ThemeData。
library;

import 'package:cna/core/theme/tdesign_theme.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 构建浅色 App 主题。
ThemeData buildLightAppTheme() => TThemeBuilder.light(AppThemeTokens.root);

/// 构建深色 App 主题。
ThemeData buildDarkAppTheme() => TThemeBuilder.dark(AppThemeTokens.root);
