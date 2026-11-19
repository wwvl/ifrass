import 'package:cna/core/router/routes.dart';
import 'package:cna/core/theme/app_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 会话过期页（401 单一入口复位后的信息页，DESIGN.md §8 差异化文案）。
class SessionExpiredPage extends StatelessWidget {
  /// 创建会话过期页。
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '会话已过期',
              style: AppTypography.title.copyWith(
                color: context.tTheme.textColorPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '登录状态已失效，请重新登录。',
              style: AppTypography.body.copyWith(
                color: context.tTheme.textColorSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TButton(
              variant: TButtonVariant.fill,
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('重新登录'),
            ),
          ],
        ),
      ),
    );
  }
}
