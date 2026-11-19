import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 间距 Token：8pt 网格（DESIGN.md §3.3，数值为硬约束）。
///
/// 所有 `padding` / `margin` / `gap` / `SizedBox` 一律取本表，
/// 禁止 `EdgeInsets.all(13)`、`SizedBox(height: 10)` 等任意值。
abstract final class AppSpacing {
  /// 极小间距（半格）：图标与文本之间等紧凑场景。
  static const double xs = 4;

  /// 小间距。
  static const double sm = 8;

  /// 标准间距。
  static const double md = 16;

  /// 大间距。
  static const double lg = 24;

  /// 超大间距。
  static const double xl = 32;

  /// 页面级留白。
  static const double xxl = 48;
}

/// 圆角 Token（DESIGN.md §3.4）。
///
/// 数值对齐 TDesign 1.1.0 内置圆角刻度（`TRadius`）：
/// radiusDefault=6 / radiusLarge=9 / radiusExtraLarge=12 / radiusRound=999。
abstract final class AppRadius {
  /// 小圆角：标签、紧凑组件。
  static const double sm = 6;

  /// 中圆角：按钮、输入框。
  static const double md = 9;

  /// 大圆角：卡片、浮层。
  static const double lg = 12;

  /// 胶囊：徽标、状态点、全圆角元素。
  static const double pill = 999;
}

/// 动效时长 Token（DESIGN.md §3.4）。
abstract final class AppDurations {
  /// 快速反馈：按压、开关。
  static const Duration fast = Duration(milliseconds: 150);

  /// 常规过渡：页面内展开、淡入。
  static const Duration normal = Duration(milliseconds: 250);

  /// 慢速：整页转场、大面板。
  static const Duration slow = Duration(milliseconds: 400);
}

/// 动效曲线 Token（DESIGN.md §3.4：曲线统一，不散落各页面）。
abstract final class AppCurves {
  /// 常规过渡曲线。
  static const Curve standard = Curves.easeOutCubic;

  /// 强调过渡曲线（大位移、整页转场）。
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
}

/// 字排角色 Token（DESIGN.md §3.2：行高、字重、字族只在此定义一次）。
///
/// 颜色不属于本表：三级文字层次由 `context.tTheme.text*` 提供
/// （textColorPrimary / textColorSecondary / textColorPlaceholder）。
/// 用法：`AppTypography.body.copyWith(color: context.tTheme.textColorPrimary)`。
abstract final class AppTypography {
  /// 页面标题、仓库名。
  static const TextStyle headline = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// 区块标题、Issue / PR 标题。
  static const TextStyle title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// 正文、描述、评论。
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// 元信息：作者、时间、star 数、标签。
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  /// 代码 / commit hash / 日志：等宽，字族只在此定义一次。
  static const TextStyle code = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontFamily: 'monospace',
    fontFamilyFallback: ['Menlo', 'Roboto Mono', 'Courier New'],
  );
}
