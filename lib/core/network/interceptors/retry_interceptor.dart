/// Retry 拦截器（AGENTS.md §5 第 2 条，注册顺序 2/5）。
///
/// 只对幂等 method 白名单（GET/HEAD/PUT/DELETE/OPTIONS）重试：
///  - HTTP 状态：5xx / 408 / 429（401 永不重试——清 token 后重发会抖动）；
///  - 网络错误：connectionTimeout / sendTimeout / receiveTimeout /
///    connectionError（瞬时类）。`transformTimeout` 归超时类但**不重试**
///    （§5 dio 5.11 语义）；`badCertificate` 持续性失败不重试；`cancel`
///    与 `unknown` 不重试。
///  - **POST / PATCH 零重试**（防重复创建 Issue/PR）；`connectionError`
///    下的 POST 也不会被重发——method 白名单先于异常类型判定（§5）。
///
/// 退避：指数 `base × 2ⁿ`；服务端 `Retry-After`（非负整数秒或 HTTP 日期）
/// 优先，合法值不截短。重放经**同一 Dio 实例**（拦截器链
/// 完整重跑；生成物自带 RetryInterceptor 的裸 `Dio()` 重放不满足此要求，
/// 不可用）。`extra['retry_count']` 计数防环。
library;

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// 幂等 method 白名单（§5；POST/PATCH 明确排除）。
const Set<String> kRetryableMethods = {
  'GET',
  'HEAD',
  'PUT',
  'DELETE',
  'OPTIONS',
};

/// 可重试 HTTP 状态（5xx 全量 + 408 请求超时 + 429 限流）。
bool isRetryableStatus(int? status) =>
    status != null &&
    (status == 408 || status == 429 || (status >= 500 && status < 600));

/// 可重试的瞬时网络异常类型（`transformTimeout` 明确不在内）。
const Set<DioExceptionType> kRetryableNetworkTypes = {
  DioExceptionType.connectionTimeout,
  DioExceptionType.sendTimeout,
  DioExceptionType.receiveTimeout,
  DioExceptionType.connectionError,
};

/// 请求计数 key（extra 内）。
const String _retryCountKey = 'cna.retry_count';

/// 幂等请求的 5xx/408/429/网络错误自动重试器。
class RetryInterceptor extends Interceptor {
  /// 创建拦截器；[dio] 必须是承载本拦截器的同一实例（重放走完整拦截器链）。
  /// [backoffBase] 必填：生产取 `AppConfig.retryBackoffBase`，测试注入
  /// `Duration.zero` 加速（fake clock 纪律，§6 M2 实测补正）。
  new({
    required this.dio,
    required this.backoffBase,
    this.maxRetries = 3,
    DateTime Function()? now,
    this.wait,
  }) : _now = now ?? DateTime.now;

  /// 承载本拦截器的 Dio 实例（重放入口）。
  final Dio dio;

  /// 最大重试次数（不含首次请求）。
  final int maxRetries;

  /// 指数退避基数。
  final Duration backoffBase;

  final DateTime Function() _now;

  /// 测试可注入等待函数；生产默认使用可随 CancelToken 取消的计时器。
  final Future<void> Function(Duration)? wait;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final count = options.extra[_retryCountKey] as int? ?? 0;
    final delay = _retryDelay(err, count);

    if (count >= maxRetries ||
        delay == null ||
        (options.cancelToken?.isCancelled ?? false)) {
      handler.next(err);
      return;
    }

    options.extra[_retryCountKey] = count + 1;
    try {
      await _waitBeforeRetry(delay, options.cancelToken);
    } on DioException catch (cancelled) {
      handler.next(cancelled);
      return;
    }
    try {
      final response = await dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      // 重放已跑完同一条链：拒绝外层请求，避免再次触发 401 / 日志副作用。
      handler.reject(retryError);
    } on Object catch (error) {
      // 重放阶段的非 Dio 异常（如 JSON 形状 TypeError）包回 DioException，
      // 保持「调用方只见 DioException / Failure」的合同。
      handler.next(DioException(requestOptions: options, error: error));
    }
  }

  Future<void> _waitBeforeRetry(
    Duration delay,
    CancelToken? cancelToken,
  ) async {
    final cancelled = cancelToken?.cancelError;
    if (cancelled != null) {
      throw cancelled;
    }
    final wait = this.wait;
    if (wait != null) {
      await Future.any<void>([
        wait(delay),
        if (cancelToken != null)
          cancelToken.whenCancel.then<void>((error) => throw error),
      ]);
      return;
    }
    final completed = Completer<void>();
    final timer = Timer(delay, completed.complete);
    if (cancelToken != null) {
      unawaited(
        cancelToken.whenCancel.then((error) {
          timer.cancel();
          if (!completed.isCompleted) {
            completed.completeError(error, error.stackTrace);
          }
        }),
      );
    }
    try {
      await completed.future;
    } finally {
      timer.cancel();
    }
  }

  /// 本次错误应等待的时长；null = 不重试。
  ///
  /// 判定顺序：method 白名单 → 可重试（状态 / 网络类型）→ 退避时长
  /// （`Retry-After` 优先，仅对可重试错误生效——401 即使带了该头也不重试）。
  Duration? _retryDelay(DioException err, int count) {
    if (err.type == DioExceptionType.transformTimeout) return null;
    if (!kRetryableMethods.contains(err.requestOptions.method.toUpperCase())) {
      return null;
    }
    final status = err.response?.statusCode;
    final hasResponse = status != null;
    final retryable = hasResponse
        ? isRetryableStatus(status)
        : kRetryableNetworkTypes.contains(err.type);
    if (!retryable) {
      return null;
    }
    return _parseRetryAfter(err) ?? backoffBase * (1 << count);
  }

  /// RFC 9110 §10.2.3：非负整数秒或 HTTP 日期；缺失 / 非法返回 null。
  /// 已过期的日期等价于无需等待，不回落到指数退避。
  Duration? _parseRetryAfter(DioException err) {
    final raw = err.response?.headers.value('retry-after');
    if (raw == null) {
      return null;
    }
    final value = raw.trim();
    if (RegExp(r'^\d+$').hasMatch(value)) {
      final seconds = int.tryParse(value);
      return seconds == null ? null : Duration(seconds: seconds);
    }
    try {
      final delay = HttpDate.parse(value).difference(_now().toUtc());
      return delay.isNegative ? Duration.zero : delay;
    } on HttpException {
      return null;
    }
  }
}
