/// token 的唯一持久化通道（AGENTS.md §6 / §11）。
///
/// 实现二选一：`FlutterSecureStorageAdapter`（Keystore / Keychain，生产）与
/// `InMemorySecureStorage`（测试 / 开发装配）。token 禁止进
/// `shared_preferences`、普通文件与日志——任何代码不得绕过本接口存取 token。
abstract interface class SecureStorage {
  /// 读取当前 token；未存储时返回 null。
  Future<String?> readToken();

  /// 写入（覆盖）当前 token。
  Future<void> writeToken(String token);

  /// 清除当前 token；不存在时为幂等空操作。
  Future<void> deleteToken();
}
