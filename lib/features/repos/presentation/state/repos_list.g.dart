// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repos_list.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 仓库列表分页状态（AGENTS.md §5：分页逻辑收口在 core 的 `PagedListNotifier`，
/// 本类只对接 Repository 抽象接口——UI 不认识 datasource / cna_api）。

@ProviderFor(ReposList)
final reposListProvider = ReposListProvider._();

/// 仓库列表分页状态（AGENTS.md §5：分页逻辑收口在 core 的 `PagedListNotifier`，
/// 本类只对接 Repository 抽象接口——UI 不认识 datasource / cna_api）。
final class ReposListProvider
    extends $AsyncNotifierProvider<ReposList, PagedListState<Repo>> {
  /// 仓库列表分页状态（AGENTS.md §5：分页逻辑收口在 core 的 `PagedListNotifier`，
  /// 本类只对接 Repository 抽象接口——UI 不认识 datasource / cna_api）。
  ReposListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reposListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reposListHash();

  @$internal
  @override
  ReposList create() => ReposList();
}

String _$reposListHash() => r'4069b84adc28a413571f9042b066f080c5a8b43e';

/// 仓库列表分页状态（AGENTS.md §5：分页逻辑收口在 core 的 `PagedListNotifier`，
/// 本类只对接 Repository 抽象接口——UI 不认识 datasource / cna_api）。

abstract class _$ReposList extends $AsyncNotifier<PagedListState<Repo>> {
  FutureOr<PagedListState<Repo>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<PagedListState<Repo>>, PagedListState<Repo>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PagedListState<Repo>>,
                PagedListState<Repo>
              >,
              AsyncValue<PagedListState<Repo>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
