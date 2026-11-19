import 'package:cna/core/error/failure.dart';
import 'package:cna/core/theme/app_tokens.dart';
import 'package:cna/features/auth/presentation/state/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// PAT 登录页（AGENTS.md §6：一个主操作；无用户名密码框）。
///
/// 最小权限引导 + 明示「token 只存本机 Keystore / Keychain」；
/// 失败给差异化文案；登录成功不在这里导航——由守卫按 `from` 回跳
/// （AGENTS.md §12：禁止页面拼跳转逻辑）。
class LoginPage extends ConsumerStatefulWidget {
  /// 创建登录页。
  const new({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _tokenController = TextEditingController();
  String? _errorText;
  bool _submitting = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _errorText = '请先粘贴访问令牌');
      return;
    }
    setState(() {
      _errorText = null;
      _submitting = true;
    });
    final failure = await ref.read(authNotifierProvider.notifier).signIn(token);
    if (!mounted) {
      return;
    }
    // 成功不导航：AuthState 变化经 refreshListenable 触发守卫，按 from 回跳。
    setState(() {
      _errorText = failure == null ? null : _failureText(failure);
      _submitting = false;
    });
  }

  String _failureText(Failure failure) {
    switch (failure) {
      case FailureUnauthorized():
        return '令牌无效或已过期，请重新生成';
      case FailureHttp(:final status) when status == 403:
        return '令牌授权范围不足，请检查令牌权限';
      case FailureNetwork():
        return '网络不可用，请检查连接后重试';
      default:
        return '登录失败，请稍后重试';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              '登录 CNB',
              style: AppTypography.headline.copyWith(
                color: context.tTheme.textColorPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '粘贴个人访问令牌（PAT）完成登录。',
              style: AppTypography.body.copyWith(
                color: context.tTheme.textColorSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '权限说明',
              style: AppTypography.title.copyWith(
                color: context.tTheme.textColorPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '· 按最小权限创建令牌：只勾选仓库、Issue、PR、构建与动态的读取权限\n'
              '· 令牌只存本机 Keystore / Keychain，不经过任何第三方服务\n'
              '· 随时可在 CNB「个人设置 → 访问令牌」撤销',
              style: AppTypography.body.copyWith(
                color: context.tTheme.textColorSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TInput(
              controller: _tokenController,
              hintText: '粘贴访问令牌（PAT）',
              obscureText: true,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorText!,
                style: AppTypography.label.copyWith(
                  color: context.tTheme.errorColor,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            TButton(
              variant: TButtonVariant.fill,
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? '登录中…' : '登录'),
            ),
          ],
        ),
      ),
    );
  }
}
