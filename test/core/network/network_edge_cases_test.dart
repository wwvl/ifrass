import 'dart:convert';

import 'package:cna/core/error/failure.dart';
import 'package:cna/features/auth/domain/auth_repository.dart';
import 'package:cna/features/auth/domain/auth_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/stub_adapter.dart';

void main() {
  for (final (type, status) in [
    (DioExceptionType.transformTimeout, 503),
    (DioExceptionType.badResponse, 600),
  ]) {
    test('$type with status $status is never retried', () async {
      final adapter = StubAdapter((options, _) async {
        throw DioException(
          requestOptions: options,
          type: type,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: status,
          ),
        );
      });
      final dio = buildTestDio(adapter: adapter);
      addTearDown(dio.close);

      final error = await _captureError(dio.get<dynamic>('/repos'));

      expect(error.type, type);
      expect(adapter.count, 1);
    });
  }

  test('a replay ending in 401 invalidates and logs exactly once', () async {
    final repository = _AuthRepositorySpy();
    var invalidated = 0;
    final lines = <String>[];
    final adapter = StubAdapter((_, attempt) async {
      return StubReply(status: attempt == 0 ? 503 : 401, body: 'unavailable');
    });
    final dio = buildTestDio(
      adapter: adapter,
      repository: () => repository,
      onInvalidated: () => invalidated++,
      sink: lines.add,
    );
    addTearDown(dio.close);

    final error = await _captureError(dio.get<dynamic>('/user'));

    expect(error.error, isA<FailureUnauthorized>());
    expect(adapter.count, 2);
    expect(repository.invalidateCount, 1);
    expect(invalidated, 1);
    expect(lines, hasLength(1));
    final record = jsonDecode(lines.single) as Map<String, dynamic>;
    expect(record['status'], 401);
    expect(record['failureType'], 'FailureUnauthorized');
  });

  test('retry exhaustion logs one final failure after four attempts', () async {
    final lines = <String>[];
    final adapter = StubAdapter(
      (_, _) async => const StubReply(status: 503, body: 'unavailable'),
    );
    final dio = buildTestDio(adapter: adapter, sink: lines.add);
    addTearDown(dio.close);

    final error = await _captureError(dio.get<dynamic>('/repos'));

    expect(adapter.count, 4);
    expect(error.error, isA<FailureHttp>());
    expect(lines, hasLength(1));
    final record = jsonDecode(lines.single) as Map<String, dynamic>;
    expect(record['failureType'], 'FailureHttp');
    expect(record['status'], 503);
  });

  testWidgets('cancellation clears a long Retry-After timer', (tester) async {
    final token = CancelToken();
    final lines = <String>[];
    final adapter = StubAdapter(
      (_, _) async => const StubReply(
        status: 429,
        body: 'limited',
        headers: {
          'retry-after': ['86400'],
        },
      ),
    );
    final dio = buildTestDio(adapter: adapter, sink: lines.add);
    addTearDown(dio.close);
    final result = _captureError(
      dio.get<dynamic>('/repos', cancelToken: token),
    );
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(adapter.count, 1);

    token.cancel('page disposed');
    await tester.pump();
    final error = await result;

    expect(error.type, DioExceptionType.cancel);
    expect(adapter.count, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(adapter.count, 1);
    // The widget test binding also rejects any pending Retry-After timer.
  });

  test(
    'structured error logs omit query, credentials and failure text',
    () async {
      const secret = 'credential-that-must-stay-private';
      final lines = <String>[];
      final adapter = StubAdapter((options, _) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 422,
            data: {'token': secret},
          ),
          error: const FailureParse('token=$secret'),
          message: secret,
        );
      });
      final dio = buildTestDio(
        adapter: adapter,
        readToken: () async => secret,
        sink: lines.add,
      );
      addTearDown(dio.close);

      await _captureError(
        dio.get<dynamic>(
          '/user?token=$secret',
          data: {'password': secret},
          options: Options(headers: {'X-Api-Key': secret}),
        ),
      );

      expect(lines, hasLength(1));
      expect(lines.single, isNot(contains(secret)));
      expect(lines.single, isNot(contains('Authorization')));
      expect(lines.single, isNot(contains('password')));
      final record = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(
        record.keys,
        unorderedEquals([
          'method',
          'path',
          'status',
          'duration',
          'failureType',
        ]),
      );
      expect(record['method'], 'GET');
      expect(record['path'], '/user');
      expect(record['status'], 422);
      expect(record['duration'], isNonNegative);
      expect(record['failureType'], 'FailureParse');
    },
  );

  test('success logs contain path without URI query or authority', () async {
    final lines = <String>[];
    final adapter = StubAdapter(
      (_, _) async => const StubReply(status: 200, body: {'ok': true}),
    );
    final dio = buildTestDio(adapter: adapter, sink: lines.add);
    addTearDown(dio.close);

    await dio.get<dynamic>('/repos?token=secret');

    final record = jsonDecode(lines.single) as Map<String, dynamic>;
    expect(record['path'], '/repos');
    expect(record['status'], 200);
    expect(record['failureType'], isNull);
    expect(lines.single, isNot(contains('secret')));
    expect(lines.single, isNot(contains('api.example.com')));
  });
}

Future<DioException> _captureError(Future<Object?> future) async {
  try {
    await future;
  } on DioException catch (error) {
    return error;
  }
  fail('Expected DioException');
}

class _AuthRepositorySpy implements AuthRepository {
  int invalidateCount = 0;

  @override
  Future<void> invalidate() async => invalidateCount++;

  @override
  Future<AuthState> restore() => throw UnimplementedError();

  @override
  Future<Failure?> signIn(String token) => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();
}
