/// 分页状态与通用 Notifier 组合（AGENTS.md §5：分页状态放 core，
/// feature 不得各写一套）。
///
/// 用法：状态类 `AsyncNotifier<PagedListState<T>>` + [PagedListMixin]，
/// 子类只实现 [PagedListMixin.fetch]（对接 Repository 抽象接口）。
/// 首屏错误经 AsyncValue 走 `AsyncStateHost` 五态；上拉失败不清列表
/// （footer 重试）；下拉刷新失败保留旧列表（手势回调自行呈现提示）。
///
/// 取消语义（M3）：请求序号（epoch）竞态防护——每次发起 `_seq++`，
/// 响应回来若序号不匹配（已被更新请求取代或已失效）则丢弃。
/// M4 演进缝：`fetch` 增加可选 `CancelToken?` 参数走 Dio 真 abort，
/// 状态层与本文件零改动；epoch 防护继续作为兜底。
library;

import 'package:cna/core/error/failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 分页列表状态（items / 搜索词 / 翻页游标语义）。
class PagedListState<T> {
  /// 创建分页状态。
  const new({
    this.items = const [],
    this.search,
    this.hasMore = false,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  /// 已加载条目（跨页累积）。
  final List<T> items;

  /// 当前搜索词；null 表示未过滤。
  final String? search;

  /// 是否还有下一页（与 `items.length >= pageSize` 对齐，CNB 无 total）。
  final bool hasMore;

  /// 正在上拉加载（footer 骨架行）。
  final bool loadingMore;

  /// 上拉加载失败（footer 重试，不清列表）。
  final bool loadMoreFailed;

  /// 拷贝并替换部分字段。
  PagedListState<T> copyWith({
    List<T>? items,
    String? search,
    bool? hasMore,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) {
    return PagedListState<T>(
      items: items ?? this.items,
      search: search ?? this.search,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

/// 通用分页组合：混入 `AsyncNotifier<PagedListState<T>>` 的实现类。
///
/// 子类示例：
/// ```dart
/// @riverpod
/// class ReposList extends AsyncNotifier<PagedListState<Repo>>
///     with PagedListMixin<Repo> {
///   @override
///   Future<PagedListState<Repo>> build() async {
///     registerDisposeGuard();
///     return loadFirstPage();
///   }
///
///   @override
///   Future<List<Repo>> fetch(int page, String? search) =>
///       ref.read(reposRepositoryProvider)
///           .listRepos(page: page, pageSize: pageSize, search: search);
/// }
/// ```
mixin PagedListMixin<T> on AsyncNotifier<PagedListState<T>> {
  /// 请求序号：每次发起自增；响应回来序号不匹配即丢弃（防竞态 / 防过期写回）。
  int _seq = 0;

  /// 拉取一页数据；失败抛 [Failure]（首屏 → AsyncError，上拉 → footer 重试）。
  Future<List<T>> fetch(int page, String? search);

  /// 每页条数（子类可覆盖）。
  int get pageSize => 20;

  /// 子类 build() 首行调用：dispose 后使所有在途请求的响应失效。
  void registerDisposeGuard() {
    ref.onDispose(() => _seq = -1);
  }

  /// 首屏加载（build 内使用）：page 1，失败直接抛给 AsyncValue。
  Future<PagedListState<T>> loadFirstPage() async {
    final seq = ++_seq;
    final search = state.value?.search;
    final items = await fetch(1, search);
    if (seq != _seq) {
      return state.value ?? PagedListState<T>();
    }
    return PagedListState<T>(
      items: items,
      search: search,
      hasMore: items.length >= pageSize,
    );
  }

  /// 下拉刷新：回到第 1 页。
  ///
  /// 失败时 state 不动（旧列表保留），异常上抛给手势回调呈现提示；
  /// 成功后重置 hasMore / loadMoreFailed。
  Future<void> refresh() async {
    final seq = ++_seq;
    final search = state.value?.search;
    final items = await fetch(1, search);
    if (seq != _seq) {
      return;
    }
    state = AsyncData(
      PagedListState<T>(
        items: items,
        search: search,
        hasMore: items.length >= pageSize,
      ),
    );
  }

  /// 上拉加载下一页：失败置 `loadMoreFailed`（footer 重试），不清列表。
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) {
      return;
    }
    final seq = ++_seq;
    final nextPage = current.items.length ~/ pageSize + 1;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final items = await fetch(nextPage, current.search);
      if (seq != _seq) {
        return;
      }
      state = AsyncData(
        PagedListState<T>(
          items: [...current.items, ...items],
          search: current.search,
          hasMore: items.length >= pageSize,
        ),
      );
    } on Failure catch (error, stackTrace) {
      if (seq != _seq) {
        return;
      }
      state = AsyncData(current.copyWith(loadMoreFailed: true));
      // 上拉失败不进 AsyncError（列表保留）；错误经 footer 重试出口呈现
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// 搜索：等价于带词刷新；失败进入 AsyncError（AsyncStateHost 呈现）。
  Future<void> search(String query) async {
    final seq = ++_seq;
    final keyword = query.trim();
    try {
      final items = await fetch(1, keyword.isEmpty ? null : keyword);
      if (seq != _seq) {
        return;
      }
      state = AsyncData(
        PagedListState<T>(
          items: items,
          search: keyword.isEmpty ? null : keyword,
          hasMore: items.length >= pageSize,
        ),
      );
    } on Failure catch (error, stackTrace) {
      if (seq != _seq) {
        return;
      }
      state = AsyncError(error, stackTrace);
    }
  }
}
