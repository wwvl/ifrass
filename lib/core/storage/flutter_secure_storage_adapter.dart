import 'package:cna/core/storage/secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// [SecureStorage] 的生产实现：Android Keystore / iOS Keychain。
///
/// 单一 key 收口，token 不落 shared_preferences / 文件 / 日志（AGENTS.md §11）。
class FlutterSecureStorageAdapter implements SecureStorage {
  /// 创建适配器。
  new({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// token 在底层存储中的唯一 key。
  static const String _tokenKey = 'auth.token';

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}
