import 'package:cna/core/error/failure.dart';
import 'package:cna_api/cna_api.dart';

/// 认证数据源合同（形状对齐 `ReposDataSource`：抽象在 data 层，允许认识生成
/// DTO；`cna_api` 到此为止不进 domain / UI）。
///
/// 校验方式维度由此层隔离：M2 用 `FakeAuthDataSource`，M4 换
/// `cna_api.UsersApi.getUserInfo()` 实现时只换 datasource。
abstract interface class AuthDataSource {
  /// 校验 PAT：成功返回当前用户信息（CNB `GET /user`，`UsersApi.getUserInfo`）；
  /// 失败抛 [Failure]（401 → 无效令牌、403 → 授权范围不足、网络 → 可重试）。
  Future<DtoUsersResult> verify(String token);
}
