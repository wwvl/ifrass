import 'package:cna/core/theme/app_tokens.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 空态视图（DESIGN.md §8：「为什么空 + 下一步做什么」，不放纯插画）。
class EmptyView extends StatelessWidget {
  /// 创建空态视图。
  const new({
    super.key,
    this.title = '这里还没有内容',
    this.description = '信息加载后会出现在这里。',
    this.actionLabel,
    this.onAction,
  });

  /// 主文案（为什么空）。
  final String title;

  /// 说明（下一步做什么）。
  final String description;

  /// 引导操作文案（null 不显示按钮）。
  final String? actionLabel;

  /// 引导操作回调。
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTypography.title.copyWith(
                color: context.tTheme.textColorPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: AppTypography.body.copyWith(
                color: context.tTheme.textColorSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              TButton(
                variant: TButtonVariant.outline,
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
