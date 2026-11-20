import 'package:cna/core/error/failure.dart';
import 'package:cna/core/network/interceptors/auth_interceptor.dart';
import 'package:cna/core/network/interceptors/error_mapping_interceptor.dart';
import 'package:cna/core/network/interceptors/logging_interceptor.dart';
import 'package:cna/core/network/interceptors/retry_interceptor.dart';
import 'package:cna/core/network/interceptors/unauthorized_interceptor.dart';
import 'package:cna/core/storage/in_memory_secure_storage.dart';
import 'package:cna/core/storage/secure_storage.dart';
import 'package:cna/features/auth/domain/auth_repository.dart';
import 'package:cna/features/auth/domain/auth_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/stub_adapter.dart';

/// 五拦截器集成行为（AGENTS.md §5）：Auth 头只注入一次、Retry 白名单矩阵
/// （POST/PATCH 零重试、transformTimeout / connectionError 语义、
/// Retry-After）、ErrorMapping 五类映射、401 单一入口、日志脱敏。
/// 全程 stub adapter，不打真实网络（§5 测试纪律）。
void main() {
  final storage = InMemorySecureStorage();

  Future<void> setToken(String? token) async {
    if (token == null) {
      await storage.deleteToken();
    } else {
      await storage.writeToken(token);
    }
  }

  Future<DioException> expectFailure(Future<Object?> future) async {
    try {
      await future;
    } on DioException catch (error) {
      return error;
    }
    fail('expected DioException');
  }

  group('Auth 拦截器（顺序 1）', () {
    test('从 readToken 注入 Bearer 头 + Accept', () async {
      await setToken('tok-123');
      final adapter = StubAdapter(
        (_, _) async => const StubReply(status: 200, body: {'ok': 1}),
      );
      final dio = buildTestDio(adapter: adapter, readToken: storage.readToken);

      await dio.get<dynamic>('/x');

      expect(adapter.count, 1);
      expect(
        adapter.received.single.headers['Authorization'],
        'Bearer tok-123',
      );
      expect(adapter.received.single.headers['Accept'], 'application/json');
    });

    test('逐请求已带 Authorization 时不注入（登录校验场景，只注入一次）', () async {
      var readCount = 0;
      final adapter = StubAdapter(
        (_, _) async => const StubReply(status: 200, body: {'ok': 1}),
      );
      final dio = buildTestDio(
        adapter: adapter,
        readToken: () async {
          readCount++;
          return 'stored-token';
        },
      );

      await dio.get<dynamic>(
        '/x',
        options: Options(headers: {'Authorization': 'Bearer candidate'}),
      );

      expect(readCount, 0, reason: '已带头则不读 storage');
      expect(
        adapter.received.single.headers['Authorization'],
        'Bearer candidate',
      );
    });

    test('无 token 时不注入 Authorization，Accept 照常', () async {
      await setToken(null);
      final adapter = StubAdapter(
        (_, _) async => const StubReply(status: 200, body: {'ok': 1}),
      );
      final dio = buildTestDio(adapter: adapter, readToken: storage.readToken);

      await dio.get<dynamic>('/x');

      expect(
        adapter.received.single.headers.containsKey('Authorization'),
        isFalse,
      );
      expect(adapter.received.single.headers['Accept'], 'application/json');
    });
  });

  group('Retry 拦截器（顺序 2）', () {
    test('GET 500 后成功：重试 1 次并 resolve（重放走同一 Dio 完整链）', () async {
      var tokenSeen = false;
      final adapter = StubAdapter((options, attempt) async {
        if (attempt == 0) {
          return const StubReply(status: 500, body: 'down');
        }
        tokenSeen = options.headers['Authorization'] != null;
        return const StubReply(status: 200, body: {'ok': 1});
      });
      final dio = buildTestDio(adapter: adapter, readToken: () async => 'tok');

      final result = await dio.get<dynamic>('/x');

      expect(result.statusCode, 200);
      expect(adapter.count, 2);
      expect(tokenSeen, isTrue, reason: '重放仍带 Authorization');
    });

    test('GET 持续 5xx：最多 3 次重试（4 次请求）后抛 FailureHttp', () async {
      final adapter = StubAdapter(
        (_, _) async => const StubReply(status: 503, body: 'down'),
      );
      final dio = buildTestDio(adapter: adapter, readToken: () async => null);

      final error = await expectFailure(dio.get<dynamic>('/x'));

      expect(adapter.count, 4);
      expect(error.error, isA<FailureHttp>());
      expect((error.error! as FailureHttp).status, 503);
    });

    test('408 / 429 也在重试白名单', () async {
      for (final status in <int>[408, 429]) {
        var calls = 0;
        final adapter = StubAdapter((_, attempt) async {
          calls = attempt + 1;
          if (attempt == 0) {
            return StubReply(status: status, body: 'slow');
          }
          return const StubReply(status: 200, body: {'ok': 1});
        });
        final dio = buildTestDio(adapter: adapter, readToken: () async => null);

        await dio.get<dynamic>('/x');

        expect(calls, 2, reason: 'status=$status');
      }
    });

    test('401 不重试：仅 1 次请求且触发 401 失效入口', () async {
      await setToken('stale');
      var invalidated = 0;
      final adapter = StubAdapter(
        (_, _) async => const StubReply(status: 401, body: 'expired'),
      );
      final dio = buildTestDio(
        adapter: adapter,
        readToken: storage.readToken,
        repository: () => _RepoStub(storage),
        onInvalidated: () => invalidated++,
      );

      final error = await expectFailure(dio.get<dynamic>('/x'));

      expect(adapter.count, 1, reason: '401 不在重试白名单');
      expect(error.error, isA<FailureUnauthorized>());
      expect(invalidated, 1);
      expect(await storage.readToken(), isNull, reason: '401 清 token');
    });

    test('404 / badCertificate / transformTimeout 不重试', () async {
      final notFound = StubAdapter(
        (_, _) async => const StubReply(status: 404, body: 'no'),
      );
      final dio = buildTestDio(adapter: notFound, readToken: () async => null);
      await expectFailure(dio.get<dynamic>('/x'));
      expect(notFound.count, 1);

      final transform = StubAdapter(
        (options, _) async => throw DioException.transformTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: options,
        ),
      );
      final dioT = buildTestDio(
        adapter: transform,
        readToken: () async => null,
      );
      await expectFailure(dioT.get<dynamic>('/x'));
      expect(transform.count, 1, reason: 'transformTimeout 不重试（§5）');

      final badCert = StubAdapter(
        (options, _) async =>
            throw DioException.badCertificate(requestOptions: options),
      );
      final dioC = buildTestDio(adapter: badCert, readToken: () async => null);
      await expectFailure(dioC.get<dynamic>('/x'));
      expect(badCert.count, 1);
    });

    test('POST / PATCH 5xx 零重试（防重复创建）', () async {
      for (final method in <String>['post', 'patch']) {
        final adapter = StubAdapter(
          (_, _) async => const StubReply(status: 500, body: 'down'),
        );
        final dio = buildTestDio(adapter: adapter, readToken: () async => null);

        await expectFailure(
          dio.request<dynamic>('/x', options: Options(method: method)),
        );

        expect(adapter.count, 1, reason: 'method=$method');
      }
    });

    test('connectionError：GET 重试、POST 不重发（§5 dio 5.11 语义）', () async {
      DioException connectionError(RequestOptions options) =>
          DioException.connectionError(
            requestOptions: options,
            reason: 'connection closed before full header was received',
          );

      final getAdapter = StubAdapter((options, attempt) async {
        if (attempt == 0) {
          throw connectionError(options);
        }
        return const StubReply(status: 200, body: {'ok': 1});
      });
      final getDio = buildTestDio(
        adapter: getAdapter,
        readToken: () async => null,
      );
      await getDio.get<dynamic>('/x');
      expect(getAdapter.count, 2, reason: 'GET 网络错误可重试');

      final postAdapter = StubAdapter(
        (options, _) async => throw connectionError(options),
      );
      final postDio = buildTestDio(
        adapter: postAdapter,
        readToken: () async => null,
      );
      final postError = await expectFailure(postDio.post<dynamic>('/x'));
      expect(postAdapter.count, 1, reason: 'POST 连接错误也不重发');
      expect(postError.error, isA<FailureNetwork>());
    });

    test('Retry-After 秒数优先指数退避，且不截短合法长延迟', () async {
      for (final seconds in <int>[1, 500]) {
        final adapter = StubAdapter((_, attempt) async {
          if (attempt == 0) {
            return StubReply(
              status: 429,
              body: 'rate',
              headers: {
                'retry-after': <String>['$seconds'],
              },
            );
          }
          return const StubReply(status: 200, body: {'ok': 1});
        });
        final waits = <Duration>[];
        final dio = _buildRetryDio(
          adapter,
          backoffBase: const Duration(seconds: 10),
          wait: (duration) async => waits.add(duration),
        );

        await dio.get<dynamic>('/x');

        expect(adapter.count, 2);
        expect(waits, [Duration(seconds: seconds)]);
      }
    });

    test(
      'Retry-After HTTP date waits until that instant using injected clock',
      () async {
        final adapter = StubAdapter((_, attempt) async {
          if (attempt == 0) {
            return const StubReply(
              status: 503,
              body: 'maintenance',
              headers: {
                'retry-after': <String>['Fri, 20 Nov 2026 12:00:10 GMT'],
              },
            );
          }
          return const StubReply(status: 200, body: {'ok': 1});
        });
        final waits = <Duration>[];
        final dio = _buildRetryDio(
          adapter,
          backoffBase: const Duration(seconds: 30),
          now: () => DateTime.utc(2026, 11, 20, 12),
          wait: (duration) async => waits.add(duration),
        );

        await dio.get<dynamic>('/x');

        expect(adapter.count, 2);
        expect(waits, [const Duration(seconds: 10)]);
      },
    );

    test('过期或非法 Retry-After 分别采用零延时或指数退避', () async {
      for (final header in <String>[
        'Thu, 19 Nov 2026 12:00:00 GMT',
        'not a date',
        '-1',
      ]) {
        final adapter = StubAdapter((_, attempt) async {
          if (attempt == 0) {
            return StubReply(
              status: 503,
              body: 'retry',
              headers: {
                'retry-after': <String>[header],
              },
            );
          }
          return const StubReply(status: 200, body: {'ok': 1});
        });
        final waits = <Duration>[];
        final dio = _buildRetryDio(
          adapter,
          backoffBase: const Duration(seconds: 2),
          now: () => DateTime.utc(2026, 11, 20, 12),
          wait: (duration) async => waits.add(duration),
        );

        await dio.get<dynamic>('/x');

        final expected = header.startsWith('Thu,')
            ? Duration.zero
            : const Duration(seconds: 2);
        expect(waits, [expected], reason: 'Retry-After=$header');
      }
    });

    test('带 Retry-After 的 401 仍不重试', () async {
      final unauthorized = StubAdapter(
        (_, _) async => const StubReply(
          status: 401,
          body: 'expired',
          headers: {
            'retry-after': <String>['1'],
          },
        ),
      );
      final dio2 = buildTestDio(
        adapter: unauthorized,
        readToken: () async => null,
        repository: () => _RepoStub(InMemorySecureStorage()),
      );

      await expectFailure(dio2.get<dynamic>('/x'));

      expect(unauthorized.count, 1, reason: '401 带 Retry-After 也不重试');
    });
  });

  group('ErrorMapping 拦截器（顺序 3）', () {
    test(
      'HTTP 4xx/5xx → FailureHttp 保留 status；401 → FailureUnauthorized',
      () async {
        final adapter = StubAdapter((_, attempt) async {
          // attempt 0/1/2 为 500（被 Retry 重试），耗尽后按 attempt 3 返回 403。
          if (attempt < 3) {
            return const StubReply(status: 500, body: 'down');
          }
          return const StubReply(status: 403, body: 'scope insufficient');
        });
        final dio = buildTestDio(adapter: adapter, readToken: () async => null);

        final error = await expectFailure(dio.get<dynamic>('/x'));

        expect(adapter.count, 4);
        expect(error.error, isA<FailureHttp>());
        final failure = error.error! as FailureHttp;
        expect(failure.status, 403);
        expect(failure.body, 'scope insufficient');
      },
    );

    test('网络异常 → FailureNetwork；日志行记最终形态（证明 Log 在映射后）', () async {
      final lines = <String>[];
      var invalidated = 0;
      final adapter = StubAdapter(
        (options, _) async => throw DioException.connectionError(
          requestOptions: options,
          reason: 'closed',
        ),
      );
      final dio = buildTestDio(
        adapter: adapter,
        readToken: () async => null,
        sink: lines.add,
        repository: () => _RepoStub(InMemorySecureStorage()),
        onInvalidated: () => invalidated++,
      );

      final error = await expectFailure(dio.get<dynamic>('/x'));

      expect(error.error, isA<FailureNetwork>());
      expect(adapter.count, 4, reason: 'GET 网络错误耗尽 3 次重试');
      expect(invalidated, 0, reason: '非 401 不触发失效入口');
      expect(lines, hasLength(1), reason: '重试耗尽后只记录一次最终失败');
      expect(
        lines.last,
        contains('FailureNetwork'),
        reason: 'Log 在映射后运行（记最终形态）',
      );
    });
  });

  group('日志脱敏（AGENTS.md §11）', () {
    test('日志行不含 Authorization / token，含 method/path/status', () async {
      const secret = 'super-secret-token';
      final lines = <String>[];
      final adapter = StubAdapter(
        (_, _) async => const StubReply(status: 200, body: {'ok': 1}),
      );
      final dio = buildTestDio(
        adapter: adapter,
        readToken: () async => secret,
        sink: lines.add,
      );

      await dio.get<dynamic>('/repos?search=cnb');

      expect(lines, hasLength(1));
      expect(lines.single, contains('GET'));
      expect(lines.single, contains('/repos'));
      expect(lines.single, contains('200'));
      expect(lines.single.contains('Authorization'), isFalse);
      expect(lines.single.contains('Bearer'), isFalse);
      expect(lines.single.contains(secret), isFalse);

      final failing = StubAdapter(
        (_, _) async => const StubReply(status: 401, body: 'expired'),
      );
      final dio2 = buildTestDio(
        adapter: failing,
        readToken: () async => secret,
        sink: lines.add,
        repository: () => _RepoStub(InMemorySecureStorage()),
      );
      await expectFailure(dio2.get<dynamic>('/user'));

      final errorLine = lines.last;
      expect(errorLine.contains('401'), isTrue);
      expect(errorLine.contains('FailureUnauthorized'), isTrue);
      expect(errorLine.contains(secret), isFalse);
      expect(errorLine.contains('Bearer'), isFalse);
    });
  });
}

/// retry clock/wait 注入，验证精确延时而不让测试实际等待。
Dio _buildRetryDio(
  StubAdapter adapter, {
  required Duration backoffBase,
  DateTime Function()? now,
  Future<void> Function(Duration)? wait,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
    ..httpClientAdapter = adapter;
  dio.interceptors.addAll([
    AuthInterceptor(readToken: () async => null),
    RetryInterceptor(dio: dio, backoffBase: backoffBase, now: now, wait: wait),
    const ErrorMappingInterceptor(),
    UnauthorizedInterceptor(
      repository: () => _RepoStub(InMemorySecureStorage()),
      onInvalidated: () {},
    ),
    LoggingInterceptor(),
  ]);
  return dio;
}

/// 记录失效动作的 AuthRepository 桩（仅 401 入口测试用）。
class _RepoStub implements AuthRepository {
  new(this._storage);

  final SecureStorage _storage;
  int invalidateCount = 0;

  @override
  Future<void> invalidate() async {
    invalidateCount++;
    await _storage.deleteToken();
  }

  @override
  Future<Failure?> signIn(String token) => throw UnimplementedError();

  @override
  Future<AuthState> restore() => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();
}
