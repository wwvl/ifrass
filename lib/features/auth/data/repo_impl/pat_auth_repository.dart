import 'package:cna/core/error/failure.dart';
import 'package:cna/core/storage/secure_storage.dart';
import 'package:cna/features/auth/data/datasource/auth_data_source.dart';
import 'package:cna/features/auth/domain/auth_repository.dart';
import 'package:cna/features/auth/domain/auth_state.dart';

/// 一期 PAT 认证仓储实现（AGENTS.md §6）。
///
/// token 来源维度收口在此：二期换 `OAuthAuthRepository` 时本文件的
/// 消费方（UI / state / 路由）一行不动。401 不在本层处理——原样抛给上层，
/// 由 `AuthNotifier` 经唯一失效入口复位（AGENTS.md §5）。
class PatAuthRepository implements AuthRepository {
  /// 创建 PAT 仓储。
  new({required this.storage, required this.dataSource});

  /// token 持久化通道。
  final SecureStorage storage;

  /// 校验数据源（M2 假实现 / M4 远程实现）。
  final AuthDataSource dataSource;

  bool _invalidated = false;
  Future<void>? _invalidationFuture;

  @override
  Future<Failure?> signIn(String token) async {
    try {
      await dataSource.verify(token);
    } on Failure catch (failure) {
      return failure;
    }
    await storage.writeToken(token);
    _invalidated = false;
    return null;
  }

  @override
  Future<AuthState> restore() async {
    final token = await storage.readToken();
    if (token == null || token.isEmpty) {
      return const AuthSignedOut();
    }
    await dataSource.verify(token);
    return AuthSignedIn(token);
  }

  @override
  Future<void> signOut() => invalidate();

  @override
  Future<void> invalidate() {
    if (_invalidated) return _invalidationFuture ?? Future<void>.value();
    return _invalidationFuture ??= _clearToken();
  }

  Future<void> _clearToken() async {
    _invalidated = true;
    try {
      await storage.deleteToken();
    } on Object {
      _invalidated = false;
      rethrow;
    } finally {
      _invalidationFuture = null;
    }
  }
}
