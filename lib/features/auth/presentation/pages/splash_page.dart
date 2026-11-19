import 'dart:async';

import 'package:cna/core/error/failure.dart';
import 'package:cna/core/theme/app_tokens.dart';
import 'package:cna/features/auth/presentation/state/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 启动解析页：`AuthUnknown` 期间停留并触发 `restore()`（AGENTS.md §7）。
///
/// 网络失败保持 Unknown（不加第四态）：本页展示离线提示 + 重试；
/// restore 落定后由守卫送走（SignedIn → 目标页，SignedOut → 登录页）。
class SplashPage extends ConsumerStatefulWidget {
  /// 创建启动页。
  const new({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    setState(() => _failure = null);
    try {
      await ref.read(authNotifierProvider.notifier).restore();
    } on Failure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() => _failure = failure);
    }
  }

  String _failureText(Failure failure) {
    switch (failure) {
      case FailureNetwork():
        return '网络不可用，请检查连接后重试';
      case FailureHttp(:final status) when status == 403:
        return '令牌授权范围不足，无法恢复会话';
      default:
        return '会话恢复失败，请重试';
    }
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CNB',
              style: AppTypography.headline.copyWith(
                color: context.tTheme.textColorPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              failure == null ? '正在恢复会话…' : _failureText(failure),
              style: AppTypography.body.copyWith(
                color: context.tTheme.textColorSecondary,
              ),
            ),
            if (failure != null) ...[
              const SizedBox(height: AppSpacing.md),
              TButton(
                variant: TButtonVariant.fill,
                onPressed: _restore,
                child: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
