import 'package:cna/features/repos/data/datasource/repos_datasource.dart';
import 'package:cna/features/repos/data/mappers/repo_mappers.dart';
import 'package:cna/features/repos/domain/entities/repo.dart';
import 'package:cna/features/repos/domain/repositories/repos_repository.dart';

/// [ReposRepository] 的开发/测试实现：Fake 数据源 + mapper 组装。
///
/// M3 UI 垂直切片用；M4 换 `RemoteReposRepository`（真数据源实现）时
/// 仅替换 `reposRepositoryProvider` 的装配，UI / 状态层一行不动。
/// 错误语义与 M1 数据源一致：FakeDS 抛 Failure（core/error），原样上抛。
class FakeReposRepository implements ReposRepository {
  /// 创建假仓储。
  new({required this._dataSource});

  final ReposDataSource _dataSource;

  @override
  Future<List<Repo>> listRepos({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    final dtos = await _dataSource.listRepos(
      page: page,
      pageSize: pageSize,
      search: search,
    );
    return reposFromDtos(dtos);
  }

  @override
  Future<Repo> getRepo({required String path}) async {
    final dto = await _dataSource.getRepo(path: path);
    return repoFromDto(dto);
  }
}
