import 'package:cna/core/error/failure.dart';
import 'package:cna/features/auth/domain/auth_state.dart';

/// 认证域仓储抽象（形状对齐 `ReposRepository`：接口在 domain，实现在 data）。
///
/// token 来源维度由此层隔离：一期 `PatAuthRepository`，二期换
/// `OAuthAuthRepository` 时 UI / state / 路由一行不动（AGENTS.md §6）。
/// 纯 Dart——不认识 Dio、`cna_api` 与 Flutter。
abstract interface class AuthRepository {
  /// 校验 [token] 并写入 SecureStorage。
  ///
  /// 成功返回 null（调用方据此置 `AuthSignedIn(token)`）；
  /// 失败返回 [Failure]（401 → 令牌无效、403 → 授权范围不足、网络 → 可重试），
  /// 登录页负责差异化文案。
  Future<Failure?> signIn(String token);

  /// 恢复会话：无本地 token → [AuthSignedOut]；校验通过 → [AuthSignedIn]。
  ///
  /// 401 / 网络失败等 → 抛 [Failure]：401 由上层经唯一失效入口复位，
  /// 其余由 splash 保持 Unknown 并重试，本方法不吞错误。
  Future<AuthState> restore();

  /// 用户主动登出：清除本地 token。
  Future<void> signOut();

  /// 会话失效复位（401 单一入口 `handleUnauthorized` 调用）：清除本地 token。
  Future<void> invalidate();
}
