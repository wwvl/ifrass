import 'package:cna/core/error/failure.dart';
import 'package:cna/shared/widgets/empty_view.dart';
import 'package:cna/shared/widgets/error_view.dart';
import 'package:cna/shared/widgets/offline_view.dart';
import 'package:cna/shared/widgets/skeleton_repo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 异步渲染态（DESIGN.md §8 五态；dark 为全主题维度，不在此枚举）。
enum AsyncPhase {
  /// 加载中：骨架屏（与真实布局同尺寸），禁止全屏转圈。
  loading,

  /// 空数据且非错误：说明「为什么空 + 下一步做什么」。
  empty,

  /// 错误：可读错误 + 重试；403/404 给差异化文案。
  error,

  /// 离线：网络不可达；不伪装成空态。
  offline,

  /// 有数据。
  content,
}

/// 五态统一宿主的空接口（DESIGN.md §6）。
///
/// 目的：避免每个页面各写一遍 `AsyncValue.when` 分支。
/// 实现为同文件的 [AsyncStateHost]；配套的
/// EmptyView / ErrorView / OfflineView / Skeleton* 均在 `lib/shared/widgets/`。
///
/// 合同要求：
/// - 渲染分支由 [phase] 决定，页面不得手写状态判断；
/// - loading 必须是骨架屏，不是全屏 loading；
/// - error / offline 必须提供重试入口；
/// - 实现组件必须同时通过浅色与深色 golden test。
abstract interface class AsyncStateView extends StatelessWidget {
  const new({super.key});

  /// 当前渲染态。
  AsyncPhase get phase;
}

/// [AsyncStateView] 的唯一实现：把 `AsyncValue<T>` 映射为五态，
/// 页面只需给出内容态渲染与业务回调，不再各写 `when`。
///
/// - `AsyncLoading` 无旧值 → [loadingView]（默认骨架屏，与内容布局同尺寸）；
/// - `AsyncError` → [FailureNetwork] 归 `AsyncPhase.offline`，其余归
///   `AsyncPhase.error`（[ErrorView] 按 Failure 分类给差异化文案，403 必现）；
/// - `AsyncData` → [isEmpty] 谓词命中归 `AsyncPhase.empty`（[EmptyView]），
///   否则 [contentBuilder]；
/// - `AsyncLoading` 携带旧值（下拉刷新保数据场景）→ 直接呈现旧内容，
///   刷新手势动画由页面自管，不闪骨架。
class AsyncStateHost<T> extends StatelessWidget implements AsyncStateView {
  /// 创建五态宿主。
  const new({
    required this.async,
    required this.contentBuilder,
    super.key,
    this.isEmpty,
    this.onRetry,
    this.loadingView,
    this.emptyView,
  });

  /// 异步状态源。
  final AsyncValue<T> async;

  /// 内容态渲染。
  final Widget Function(BuildContext context, T value) contentBuilder;

  /// 空数据谓词（列表页传 `(items) => items.isEmpty`；详情页不传即永不 empty）。
  final bool Function(T value)? isEmpty;

  /// 重试入口（error / offline 态的按钮回调；null 则不显示按钮）。
  final VoidCallback? onRetry;

  /// 加载态视图（默认 [SkeletonList]，与内容布局同尺寸）。
  final Widget? loadingView;

  /// 空态视图（默认中性 [EmptyView]；业务页传定制文案）。
  final Widget? emptyView;

  @override
  AsyncPhase get phase {
    if (async.hasValue) {
      final predicate = isEmpty;
      final value = async.requireValue;
      if (predicate != null && predicate(value)) {
        return AsyncPhase.empty;
      }
      return AsyncPhase.content;
    }
    if (async.hasError) {
      return async.error is FailureNetwork
          ? AsyncPhase.offline
          : AsyncPhase.error;
    }
    return AsyncPhase.loading;
  }

  @override
  Widget build(BuildContext context) {
    switch (phase) {
      case AsyncPhase.loading:
        return loadingView ?? const SkeletonList();
      case AsyncPhase.empty:
        return emptyView ?? const EmptyView();
      case AsyncPhase.error:
        return ErrorView(failure: async.error! as Failure, onRetry: onRetry);
      case AsyncPhase.offline:
        return OfflineView(onRetry: onRetry);
      case AsyncPhase.content:
        return contentBuilder(context, async.requireValue);
    }
  }
}
