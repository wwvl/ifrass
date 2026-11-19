import 'package:meta/meta.dart';

/// 认证状态（AGENTS.md §6：sealed 三态；守卫 `appRedirect` 只认这三态）。
///
/// [AuthUnknown] 期间守卫统一送 `/splash`； splash 上的 restore 网络失败
/// 保持 Unknown（离线重试），不加第四态。
sealed class AuthState {
  /// 创建认证状态。
  const new();
}

/// 启动解析中：会话尚未落定（splash 停留期）。
@immutable
class AuthUnknown extends AuthState {
  /// 创建解析中状态。
  const new();

  @override
  bool operator ==(Object other) => other is AuthUnknown;

  @override
  int get hashCode => 1;
}

/// 未登录。
@immutable
class AuthSignedOut extends AuthState {
  /// 创建未登录状态。
  const new();

  @override
  bool operator ==(Object other) => other is AuthSignedOut;

  @override
  int get hashCode => 2;
}

/// 已登录；[token] 只驻内存与 SecureStorage，禁止进日志 / prompt（AGENTS.md §11）。
@immutable
class AuthSignedIn extends AuthState {
  /// 创建已登录状态。
  const new(this.token);

  /// 当前 PAT。
  final String token;

  @override
  bool operator ==(Object other) =>
      other is AuthSignedIn && other.token == token;

  @override
  int get hashCode => Object.hash(AuthSignedIn, token);
}
