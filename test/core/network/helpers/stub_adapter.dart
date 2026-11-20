import 'dart:convert';
import 'dart:typed_data';

import 'package:cna/core/network/interceptors/auth_interceptor.dart';
import 'package:cna/core/network/interceptors/error_mapping_interceptor.dart';
import 'package:cna/core/network/interceptors/logging_interceptor.dart';
import 'package:cna/core/network/interceptors/retry_interceptor.dart';
import 'package:cna/core/network/interceptors/unauthorized_interceptor.dart';
import 'package:cna/features/auth/domain/auth_repository.dart';
import 'package:dio/dio.dart';

/// 可编程回复。
class StubReply {
  /// 创建回复；[body] 为对象时经 jsonEncode 序列化，字符串原样。
  const new({required this.status, this.body, this.headers = const {}});

  /// HTTP 状态码。
  final int status;

  /// 响应体（JSON 响应需为可序列化对象 / 数组 / 字符串）。
  final Object? body;

  /// 附加响应头（如 `retry-after`）。
  final Map<String, List<String>> headers;
}

/// 打桩 `HttpClientAdapter`（AGENTS.md §5：测试不打真实网络）。
///
/// [handler] 依请求序号 / 内容返回 [StubReply]，或直接抛
/// `DioException`（模拟网络异常）；[received] 记录到达 adapter 的请求
/// （此时拦截器已跑完 onRequest，可断言头注入），[count] 为到达次数
/// （重试计数断言）。
class StubAdapter implements HttpClientAdapter {
  /// 创建打桩 adapter。
  new(this.handler);

  /// 按请求生成回复；抛出值原样传播（DioException 直达拦截器链）。
  final Future<StubReply> Function(RequestOptions options, int attempt) handler;

  /// 到达 adapter 的请求（按序）。
  final List<RequestOptions> received = <RequestOptions>[];

  /// 到达次数。
  int get count => received.length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final attempt = count;
    received.add(options);
    final reply = await handler(options, attempt);
    // 字符串 body 按 text/plain 回（dio 对 JSON content-type 的 4xx 也做
    // jsonDecode，裸字符串会盖掉原始状态）；对象/数组才按 JSON。
    final isString = reply.body is String;
    return ResponseBody.fromString(
      isString ? reply.body! as String : jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: <String>[
          if (isString) 'text/plain' else Headers.jsonContentType,
        ],
        ...reply.headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// 构建带五个拦截器完整链的测试 Dio（与生产 dioProvider 同构）。
///
/// 简化点：[readToken] 直传、[backoffBase] 默认 zero（fake clock 纪律）、
/// [sink] 收集日志行、[repository] / [onInvalidated] 记录 401 失效动作。
Dio buildTestDio({
  required StubAdapter adapter,
  Future<String?> Function()? readToken,
  Duration backoffBase = Duration.zero,
  int maxRetries = 3,
  void Function(String line)? sink,
  AuthRepository Function()? repository,
  void Function()? onInvalidated,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
    ..httpClientAdapter = adapter;
  dio.interceptors.addAll([
    AuthInterceptor(readToken: readToken ?? () async => null),
    RetryInterceptor(
      dio: dio,
      maxRetries: maxRetries,
      backoffBase: backoffBase,
    ),
    const ErrorMappingInterceptor(),
    UnauthorizedInterceptor(
      repository:
          repository ?? () => throw StateError('unexpected 401 in this test'),
      onInvalidated: onInvalidated ?? () {},
    ),
    LoggingInterceptor(sink: sink),
  ]);
  return dio;
}
