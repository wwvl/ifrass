// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repos_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 仓库数据源 Provider：M3 假数据源，M4 换 `cna_api` 远程实现（只换这里）。

@ProviderFor(reposDataSource)
final reposDataSourceProvider = ReposDataSourceProvider._();

/// 仓库数据源 Provider：M3 假数据源，M4 换 `cna_api` 远程实现（只换这里）。

final class ReposDataSourceProvider
    extends
        $FunctionalProvider<ReposDataSource, ReposDataSource, ReposDataSource>
    with $Provider<ReposDataSource> {
  /// 仓库数据源 Provider：M3 假数据源，M4 换 `cna_api` 远程实现（只换这里）。
  ReposDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reposDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reposDataSourceHash();

  @$internal
  @override
  $ProviderElement<ReposDataSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReposDataSource create(Ref ref) {
    return reposDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReposDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReposDataSource>(value),
    );
  }
}

String _$reposDataSourceHash() => r'e2a941b550f0bffd77e8b0ac3a44626d94081649';

/// 仓库仓储 Provider（AGENTS.md §7 核心 provider）：Fake 数据源 + mapper 组装。

@ProviderFor(reposRepository)
final reposRepositoryProvider = ReposRepositoryProvider._();

/// 仓库仓储 Provider（AGENTS.md §7 核心 provider）：Fake 数据源 + mapper 组装。

final class ReposRepositoryProvider
    extends
        $FunctionalProvider<ReposRepository, ReposRepository, ReposRepository>
    with $Provider<ReposRepository> {
  /// 仓库仓储 Provider（AGENTS.md §7 核心 provider）：Fake 数据源 + mapper 组装。
  ReposRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reposRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reposRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReposRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReposRepository create(Ref ref) {
    return reposRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReposRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReposRepository>(value),
    );
  }
}

String _$reposRepositoryHash() => r'59554f0ffe02dad54e625efbbcd2702997f00096';
