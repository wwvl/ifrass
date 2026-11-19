import 'package:cna/core/error/failure.dart';
import 'package:cna/core/network/unauthorized_handler.dart';
import 'package:cna/core/storage/secure_storage_provider.dart';
import 'package:cna/features/auth/data/datasource/auth_data_source.dart';
import 'package:cna/features/auth/data/datasource/fake_auth_data_source.dart';
import 'package:cna/features/auth/data/repo_impl/pat_auth_repository.dart';
import 'package:cna/features/auth/domain/auth_repository.dart';
import 'package:cna/features/auth/domain/auth_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_notifier.g.dart';

/// 认证状态 Provider：`AuthState` 的唯一写入者（AGENTS.md §7）。
///
/// 同步 `Notifier<AuthState>` + `keepAlive`——`appRedirect` 是同步纯函数，
/// 只认 `AuthUnknown` / `AuthSignedOut` / `AuthSignedIn` 三态，禁止
/// `AsyncNotifier`。异步副作用都在方法内完成，state 变化经
/// refreshListenable 触发守卫重跑。
@Riverpod(keepAlive: true, name: 'authNotifierProvider')
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => const AuthUnknown();

  /// 启动恢复：splash 触发一次；网络失败抛出（splash 重试），401 走唯一失效入口。
  Future<void> restore() async {
    try {
      state = await ref.read(authRepositoryProvider).restore();
    } on FailureUnauthorized {
      await handleUnauthorized(
        repository: ref.read(authRepositoryProvider),
        onInvalidated: () => state = const AuthSignedOut(),
      );
    }
  }

  /// 登录：成功落定 [AuthSignedIn] 并返回 null；失败返回 [Failure]
  /// （登录页差异化文案），state 不变——守卫回跳只依赖成功路径。
  Future<Failure?> signIn(String token) async {
    final failure = await ref.read(authRepositoryProvider).signIn(token);
    if (failure != null) {
      return failure;
    }
    state = AuthSignedIn(token);
    return null;
  }

  /// 用户主动登出：清 token + 复位状态；守卫随后送回 `/login`。
  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AuthSignedOut();
  }

  /// 401 复位（唯一入口 [handleUnauthorized] 的状态回调）：清 token + 复位状态。
  /// 测试与 M4 interceptor 可直接调用本方法完成「token 清除 + SignedOut」。
  Future<void> invalidate() async {
    await ref.read(authRepositoryProvider).invalidate();
    state = const AuthSignedOut();
  }
}

/// 认证仓储 Provider：生产 [PatAuthRepository]，测试可整体 override。
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return PatAuthRepository(
    storage: ref.watch(secureStorageProvider),
    dataSource: ref.watch(authDataSourceProvider),
  );
}

/// 认证数据源 Provider：M2 假数据源，M4 换 `cna_api.UsersApi` 实现。
@Riverpod(keepAlive: true)
AuthDataSource authDataSource(Ref ref) => FakeAuthDataSource();
