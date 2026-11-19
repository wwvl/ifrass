import 'package:cna/core/theme/app_tokens.dart';
import 'package:cna/shared/widgets/skeleton_repo_card.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 统一分页列表（DESIGN.md §6 点名组件）：纯渲染，不管数据来源。
///
/// - [onLoadMore]：滚动到底部自动触发（provider 层做 epoch 防护）；
/// - footer 三态：加载中（骨架行）/ 到底 / 失败重试；
/// - 下拉刷新手势由 `TPullDownRefresh` 承担，本组件不管。
class PagedList<T> extends StatefulWidget {
  /// 创建分页列表。
  const new({
    required this.items,
    required this.itemBuilder,
    required this.hasMore,
    required this.loadingMore,
    required this.loadMoreFailed,
    required this.onLoadMore,
    required this.onRetryLoadMore,
    super.key,
    this.controller,
  });

  /// 已加载条目。
  final List<T> items;

  /// 单条渲染（业务回调）。
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// 是否还有下一页。
  final bool hasMore;

  /// 正在上拉加载。
  final bool loadingMore;

  /// 上拉加载失败（footer 重试）。
  final bool loadMoreFailed;

  /// 滚动到底触发加载更多。
  final VoidCallback onLoadMore;

  /// footer 重试回调。
  final VoidCallback onRetryLoadMore;

  /// 滚动控制器（外部传入则由外部持有）。
  final ScrollController? controller;

  @override
  State<PagedList<T>> createState() => _PagedListState<T>();
}

class _PagedListState<T> extends State<PagedList<T>> {
  late final ScrollController _scroll = widget.controller ?? ScrollController();

  bool _ownsScroll = false;

  static const double _loadMoreThreshold = 200;

  void _onScroll() {
    if (!widget.hasMore ||
        widget.loadingMore ||
        widget.loadMoreFailed ||
        !_scroll.hasClients) {
      return;
    }
    final position = _scroll.position;
    if (position.maxScrollExtent - position.pixels <= _loadMoreThreshold) {
      widget.onLoadMore();
    }
  }

  @override
  void initState() {
    super.initState();
    _ownsScroll = widget.controller == null;
    if (_ownsScroll) {
      _scroll.addListener(_onScroll);
    } else {
      widget.controller!.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    if (_ownsScroll) {
      _scroll.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.loadingMore) {
      // 空数据交给 AsyncStateHost 的 empty 态呈现；本组件只渲染有条目场景
      return const SizedBox.shrink();
    }
    final footer = _buildFooter(context);
    return ListView.builder(
      controller: _scroll,
      // +1：footer 槽位（到底 / 加载中 / 失败重试）
      itemCount: widget.items.length + 1,
      itemBuilder: (context, index) {
        if (index < widget.items.length) {
          return widget.itemBuilder(context, widget.items[index]);
        }
        return footer;
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (widget.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: SkeletonBlock(height: 48),
      );
    }
    if (widget.loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(
              '加载更多失败',
              style: AppTypography.body.copyWith(
                color: context.tTheme.errorColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TButton(
              variant: TButtonVariant.outline,
              onPressed: widget.onRetryLoadMore,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (!widget.hasMore) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          '已经到底了',
          textAlign: TextAlign.center,
          style: AppTypography.label.copyWith(
            color: context.tTheme.textColorPlaceholder,
          ),
        ),
      );
    }
    // 有更多但未触发：给滚动留出触发空间
    return const SizedBox(height: AppSpacing.xl);
  }
}
