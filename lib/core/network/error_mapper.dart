/// Dio 异常 → sealed `Failure` 统一映射（AGENTS.md §5 第 3 条）。
///
/// 唯一映射点：`ErrorMappingInterceptor` 把映射结果挂在 DioException.error
/// 上，datasource 只做薄解包；sealed `Error` 分支（2xx 非 200）走
/// [failureFromResponse]。纯函数，不依赖拦截器与 provider，可独立单测。
///
/// dio 5.11.1 两条新增语义（AGENTS.md §5）：
///  - `DioExceptionType.transformTimeout` 归超时类（[FailureNetwork]），
///    Retry 拦截器不把它当可重试网络错误；
///  - `connection closed before full header was received` 已由 dio 改判
///    `connectionError`（[FailureNetwork]）；Retry 只按 method 白名单重试，
///    POST/PATCH 不会被该子类重发。
///
/// 日志脱敏：body 只保留摘录且不进 `toString`（AGENTS.md §11）。
library;

import 'package:cna/core/error/failure.dart';
import 'package:dio/dio.dart';

/// 响应体摘录上限（字符），超出截断。
const int _bodyExcerptLimit = 200;

/// DioException（含网络 / 超时 / HTTP 状态 / 取消 / JSON 形状破坏）→ Failure。
///
/// 穷尽 `DioExceptionType` 全部 9 个枚举值：
///  - `badResponse`：401 → `FailureUnauthorized`；其余 → `FailureHttp(status)`
///    （403/404/422/5xx 等保留 status 供 UI 决策，DESIGN.md §8）；
///  - `connectionTimeout` / `sendTimeout` / `receiveTimeout` /
///    `transformTimeout` / `connectionError` / `badCertificate` →
///    `FailureNetwork`（OfflineView 对应态）；
///  - `cancel` → `FailureUnknown`（页面销毁取消，Notifier 层按 epoch 吞掉，
///    正常不可见）；
///  - `unknown`：error 为 `TypeError` / `FormatException`（dio 解析阶段抛出，
///    例如生成物 `as Map` 形状破坏）→ `FailureParse`；其余 → `FailureUnknown`。
Failure failureFromDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.badResponse:
      final status = error.response?.statusCode ?? 0;
      final body = _excerpt(error.response?.data);
      if (status == 401) {
        return FailureUnauthorized(body: body);
      }
      return FailureHttp(status, body: body);
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const FailureNetwork(message: 'timeout');
    case DioExceptionType.connectionError:
      return const FailureNetwork(message: 'connection error');
    case DioExceptionType.badCertificate:
      return const FailureNetwork(message: 'bad certificate');
    case DioExceptionType.cancel:
      return const FailureUnknown('request cancelled');
    case DioExceptionType.unknown:
      final cause = error.error;
      if (cause is TypeError || cause is FormatException) {
        return FailureParse('响应形状破坏: $cause');
      }
      return FailureUnknown('${cause?.runtimeType ?? error.type}');
  }
}

/// 生成物 sealed result 的 `Error` 分支（2xx 非 200，默认 `validateStatus`
/// 下 4xx/5xx 走 DioException，到不了这里）→ Failure。
Failure failureFromResponse(int? status, Object? body) =>
    FailureHttp(status ?? 0, body: _excerpt(body));

/// 响应体摘录：字符串截断；结构化数据转字符串后截断（不携带全文，§11）。
String? _excerpt(Object? body) {
  if (body == null) {
    return null;
  }
  final text = body is String ? body : body.toString();
  if (text.length <= _bodyExcerptLimit) {
    return text;
  }
  return '${text.substring(0, _bodyExcerptLimit)}…';
}
