import 'package:cna/core/error/failure.dart';
import 'package:cna/core/theme/app_tokens.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 错误态视图（DESIGN.md §8：可读错误 + 重试；403/404 差异化文案）。
///
/// 403 不显示崩溃或空白页：提示检查访问令牌授权范围。
class ErrorView extends StatelessWidget {
  /// 创建错误视图。
  const new({required this.failure, super.key, this.onRetry});

  /// 失败分类（文案依据）。
  final Failure failure;

  /// 重试回调（用户驱动；框架不自动重试——ProviderScope retry 已关闭）。
  final VoidCallback? onRetry;

  String get _title {
    switch (failure) {
      case FailureUnauthorized():
        return '登录已失效';
      case FailureHttp(:final status) when status == 403:
        return '令牌授权范围不足';
      case FailureHttp(:final status) when status == 404:
        return '资源不存在';
      case FailureHttp():
        return '请求失败';
      case FailureParse():
        return '数据解析失败';
      case FailureNetwork():
        return '网络不可用';
      case FailureUnknown():
        return '出错了';
    }
  }

  String get _description {
    switch (failure) {
      case FailureUnauthorized():
        return '请重新登录后再试。';
      case FailureHttp(:final status) when status == 403:
        return '请在 CNB「个人设置 → 访问令牌」检查令牌的授权范围后重试。';
      case FailureHttp(:final status) when status == 404:
        return '内容可能已被删除或你暂时无权查看。';
      case FailureHttp(:final status):
        return '服务返回了异常状态（$status），请稍后重试。';
      case FailureParse():
        return '服务返回了无法识别的数据，请重试或反馈问题。';
      case FailureNetwork():
        return '网络不可用，请检查连接后重试。';
      case FailureUnknown():
        return '发生了未知错误，请重试。';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _title,
              style: AppTypography.title.copyWith(
                color: context.tTheme.textColorPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _description,
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
