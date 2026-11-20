import 'package:cna/features/repos/data/datasource/repos_datasource.dart';
import 'package:cna/features/repos/data/mappers/repo_mappers.dart';
import 'package:cna/features/repos/domain/entities/repo.dart';
import 'package:cna/features/repos/domain/repositories/repos_repository.dart';

/// Remote 仓储：把生成 DTO 映射为 domain Repo。
///
/// 该类不暴露生成客户端给 presentation；FakeDataSource 也可以注入，
/// 使测试仍只需 override datasource。
class RemoteReposRepository implements ReposRepository {
  /// 创建远程仓储。
  new({required this.dataSource});

  /// 可替换的数据源（生产为远程数据源）。
  final ReposDataSource dataSource;

  @override
  Future<List<Repo>> listRepos({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    final dtos = await dataSource.listRepos(
      page: page,
      pageSize: pageSize,
      search: search,
    );
    return reposFromDtos(dtos);
  }

  @override
  Future<Repo> getRepo({required String path}) async {
    final dto = await dataSource.getRepo(path: path);
    return repoFromDto(dto);
  }
}
