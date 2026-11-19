import 'package:cna/core/theme/app_tokens.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 离线态视图（DESIGN.md §8：离线提示 + 重试；不伪装成空态）。
class OfflineView extends StatelessWidget {
  /// 创建离线视图。
  const new({super.key, this.onRetry});

  /// 重试回调。
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '网络不可用',
              style: AppTypography.title.copyWith(
                color: context.tTheme.textColorPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '无法连接到 CNB 服务。检查网络连接后重试；恢复后数据会正常加载。',
              style: AppTypography.body.copyWith(
                color: context.tTheme.textColorSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              TButton(
                variant: TButtonVariant.fill,
                onPressed: onRetry,
                child: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
