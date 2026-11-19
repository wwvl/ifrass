import 'package:cna/features/repos/data/datasource/fake_repos_datasource.dart';
import 'package:cna/features/repos/data/datasource/repos_datasource.dart';
import 'package:cna/features/repos/data/repo_impl/fake_repos_repository.dart';
import 'package:cna/features/repos/domain/repositories/repos_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repos_providers.g.dart';

/// 仓库数据源 Provider：M3 假数据源，M4 换 `cna_api` 远程实现（只换这里）。
@Riverpod(keepAlive: true)
ReposDataSource reposDataSource(Ref ref) => FakeReposDataSource();

/// 仓库仓储 Provider（AGENTS.md §7 核心 provider）：Fake 数据源 + mapper 组装。
@Riverpod(keepAlive: true)
ReposRepository reposRepository(Ref ref) =>
    FakeReposRepository(dataSource: ref.watch(reposDataSourceProvider));
