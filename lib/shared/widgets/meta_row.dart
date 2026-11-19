import 'package:cna/core/theme/app_tokens.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 元信息单元：可选图标 + 文本（DESIGN.md §3.2：label 层级，元信息）。
class MetaItem extends StatelessWidget {
  /// 创建元信息单元。
  const new({required this.label, super.key, this.icon});

  /// 可选图标（TDesign 图标库实名，如 `TIcons.star`；null 为纯文本）。
  final IconData? icon;

  /// 文本（计数等）。
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.label.copyWith(
      color: context.tTheme.textColorSecondary,
    );
    final children = <Widget>[
      if (icon != null) ...[
        Icon(icon, size: 14, color: context.tTheme.textColorSecondary),
        const SizedBox(width: AppSpacing.xs),
      ],
      Text(label, style: style),
    ];
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

/// 元信息行：作者 / 时间 / 计数等统一排版（DESIGN.md §6 点名组件）。
class MetaRow extends StatelessWidget {
  /// 创建元信息行。
  const new({required this.items, super.key, this.spacing = AppSpacing.sm});

  /// 元信息单元列表。
  final List<MetaItem> items;

  /// 单元间距。
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(SizedBox(width: spacing));
      }
      children.add(items[i]);
    }
    return Wrap(children: children);
  }
}
