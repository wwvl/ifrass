// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 远程认证数据源：复用全局 ApiClient 的 UsersApi。

@ProviderFor(remoteAuthDataSource)
final remoteAuthDataSourceProvider = RemoteAuthDataSourceProvider._();

/// 远程认证数据源：复用全局 ApiClient 的 UsersApi。

final class RemoteAuthDataSourceProvider
    extends $FunctionalProvider<AuthDataSource, AuthDataSource, AuthDataSource>
    with $Provider<AuthDataSource> {
  /// 远程认证数据源：复用全局 ApiClient 的 UsersApi。
  RemoteAuthDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteAuthDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteAuthDataSourceHash();

  @$internal
  @override
  $ProviderElement<AuthDataSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthDataSource create(Ref ref) {
    return remoteAuthDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthDataSource>(value),
    );
  }
}

String _$remoteAuthDataSourceHash() =>
    r'8e36f98725544573ece74a65b8937fcd497750f3';
