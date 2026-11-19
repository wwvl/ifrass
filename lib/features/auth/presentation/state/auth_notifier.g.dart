// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 认证状态 Provider：`AuthState` 的唯一写入者（AGENTS.md §7）。
///
/// 同步 `Notifier<AuthState>` + `keepAlive`——`appRedirect` 是同步纯函数，
/// 只认 `AuthUnknown` / `AuthSignedOut` / `AuthSignedIn` 三态，禁止
/// `AsyncNotifier`。异步副作用都在方法内完成，state 变化经
/// refreshListenable 触发守卫重跑。

@ProviderFor(AuthNotifier)
final authNotifierProvider = AuthNotifierProvider._();

/// 认证状态 Provider：`AuthState` 的唯一写入者（AGENTS.md §7）。
///
/// 同步 `Notifier<AuthState>` + `keepAlive`——`appRedirect` 是同步纯函数，
/// 只认 `AuthUnknown` / `AuthSignedOut` / `AuthSignedIn` 三态，禁止
/// `AsyncNotifier`。异步副作用都在方法内完成，state 变化经
/// refreshListenable 触发守卫重跑。
final class AuthNotifierProvider
    extends $NotifierProvider<AuthNotifier, AuthState> {
  /// 认证状态 Provider：`AuthState` 的唯一写入者（AGENTS.md §7）。
  ///
  /// 同步 `Notifier<AuthState>` + `keepAlive`——`appRedirect` 是同步纯函数，
  /// 只认 `AuthUnknown` / `AuthSignedOut` / `AuthSignedIn` 三态，禁止
  /// `AsyncNotifier`。异步副作用都在方法内完成，state 变化经
  /// refreshListenable 触发守卫重跑。
  AuthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authNotifierHash();

  @$internal
  @override
  AuthNotifier create() => AuthNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthState>(value),
    );
  }
}

String _$authNotifierHash() => r'd5cebec5090c6532525a44cacb7e8a7a9477a50e';

/// 认证状态 Provider：`AuthState` 的唯一写入者（AGENTS.md §7）。
///
/// 同步 `Notifier<AuthState>` + `keepAlive`——`appRedirect` 是同步纯函数，
/// 只认 `AuthUnknown` / `AuthSignedOut` / `AuthSignedIn` 三态，禁止
/// `AsyncNotifier`。异步副作用都在方法内完成，state 变化经
/// refreshListenable 触发守卫重跑。

abstract class _$AuthNotifier extends $Notifier<AuthState> {
  AuthState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AuthState, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthState, AuthState>,
              AuthState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 认证仓储 Provider：生产 [PatAuthRepository]，测试可整体 override。

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

/// 认证仓储 Provider：生产 [PatAuthRepository]，测试可整体 override。

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// 认证仓储 Provider：生产 [PatAuthRepository]，测试可整体 override。
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'452e80133d24b95b25d74423c9f60b95a9e79b13';

/// 认证数据源 Provider：M2 假数据源，M4 换 `cna_api.UsersApi` 实现。

@ProviderFor(authDataSource)
final authDataSourceProvider = AuthDataSourceProvider._();

/// 认证数据源 Provider：M2 假数据源，M4 换 `cna_api.UsersApi` 实现。

final class AuthDataSourceProvider
    extends $FunctionalProvider<AuthDataSource, AuthDataSource, AuthDataSource>
    with $Provider<AuthDataSource> {
  /// 认证数据源 Provider：M2 假数据源，M4 换 `cna_api.UsersApi` 实现。
  AuthDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authDataSourceHash();

  @$internal
  @override
  $ProviderElement<AuthDataSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthDataSource create(Ref ref) {
    return authDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthDataSource>(value),
    );
  }
}

String _$authDataSourceHash() => r'076e68f819c05fe7e8744be71eb6d10737c45bd1';
