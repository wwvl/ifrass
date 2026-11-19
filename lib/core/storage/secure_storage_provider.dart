import 'package:cna/core/storage/flutter_secure_storage_adapter.dart';
import 'package:cna/core/storage/secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_provider.g.dart';

/// 全局 SecureStorage Provider（AGENTS.md §7 核心 provider）。
///
/// 生产返回 Keystore / Keychain 实现；测试以
/// `secureStorageProvider.overrideWithValue(InMemorySecureStorage())` 替换。
@Riverpod(keepAlive: true)
SecureStorage secureStorage(Ref ref) => FlutterSecureStorageAdapter();
