/// 分页状态与通用 Notifier 基类（AGENTS.md §5：分页状态放 core，
/// feature 不得各写一套）。
///
/// 用法（Riverpod 3 custom base class 模式）：注解类继承
/// [PagedListNotifier]，provider 用手写 `AsyncNotifierProvider` 实例化
/// （生成器产物 `_$Xxx` 是 class，无法与自定义基类组合混入）——
/// ```dart
/// class ReposList extends PagedListNotifier<Repo> {
///   @override
///   Future<PagedListState<Repo>> build() {
///     registerDisposeGuard();
///     return loadFirstPage();
///   }
///
///   @override
///   Future<List<Repo>> fetch(int page, String? search) =>
///       ref.read(reposRepositoryProvider)
///           .listRepos(page: page, pageSize: pageSize, search: search);
/// }
///
/// final reposListProvider =
///     AsyncNotifierProvider<ReposList, PagedListState<Repo>>(ReposList.new);
/// ```
/// 首屏错误经 AsyncValue 走 `AsyncStateHost` 五态；上拉失败不清列表
/// （footer 重试）；下拉刷新失败保留旧列表（手势回调自行呈现提示）。
///
/// 取消语义（M4 落地）：每次发起 `_seq++`，响应回来若序号不匹配（已被
/// 更新请求取代或 provider 已 dispose）则丢弃；M4 起页面销毁还会经
/// datasource 的 `cancelInFlight()` 真 abort 在途请求——被取消的请求以
/// Failure 形态抛回，本基类在各 await 点**先查 epoch 再处理错误**：
/// 已过期（dispose）的错误静默吞掉，不向已销毁的 provider 写状态、
/// 不向已卸载的手势回调上抛；epoch 防护继续作为竞态兜底。
library;

import 'dart:async';

import 'package:cna/core/error/failure.dart';
import 'package:cna/core/network/request_cancellation_scope.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

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

/// 通用分页 Notifier 基类：承载刷新 / 上拉 / 搜索与 epoch 防护，
/// 子类只实现 [fetch]（对接 Repository 抽象接口）。
abstract class PagedListNotifier<T> extends AsyncNotifier<PagedListState<T>> {
  /// 请求序号：每次发起自增；响应回来序号不匹配即丢弃（防竞态 / 防过期写回）。
  int _seq = 0;

  final Set<CancelToken> _activeTokens = <CancelToken>{};
  bool _pausedWithRequests = false;

  /// 拉取一页数据；失败抛 [Failure]（首屏 → AsyncError，上拉 → footer 重试）。
  Future<List<T>> fetch(int page, String? search);

  /// 每页条数（子类可覆盖；受保护成员，不作为 Notifier 公开 API）。
  @protected
  int get pageSize => 20;

  /// 子类 build() 首行调用：dispose 后使所有在途请求的响应失效。
  @protected
  void registerDisposeGuard() {
    ref.onDispose(() {
      _seq = -1;
      _cancelActiveRequests('Paged list disposed');
    });
    ref.onCancel(() {
      if (_activeTokens.isEmpty) return;
      _pausedWithRequests = true;
      _seq++;
      _cancelActiveRequests('Paged list has no listeners');
    });
    ref.onResume(() {
      if (!_pausedWithRequests) return;
      _pausedWithRequests = false;
      // Keep-alive AsyncNotifierProviders are paused, not disposed, when a
      // page stops listening. Rebuild on return so a canceled request is not
      // mistaken for a completed empty page.
      unawaited(
        Future<void>.microtask(() {
          if (ref.mounted) ref.invalidateSelf();
        }),
      );
    });
  }

  void _cancelActiveRequests(String reason) {
    for (final token in _activeTokens) {
      if (!token.isCancelled) token.cancel(reason);
    }
    _activeTokens.clear();
  }

  Future<List<T>> _fetch(int page, String? search) async {
    final token = CancelToken();
    _activeTokens.add(token);
    try {
      return await RequestCancellationScope.run(
        token,
        () => fetch(page, search),
      );
    } finally {
      _activeTokens.remove(token);
    }
  }

  /// 首屏加载（build 内使用）：page 1，失败直接抛给 AsyncValue；
  /// provider 已 dispose（含被 CancelToken abort）时静默丢弃。
  @protected
  Future<PagedListState<T>> loadFirstPage() async {
    final seq = ++_seq;
    final search = state.value?.search;
    List<T> items;
    try {
      items = await _fetch(1, search);
    } on Failure catch (error, stackTrace) {
      if (seq != _seq) {
        // 响应过期（被取代或 provider 已失效）：静默丢弃，不上抛
        return PagedListState<T>();
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (seq != _seq) {
      // 响应过期（被取代或 provider 已失效）：丢弃，不读已失效的 state
      return PagedListState<T>();
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
  /// provider 已 dispose（含被 CancelToken abort）时静默丢弃，不向已卸载
  /// 的手势回调上抛。成功后重置 hasMore / loadMoreFailed。
  Future<void> refresh() async {
    final seq = ++_seq;
    final search = state.value?.search;
    List<T> items;
    try {
      items = await _fetch(1, search);
    } on Failure catch (error, stackTrace) {
      if (seq != _seq) {
        return;
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
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
      final items = await _fetch(nextPage, current.search);
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
      final items = await _fetch(1, keyword.isEmpty ? null : keyword);
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
