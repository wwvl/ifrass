import 'package:cna/core/network/network_providers.dart';
import 'package:cna/features/repos/data/datasource/fake_repos_datasource.dart';
import 'package:cna/features/repos/data/datasource/remote_repos_datasource.dart';
import 'package:cna/features/repos/data/datasource/repos_datasource.dart';
import 'package:cna/features/repos/data/repo_impl/remote_repos_repository.dart';
import 'package:cna/features/repos/domain/repositories/repos_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repos_providers.g.dart';

/// 仓库数据源 Provider：M3 假数据源，M4 换 `cna_api` 远程实现（只换这里）。
@Riverpod(keepAlive: true, name: 'reposDataSourceProvider')
ReposDataSource reposDataSource(Ref ref) => FakeReposDataSource();

/// Production remote data source. The composition root overrides the fake
/// provider with this instance; tests can continue overriding the fake slot.
@Riverpod(keepAlive: true, name: 'remoteReposDataSourceProvider')
ReposDataSource remoteReposDataSource(Ref ref) {
  final dataSource = RemoteReposDataSource(
    api: ref.watch(apiClientProvider).repositories,
  );
  ref.onDispose(dataSource.cancelInFlight);
  return dataSource;
}

/// 仓库仓储 Provider（AGENTS.md §7 核心 provider）：Fake 数据源 + mapper 组装。
@Riverpod(keepAlive: true, name: 'reposRepositoryProvider')
ReposRepository reposRepository(Ref ref) {
  final dataSource = ref.watch(reposDataSourceProvider);
  return RemoteReposRepository(dataSource: dataSource);
}
