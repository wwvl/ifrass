import 'package:cna/core/error/failure.dart';
import 'package:cna/core/network/network_providers.dart';
import 'package:cna/core/providers/data_source_overrides.dart';
import 'package:cna/core/storage/in_memory_secure_storage.dart';
import 'package:cna/core/storage/secure_storage.dart';
import 'package:cna/core/storage/secure_storage_provider.dart';
import 'package:cna/features/auth/domain/auth_state.dart';
import 'package:cna/features/auth/presentation/state/auth_notifier.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/network/helpers/stub_adapter.dart';

class _CountingSecureStorage implements SecureStorage {
  final InMemorySecureStorage _storage = InMemorySecureStorage();
  int deleteCount = 0;

  @override
  Future<String?> readToken() => _storage.readToken();

  @override
  Future<void> writeToken(String token) => _storage.writeToken(token);

  @override
  Future<void> deleteToken() async {
    deleteCount++;
    await _storage.deleteToken();
  }
}

void main() {
  late _CountingSecureStorage storage;
  late ProviderContainer container;

  setUp(() {
    storage = _CountingSecureStorage();
    container = ProviderContainer.test(
      overrides: [
        ...dataSourceOverrides(),
        secureStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);
  });

  StubAdapter attachAdapter(
    Future<StubReply> Function(RequestOptions, int) handler,
  ) {
    final adapter = StubAdapter(handler);
    container.read(dioProvider).httpClientAdapter = adapter;
    return adapter;
  }

  test('真实 remote provider 恢复成功并复用唯一 Dio 与存储 token', () async {
    await storage.writeToken('stored-token');
    final adapter = attachAdapter(
      (_, _) async => const StubReply(
        status: 200,
        body: {'id': 'user-1', 'nickname': 'CNB developer'},
      ),
    );

    await container.read(authNotifierProvider.notifier).restore();

    expect(
      container.read(apiClientProvider).dio,
      same(container.read(dioProvider)),
    );
    expect(
      container.read(authNotifierProvider),
      const AuthSignedIn('stored-token'),
    );
    expect(await storage.readToken(), 'stored-token');
    expect(storage.deleteCount, 0);
    expect(adapter.count, 1);
    expect(adapter.received.single.path, '/user');
    expect(adapter.received.single.method, 'GET');
    expect(
      adapter.received.single.headers['Authorization'],
      'Bearer stored-token',
    );
    expect(adapter.received.single.headers['Accept'], 'application/json');
  });

  test('restore 收到 Dio 401：SignedOut、只清一次存储且不重试', () async {
    await storage.writeToken('expired-token');
    final adapter = attachAdapter(
      (_, _) async => const StubReply(status: 401, body: 'expired'),
    );

    await container.read(authNotifierProvider.notifier).restore();

    expect(container.read(authNotifierProvider), const AuthSignedOut());
    expect(await storage.readToken(), isNull);
    expect(storage.deleteCount, 1);
    expect(adapter.count, 1, reason: '401 不重试');
  });

  test('restore 网络连接失败：保持 Unknown 与 token，重试仅由 Dio 执行', () async {
    await storage.writeToken('stored-token');
    final adapter = attachAdapter(
      (options, _) async => throw DioException.connectionError(
        requestOptions: options,
        reason: 'stub connection is offline',
      ),
    );

    await expectLater(
      container.read(authNotifierProvider.notifier).restore(),
      throwsA(isA<FailureNetwork>()),
    );

    expect(container.read(authNotifierProvider), const AuthUnknown());
    expect(await storage.readToken(), 'stored-token');
    expect(storage.deleteCount, 0);
    expect(adapter.count, 4, reason: '首次请求 + Dio 最多三次重试');
  });

  test('真实解码的用户字段类型漂移：FailureParse，不保存候选 token 或改认证态', () async {
    final adapter = attachAdapter(
      (_, _) async => const StubReply(status: 200, body: {'id': 7}),
    );
    final initialState = container.read(authNotifierProvider);

    final failure = await container
        .read(authNotifierProvider.notifier)
        .signIn('candidate-token');

    expect(failure, isA<FailureParse>());
    expect(container.read(authNotifierProvider), initialState);
    expect(await storage.readToken(), isNull);
    expect(storage.deleteCount, 0);
    expect(adapter.count, 1, reason: '200 后 DTO 类型漂移不会重试');
    expect(adapter.received.single.path, '/user');
    expect(
      adapter.received.single.headers['Authorization'],
      'Bearer candidate-token',
    );
  });

  test('候选 token 被拒绝后仍可登录；新会话再次 401 会再次清除', () async {
    var sessionExpired = false;
    final adapter = attachAdapter((options, _) async {
      final authorization = options.headers['Authorization'];
      if (authorization == 'Bearer rejected-token' || sessionExpired) {
        return const StubReply(status: 401, body: 'expired');
      }
      expect(authorization, 'Bearer fresh-token');
      return const StubReply(
        status: 200,
        body: {'id': 'user-1', 'nickname': 'CNB developer'},
      );
    });
    final notifier = container.read(authNotifierProvider.notifier);
    await notifier.restore();
    expect(container.read(authNotifierProvider), const AuthSignedOut());
    expect(adapter.count, 0, reason: '无本地 token 不发送恢复请求');

    final rejected = await notifier.signIn('rejected-token');

    expect(rejected, isA<FailureUnauthorized>());
    expect(container.read(authNotifierProvider), const AuthSignedOut());
    expect(await storage.readToken(), isNull);
    expect(storage.deleteCount, 1);
    expect(adapter.count, 1);

    final signedIn = await notifier.signIn('fresh-token');

    expect(signedIn, isNull);
    expect(
      container.read(authNotifierProvider),
      const AuthSignedIn('fresh-token'),
    );
    expect(await storage.readToken(), 'fresh-token');
    expect(storage.deleteCount, 1);
    expect(adapter.count, 2);

    sessionExpired = true;
    await expectLater(
      container.read(apiClientProvider).users.getUserInfo(),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'mapped failure',
          isA<FailureUnauthorized>(),
        ),
      ),
    );
    await container.pump();

    expect(container.read(authNotifierProvider), const AuthSignedOut());
    expect(await storage.readToken(), isNull);
    expect(storage.deleteCount, 2, reason: '新会话复位后必须允许再次清除');
    expect(adapter.count, 3, reason: '每次 401 都不重试');
    expect(
      adapter.received.last.headers['Authorization'],
      'Bearer fresh-token',
      reason: '已登录请求从 SecureStorage 读取，而非沿用候选 token',
    );
  });
}
