import 'package:cna/core/router/routes.dart';
import 'package:cna/core/theme/app_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 404 页（AGENTS.md §7：必须提供）：由 GoRouter errorBuilder 呈现。
class NotFoundPage extends StatelessWidget {
  /// 创建 404 页。
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '页面不存在',
              style: AppTypography.title.copyWith(
                color: context.tTheme.textColorPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '链接可能已失效，回首页继续。',
              style: AppTypography.body.copyWith(
                color: context.tTheme.textColorSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TButton(
              variant: TButtonVariant.fill,
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('回首页'),
            ),
          ],
        ),
      ),
    );
  }
}
