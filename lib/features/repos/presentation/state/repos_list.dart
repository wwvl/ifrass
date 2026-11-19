import 'package:cna/core/network/pagination.dart';
import 'package:cna/features/repos/data/repos_providers.dart';
import 'package:cna/features/repos/domain/entities/repo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 仓库列表分页状态（AGENTS.md §5：分页逻辑收口在 core 的 `PagedListNotifier`，
/// 本类只对接 Repository 抽象接口——UI 不认识 datasource / cna_api）。
///
/// Riverpod 3 泛型基类复用形态：`AsyncNotifierProvider` 手写实例化
/// （生成器产物 `_$Xxx` 是 class 无法与自定义基类混入）。
class ReposList extends PagedListNotifier<Repo> {
  @override
  Future<PagedListState<Repo>> build() {
    registerDisposeGuard();
    return loadFirstPage();
  }

  @override
  Future<List<Repo>> fetch(int page, String? search) => ref
      .read(reposRepositoryProvider)
      .listRepos(page: page, pageSize: pageSize, search: search);
}

/// 仓库列表 Provider。
final AsyncNotifierProvider<ReposList, PagedListState<Repo>> reposListProvider =
    AsyncNotifierProvider<ReposList, PagedListState<Repo>>(ReposList.new);
