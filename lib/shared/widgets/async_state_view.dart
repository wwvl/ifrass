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
/// 本文件只声明合同，不包含任何实现；实现与配套的
/// EmptyView / ErrorView / OfflineView / Skeleton* 在后续里程碑落于
/// `lib/shared/widgets/`。
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
