import 'dart:async';

import 'package:cna/core/network/pagination.dart';
import 'package:cna/core/router/routes.dart';
import 'package:cna/core/theme/app_tokens.dart';
import 'package:cna/features/repos/domain/entities/repo.dart';
import 'package:cna/features/repos/presentation/state/repos_list.dart';
import 'package:cna/shared/widgets/async_state_view.dart';
import 'package:cna/shared/widgets/empty_view.dart';
import 'package:cna/shared/widgets/paged_list.dart';
import 'package:cna/shared/widgets/repo_card.dart';
import 'package:cna/shared/widgets/skeleton_repo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 仓库列表页（DESIGN.md §5 规格）：
/// 数据源 = `ReposRepository` 抽象接口（禁止直调 datasource / cna_api）；
/// 主组件 = TNavBar + TInput（搜索）+ TPullDownRefresh + PagedList + RepoCard；
/// 交互 = 下拉刷新 / 上拉分页 / 搜索 / 点击进详情；五态由 AsyncStateHost 收敛。
class ReposPage extends ConsumerStatefulWidget {
  /// 创建仓库列表页。
  const new({super.key});

  @override
  ConsumerState<ReposPage> createState() => _ReposPageState();
}

class _ReposPageState extends ConsumerState<ReposPage> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reposListProvider);
    final search = async.value?.search;

    return Scaffold(
      appBar: const TNavBar(title: Text('仓库')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TInput(
              hintText: '搜索仓库',
              onSubmitted: (value) =>
                  ref.read(reposListProvider.notifier).search(value),
            ),
          ),
          Expanded(
            child: AsyncStateHost<PagedListState<Repo>>(
              async: async,
              isEmpty: (state) => state.items.isEmpty,
              onRetry: () => ref.invalidate(reposListProvider),
              loadingView: const SkeletonList(),
              emptyView: EmptyView(
                title: search == null ? '还没有可见的仓库' : '没有找到「$search」',
                description: search == null
                    ? '你的令牌可见的仓库会出现在这里；也可能是令牌授权范围未覆盖。'
                    : '换个关键词试试，或清除搜索查看全部仓库。',
                actionLabel: search == null ? null : '清除搜索',
                onAction: search == null
                    ? null
                    : () => ref.read(reposListProvider.notifier).search(''),
              ),
              contentBuilder: (context, state) => TPullDownRefresh(
                onRefresh: () => ref.read(reposListProvider.notifier).refresh(),
                onLoadMore: () =>
                    ref.read(reposListProvider.notifier).loadMore(),
                child: PagedList<Repo>(
                  items: state.items,
                  itemBuilder: (context, repo) => RepoCard(
                    repo: repo,
                    onTap: () {
                      final segments = repo.path.split('/');
                      final owner = segments.firstOrNull ?? repo.name;
                      final name = segments.length > 1
                          ? segments.last
                          : repo.name;
                      unawaited(
                        context.push(AppRoutes.repo(owner: owner, name: name)),
                      );
                    },
                  ),
                  hasMore: state.hasMore,
                  loadingMore: state.loadingMore,
                  loadMoreFailed: state.loadMoreFailed,
                  onLoadMore: () =>
                      ref.read(reposListProvider.notifier).loadMore(),
                  onRetryLoadMore: () =>
                      ref.read(reposListProvider.notifier).loadMore(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
