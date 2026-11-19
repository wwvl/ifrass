import 'package:cna/core/theme/app_colors.dart';
import 'package:cna/core/theme/app_tokens.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 语言标识：色点 + 语言名（DESIGN.md §3.1：语言色条取 `AppLanguageColors`）。
///
/// 语言未登记或缺失时使用兜底色与「未知语言」文案，不裸取 hex。
class LanguageBar extends StatelessWidget {
  /// 创建语言标识。
  const new({super.key, this.language});

  /// 主语言（Repo 实体同名字段；null → 兜底）。
  final String? language;

  @override
  Widget build(BuildContext context) {
    final name = language ?? '未知语言';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppLanguageColors.of(name),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          name,
          style: AppTypography.label.copyWith(
            color: context.tTheme.textColorSecondary,
          ),
        ),
      ],
    );
  }
}
