/// Auth 拦截器（AGENTS.md §5 第 1 条，注册顺序 1/5）。
///
/// - 每个请求注入 `Accept: application/json`；
/// - `Authorization: Bearer ${token}` **仅在请求头尚未携带时**从
///   `readToken`（SecureStorage）读取注入——「absent 才注入」同时覆盖两个
///   场景：① 登录校验 `verify(token)` 时候选 token 尚未入 storage，由调用方
///   经逐请求 `Options(headers:)` 先行占位；② 生成物 `BearerAuthSecurity`
///   不可用（默认 keyName 是字面量 `'BearerAuth'` 头、静态 apiKey、不带
///   Bearer 前缀），本拦截器是 app 内唯一注入点，头不可能重复。
///
/// token 每请求读取（不缓存）：登录 / 登出后的下一个请求立即生效。
library;

import 'package:dio/dio.dart';

/// Dio 5 请求的生命周期：默认取消信号与显式页面取消信号统一由装配层释放。
/// 请求结束后移除登记，重试复用同一 RequestOptions 时不会重复持有资源。
class NetworkRequestLifetime {
  /// 创建网络生命周期。
  new();

  static const String _disposedReason = 'network provider disposed';
  bool _disposed = false;
  final Map<RequestOptions, CancelToken> _activeRequests = Map.identity();

  /// 绑定并登记请求，保持调用方显式传入的页面取消信号。
  void attach(RequestOptions options) {
    final token = (options.cancelToken ??= CancelToken())
      ..requestOptions = options;
    final cancelled = cancellationFor(options);
    if (cancelled != null) throw cancelled;
    _activeRequests[options] = token;
  }

  /// 取消错误始终使用当前请求信息，并拒绝释放后才到达拦截器的响应。
  DioException? cancellationFor(RequestOptions options) {
    final token = options.cancelToken;
    if (_disposed && token != null && !token.isCancelled) {
      token.cancel(_disposedReason);
    }
    final error = token?.cancelError;
    return error?.copyWith(requestOptions: options);
  }

  /// 延迟认证回调在读取 provider 容器前检查生命周期，防止释放后读取。
  void throwIfDisposed() {
    if (_disposed) {
      throw DioException.requestCancelled(
        requestOptions: RequestOptions(),
        reason: _disposedReason,
      );
    }
  }

  /// 释放已完成请求的登记；由最终响应或错误的尾部拦截器调用。
  void complete(RequestOptions options) => _activeRequests.remove(options);

  /// 取消在途请求及重试等待；同一显式信号只取消一次。
  void dispose() {
    _disposed = true;
    final tokens = _activeRequests.values.toSet();
    _activeRequests.clear();
    for (final token in tokens) {
      if (!token.isCancelled) token.cancel(_disposedReason);
    }
  }
}

/// Authorization 注入器：从 SecureStorage 读当前 PAT。
class AuthInterceptor extends Interceptor {
  /// 创建拦截器；[readToken] 由装配层注入（`secureStorageProvider.readToken`）。
  new({required this.readToken, this.lifetime});

  /// 读当前 PAT（返回 null / 空串时不注入）。
  final Future<String?> Function() readToken;

  /// 可选的 Dio 5 生命周期信号；生产由 dioProvider 持有。
  final NetworkRequestLifetime? lifetime;

  /// 逐请求占位的 Authorization 头名（与生成物 `BearerAuthSecurity` 的
  /// `'BearerAuth'` 不同，此处为标准头）。
  static const String authorizationHeader = 'Authorization';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      lifetime?.attach(options);
      options.headers['Accept'] = 'application/json';
      if (options.headers[authorizationHeader] == null) {
        final cancelToken = options.cancelToken;
        final token = await Future.any<String?>([
          readToken(),
          if (cancelToken != null)
            cancelToken.whenCancel.then<String?>((error) => throw error),
        ]);
        if (token != null && token.isNotEmpty) {
          options.headers[authorizationHeader] = 'Bearer $token';
        }
      }
      final cancelled = lifetime?.cancellationFor(options);
      if (cancelled != null) throw cancelled;
      handler.next(options);
    } on DioException catch (error) {
      handler.reject(error, true);
    }
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final cancelled = lifetime?.cancellationFor(response.requestOptions);
    if (cancelled != null) {
      handler.reject(cancelled, true);
    } else {
      handler.next(response);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(lifetime?.cancellationFor(err.requestOptions) ?? err);
  }
}
