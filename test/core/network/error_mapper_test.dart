import 'package:cna/core/error/failure.dart';
import 'package:cna/core/network/error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// `failureFromDioException` / `failureFromResponse` 的穷尽映射契约
/// （AGENTS.md §5 第 3 条：Failure 五类；dio 5.11.1 全部 9 个
/// DioExceptionType 分支 + status 保留）。
void main() {
  RequestOptions options() => RequestOptions(path: '/x');

  Response<dynamic> response(int status, [Object? body]) => Response<dynamic>(
    requestOptions: options(),
    statusCode: status,
    data: body,
  );

  group('failureFromDioException / badResponse（status 保留）', () {
    test('401 → FailureUnauthorized（不带 status 字段，语义即 401）', () {
      final failure = failureFromDioException(
        DioException.badResponse(
          statusCode: 401,
          requestOptions: options(),
          response: response(401, {'message': 'invalid token'}),
        ),
      );

      expect(failure, isA<FailureUnauthorized>());
      expect((failure as FailureUnauthorized).body, contains('invalid token'));
    });

    test('403 / 404 / 422 / 500 / 503 → FailureHttp(status, body 摘录)', () {
      for (final status in <int>[403, 404, 422, 500, 503]) {
        final failure = failureFromDioException(
          DioException.badResponse(
            statusCode: status,
            requestOptions: options(),
            response: response(status, 'boom-$status'),
          ),
        );

        expect(failure, isA<FailureHttp>(), reason: 'status=$status');
        expect(
          (failure as FailureHttp).status,
          status,
          reason: 'status=$status',
        );
        expect(failure.body, 'boom-$status', reason: 'status=$status');
      }
    });

    test('超长 body 只保留摘录（脱敏纪律，§11）', () {
      final failure = failureFromDioException(
        DioException.badResponse(
          statusCode: 500,
          requestOptions: options(),
          response: response(500, 'x' * 500),
        ),
      );

      expect((failure as FailureHttp).body!.length, lessThan(220));
      expect(failure.body, endsWith('…'));
    });

    test('badResponse 无 body → FailureHttp(status) 不带摘录', () {
      final failure = failureFromDioException(
        DioException.badResponse(
          statusCode: 500,
          requestOptions: options(),
          response: response(500),
        ),
      );

      expect((failure as FailureHttp).status, 500);
      expect(failure.body, isNull);
    });
  });

  group('failureFromDioException / 网络与超时类', () {
    test('4 种超时 + connectionError + badCertificate → FailureNetwork', () {
      final cases = <DioExceptionType, DioException>{
        DioExceptionType.connectionTimeout: DioException.connectionTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: options(),
        ),
        DioExceptionType.sendTimeout: DioException.sendTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: options(),
        ),
        DioExceptionType.receiveTimeout: DioException.receiveTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: options(),
        ),
        // dio 5.11 新增：transformTimeout 归超时类（§5，不重试由 Retry 把关）
        DioExceptionType.transformTimeout: DioException.transformTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: options(),
        ),
        // dio 5.11：connection closed before full header → connectionError
        DioExceptionType.connectionError: DioException.connectionError(
          requestOptions: options(),
          reason: 'connection closed before full header was received',
        ),
        DioExceptionType.badCertificate: DioException.badCertificate(
          requestOptions: options(),
        ),
      };

      for (final MapEntry(key: type, value: error) in cases.entries) {
        expect(
          failureFromDioException(error),
          isA<FailureNetwork>(),
          reason: 'type=$type',
        );
      }
    });

    test('cancel → FailureUnknown（Notifier 层按 epoch 吞掉）', () {
      final failure = failureFromDioException(
        DioException.requestCancelled(
          requestOptions: options(),
          reason: 'page disposed',
        ),
      );

      expect(failure, isA<FailureUnknown>());
    });

    test('unknown + FormatException → FailureParse（JSON 形状破坏）', () {
      final failure = failureFromDioException(
        DioException(
          requestOptions: options(),
          error: const FormatException('bad json'),
        ),
      );

      expect(failure, isA<FailureParse>());
    });

    test('unknown + TypeError → FailureParse', () {
      final failure = failureFromDioException(
        DioException(requestOptions: options(), error: TypeError()),
      );

      expect(failure, isA<FailureParse>());
    });

    test('unknown + 其它 → FailureUnknown', () {
      final failure = failureFromDioException(
        DioException(requestOptions: options(), error: StateError('weird')),
      );

      expect(failure, isA<FailureUnknown>());
    });
  });

  group('failureFromResponse（sealed Error 分支：2xx 非 200）', () {
    test('204 → FailureHttp(204)', () {
      final failure = failureFromResponse(204, '');

      expect(failure, isA<FailureHttp>());
      expect((failure as FailureHttp).status, 204);
    });

    test('status null → 0 兜底', () {
      expect((failureFromResponse(null, null) as FailureHttp).status, 0);
    });
  });
}
