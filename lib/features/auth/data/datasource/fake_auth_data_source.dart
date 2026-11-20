import 'package:cna/core/error/failure.dart';
import 'package:cna/features/auth/data/datasource/auth_data_source.dart';
import 'package:cna/features/auth/domain/entities/auth_user.dart';

/// 假认证数据源（M2；M4 换远程实现）。
///
/// 行为：任意非空 token 校验成功（返回与真实 DTO 字段对应的领域种子）；
/// 三种可注入行为用于驱动差异化文案与五态：
/// - [invalidToken] 命中 → 抛 [FailureUnauthorized]（401）
/// - [networkFailToken] 命中 → 抛 [FailureNetwork]
/// - [delay] 模拟慢响应（注入 [Duration.zero] 加速测试）
class FakeAuthDataSource implements AuthDataSource {
  /// 创建假数据源。
  new({
    this.delay = const Duration(milliseconds: 300),
    this.invalidToken,
    this.networkFailToken,
  });

  /// 模拟网络延时。
  final Duration delay;

  /// 命中即抛 401 的固定 token（如 `'invalid-token'`）。
  final String? invalidToken;

  /// 命中即抛网络失败的固定 token。
  final String? networkFailToken;

  /// 种子用户：字段与 `DtoUsersResult` 真实字段对应，并保留可空语义。
  static const AuthUser _seedUser = AuthUser(
    id: 'user-1',
    nickname: 'cnb-dev',
    avatar: 'https://cnb.cool/avatar/cnb-dev.png',
    email: 'cnb-dev@example.com',
    bio: 'CNB 移动端开发者',
    company: 'cnb',
    location: 'Shenzhen',
    createdAt: '2026-01-01T00:00:00Z',
  );

  @override
  Future<AuthUser> verify(String token) async {
    await Future<void>.delayed(delay);
    if (token == invalidToken) {
      throw const FailureUnauthorized(body: 'fake: invalid token');
    }
    if (token == networkFailToken) {
      throw const FailureNetwork(message: 'fake: network unreachable');
    }
    if (token.trim().isEmpty) {
      throw const FailureHttp(400, body: 'token must not be empty');
    }
    return _seedUser;
  }
}
