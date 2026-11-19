// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secure_storage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 全局 SecureStorage Provider（AGENTS.md §7 核心 provider）。
///
/// 生产返回 Keystore / Keychain 实现；测试以
/// `secureStorageProvider.overrideWithValue(InMemorySecureStorage())` 替换。

@ProviderFor(secureStorage)
final secureStorageProvider = SecureStorageProvider._();

/// 全局 SecureStorage Provider（AGENTS.md §7 核心 provider）。
///
/// 生产返回 Keystore / Keychain 实现；测试以
/// `secureStorageProvider.overrideWithValue(InMemorySecureStorage())` 替换。

final class SecureStorageProvider
    extends $FunctionalProvider<SecureStorage, SecureStorage, SecureStorage>
    with $Provider<SecureStorage> {
  /// 全局 SecureStorage Provider（AGENTS.md §7 核心 provider）。
  ///
  /// 生产返回 Keystore / Keychain 实现；测试以
  /// `secureStorageProvider.overrideWithValue(InMemorySecureStorage())` 替换。
  SecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secureStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secureStorageHash();

  @$internal
  @override
  $ProviderElement<SecureStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SecureStorage create(Ref ref) {
    return secureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SecureStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SecureStorage>(value),
    );
  }
}

String _$secureStorageHash() => r'f0182504226aaec1edbf7e79d0d68cf860492efc';
