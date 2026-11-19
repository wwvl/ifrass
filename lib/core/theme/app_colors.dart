import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 业务语义色补充表（DESIGN.md §3.1：仅补充 TDesign 未覆盖部分）。
///
/// 本文件是项目唯一允许出现裸 hex 常量的地方，只放仓库语言色条；
/// Widget 内禁止直接写 `Color(0xFF…)`。状态色（success/warning/error）
/// 一律走 `context.tTheme`，不在此重复定义。
/// 注意：TDesign 1.1.0 无独立 infoColor，信息类语义由 brandColor 担当。
abstract final class AppLanguageColors {
  /// 未知语言或映射未命中的兜底色。
  static const Color unknown = Color(0xFF8A9099);

  /// 语言 → 色条颜色映射（`LanguageBar` / `RepoCard` 消费）。
  ///
  /// 取社区通用的语言配色约定（GitHub Linguist 色表），
  /// 与 cnb.cool Web 端仓库语言标识保持同源观感。
  static const Map<String, Color> _colors = {
    'dart': Color(0xFF00B4AB),
    'typescript': Color(0xFF3178C6),
    'javascript': Color(0xFFF1E05A),
    'python': Color(0xFF3572A5),
    'go': Color(0xFF00ADD8),
    'rust': Color(0xFFDEA584),
    'java': Color(0xFFB07219),
    'kotlin': Color(0xFFA97BFF),
    'swift': Color(0xFFF05138),
    'objective-c': Color(0xFF438EFF),
    'c': Color(0xFF555555),
    'c++': Color(0xFFF34B7D),
    'c#': Color(0xFF178600),
    'ruby': Color(0xFF701516),
    'php': Color(0xFF4F5D95),
    'shell': Color(0xFF89E051),
    'html': Color(0xFFE34C26),
    'css': Color(0xFF563D7C),
    'vue': Color(0xFF41B883),
    'scala': Color(0xFFC22D40),
    'lua': Color(0xFF000080),
    'haskell': Color(0xFF5E5086),
    'elixir': Color(0xFF6E4A7E),
    'zig': Color(0xFFEC9153),
  };

  /// 按语言名取色条颜色；大小写不敏感，未命中返回 [unknown]。
  static Color of(String language) {
    final key = language.trim().toLowerCase();
    return _colors[key] ?? unknown;
  }

  /// 已登记的语言清单（供测试断言，不参与渲染分支）。
  static Iterable<String> get languages => _colors.keys;
}
