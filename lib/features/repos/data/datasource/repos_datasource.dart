import 'package:cna_api/cna_api.dart';

/// 仓库数据源合同（data 层：允许认识生成 DTO，DTO 到此为止不进 domain/UI）。
///
/// 职责边界：拆生成客户端的 sealed Result（`GetReposResultHttp200` /
/// `GetReposResultError`…）并把非 2xx 统一转 `Failure` 抛出——本合同的方法
/// 只在成功路径返回 DTO。真实现 `RemoteReposDataSource`（M2 接网）与
/// `FakeReposDataSource`（M3 UI 五态）都实现本接口，实现可互换
/// （AGENTS.md §9：将来替换 datasource 不动上层）。
abstract interface class ReposDataSource {
  /// 分页列仓库（对应生成客户端 `RepositoriesApi.getRepos`）。
  Future<List<DtoRepos4User>> listRepos({
    required int page,
    required int pageSize,
    String? search,
  });

  /// 按 path 取仓库详情（对应生成客户端 `RepositoriesApi.getByID`）。
  Future<DtoRepos4User> getRepo({required String path});
}
