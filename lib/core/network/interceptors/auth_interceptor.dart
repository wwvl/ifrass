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

/// Authorization 注入器：从 SecureStorage 读当前 PAT。
class AuthInterceptor extends Interceptor {
  /// 创建拦截器；[readToken] 由装配层注入（`secureStorageProvider.readToken`）。
  new({required this.readToken});

  /// 读当前 PAT（返回 null / 空串时不注入）。
  final Future<String?> Function() readToken;

  /// 逐请求占位的 Authorization 头名（与生成物 `BearerAuthSecurity` 的
  /// `'BearerAuth'` 不同，此处为标准头）。
  static const String authorizationHeader = 'Authorization';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept'] = 'application/json';
    if (options.headers[authorizationHeader] == null) {
      final token = await readToken();
      if (token != null && token.isNotEmpty) {
        options.headers[authorizationHeader] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
