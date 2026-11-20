/// ErrorMapping 拦截器（AGENTS.md §5 第 3 条，注册顺序 3/5）。
///
/// onError 时把 [failureFromDioException] 的映射结果挂到 DioException.error
/// 上再放行——datasource 只需 `throw e.error as Failure` 式薄解包，映射全 app
/// 仅此一处。保留原始 `response`（status）供后续拦截器（Unauthorized / Log）
/// 与 UI 决策使用。
library;

import 'package:cna/core/error/failure.dart';
import 'package:cna/core/network/error_mapper.dart';
import 'package:dio/dio.dart';

/// 把 DioException 统一映射为携带 sealed Failure 的异常。
class ErrorMappingInterceptor extends Interceptor {
  /// 创建拦截器（无状态，const 复用）。
  const new();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is Failure) {
      // 重放链路（Retry → 重新入栈）已映射过，不二次包裹。
      handler.next(err);
      return;
    }
    handler.next(err.copyWith(error: failureFromDioException(err)));
  }
}
