import 'package:cna/core/router/routes.dart';
import 'package:cna/core/theme/app_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 离线提示页（DESIGN.md §8：不伪装成空态；重试交回守卫裁决去向）。
class OfflinePage extends StatelessWidget {
  /// 创建离线页。
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '网络不可用',
              style: AppTypography.title.copyWith(
                color: context.tTheme.textColorPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '检查网络连接后重试；恢复后可继续操作。',
              style: AppTypography.body.copyWith(
                color: context.tTheme.textColorSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TButton(
              variant: TButtonVariant.fill,
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
