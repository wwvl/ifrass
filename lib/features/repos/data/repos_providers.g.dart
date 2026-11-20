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

String _$reposDataSourceHash() => r'5a3a17c1704968fa0465707caf3878caf3aad1a3';

/// Production remote data source. The composition root overrides the fake
/// provider with this instance; tests can continue overriding the fake slot.

@ProviderFor(remoteReposDataSource)
final remoteReposDataSourceProvider = RemoteReposDataSourceProvider._();

/// Production remote data source. The composition root overrides the fake
/// provider with this instance; tests can continue overriding the fake slot.

final class RemoteReposDataSourceProvider
    extends
        $FunctionalProvider<ReposDataSource, ReposDataSource, ReposDataSource>
    with $Provider<ReposDataSource> {
  /// Production remote data source. The composition root overrides the fake
  /// provider with this instance; tests can continue overriding the fake slot.
  RemoteReposDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteReposDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteReposDataSourceHash();

  @$internal
  @override
  $ProviderElement<ReposDataSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReposDataSource create(Ref ref) {
    return remoteReposDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReposDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReposDataSource>(value),
    );
  }
}

String _$remoteReposDataSourceHash() =>
    r'3aa0cad5064b30fbfebf719385d33d1f2eac0286';

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

String _$reposRepositoryHash() => r'1253b569eac955841fc49ad32a74dab78085a7fc';
