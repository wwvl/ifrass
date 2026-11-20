/// Log 拦截器（AGENTS.md §5 第 4 条，注册顺序 5/5，最外层）。
///
/// 结构化单行 JSON：method / path / status / duration / failureType。
/// **脱敏硬约束（§11）**：不打印 query、headers、body、错误正文或 token。
///
/// 日志槽位 `sink` 由装配层注入（`AppConfig.enableHttpLogging` 时接
/// debugPrint，测试注入收集器）；null = 静默（release 默认）。注册在最外层，
/// onError 记录的是经过 Retry / ErrorMapping / Unauthorized 处理后的最终形态。
library;

import 'dart:convert';

import 'package:cna/core/error/failure.dart';
import 'package:dio/dio.dart';

/// 耗时测量的 extra key（Stopwatch 实例，仅单次请求生命周期内使用）。
const String _stopwatchKey = 'cna.log_stopwatch';

/// 结构化 HTTP 日志器。
class LoggingInterceptor extends Interceptor {
  /// 创建拦截器；[sink] 为日志出口（每行调用一次），null 表示静默。
  new({this.sink});

  /// 日志出口；null = 静默。
  final void Function(String line)? sink;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (sink != null) {
      options.extra[_stopwatchKey] = Stopwatch()..start();
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(_summary(response.requestOptions, response.statusCode));
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = err.error;
    final failureType = failure is Failure
        ? failure.runtimeType.toString()
        : err.type.name;
    _log(_summary(err.requestOptions, err.response?.statusCode, failureType));
    handler.next(err);
  }

  String _summary(RequestOptions options, int? status, [String? failureType]) {
    final stopwatch = options.extra[_stopwatchKey] as Stopwatch?;
    stopwatch?.stop();
    return jsonEncode({
      'method': options.method,
      'path': options.uri.path,
      'status': status,
      'duration': stopwatch?.elapsedMilliseconds,
      'failureType': failureType,
    });
  }

  void _log(String line) {
    sink?.call(line);
  }
}
