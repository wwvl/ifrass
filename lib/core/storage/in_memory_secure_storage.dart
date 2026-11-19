import 'package:cna/core/storage/secure_storage.dart';

/// [SecureStorage] 的内存 Fake：测试与开发装配用，进程结束即失。
/// 生产装配禁止使用（token 必须落 Keystore / Keychain）。
class InMemorySecureStorage implements SecureStorage {
  /// 创建空存储。
  new();

  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async {
    _token = token;
  }

  @override
  Future<void> deleteToken() async {
    _token = null;
  }
}
