/// 网络层装配（AGENTS.md §7 核心 provider：dioProvider / apiClientProvider）。
///
/// `dioProvider` 是全 app **唯一**建 Dio 的地方（§5）：baseUrl 与超时取
/// [AppConfig]；拦截器按 §5 的 1→4 固定相对顺序注册——
/// Auth(1) → Retry(2) → ErrorMapping(3) → Unauthorized(4) → Log(5)，
/// Log 最外层记录处理后形态。`ApiClient` 只传 `dio:` + `baseUrl:`，
/// `bearerAuth` / `errorHandler` / `interceptors` 三个槽位一律不传：
/// 生成物会在构造器与 `.dio` getter 里各加一遍（实测源码），传了就重复。
library;

import 'dart:async';

import 'package:cna/core/config/app_config.dart';
import 'package:cna/core/network/interceptors/auth_interceptor.dart';
import 'package:cna/core/network/interceptors/error_mapping_interceptor.dart';
import 'package:cna/core/network/interceptors/logging_interceptor.dart';
import 'package:cna/core/network/interceptors/retry_interceptor.dart';
import 'package:cna/core/network/interceptors/unauthorized_interceptor.dart';
import 'package:cna/core/storage/secure_storage_provider.dart';
import 'package:cna/features/auth/presentation/state/auth_notifier.dart';
// 生成物 barrel 里自带同名 Auth/Retry/Logging 拦截器（core/interceptors.dart，
// 重放丢拦截器链 / 不看 method，均不可用）——hide 防歧义，本目录实现为准。
import 'package:cna_api/cna_api.dart'
    hide AuthInterceptor, LoggingInterceptor, RetryInterceptor;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_providers.g.dart';

/// 全局 Dio 实例（keepAlive；`ref.onDispose` 关闭底层连接池）。
@Riverpod(keepAlive: true, name: 'dioProvider')
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      sendTimeout: AppConfig.sendTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
    ),
  );

  dio.interceptors.addAll([
    // 1 Auth：absent 才注入 Authorization（登录校验的逐请求头优先）。
    AuthInterceptor(
      readToken: () => ref.read(secureStorageProvider).readToken(),
    ),
    // 2 Retry：幂等 method 白名单 + 5xx/408/429/瞬时网络错误，指数退避。
    RetryInterceptor(dio: dio, backoffBase: AppConfig.retryBackoffBase),
    // 3 ErrorMapping：DioException → sealed Failure（唯一映射点）。
    const ErrorMappingInterceptor(),
    // 4 Unauthorized：401 单一入口；延迟闭包避免装配期 Riverpod 环
    // （dio → authRepository → authDataSource → apiClient → dio）。
    UnauthorizedInterceptor(
      repository: () => ref.read(authRepositoryProvider),
      onInvalidated: () =>
          unawaited(ref.read(authNotifierProvider.notifier).invalidate()),
    ),
    // 5 Log：最外层记录最终形态；release 静默（§11）。
    LoggingInterceptor(sink: AppConfig.enableHttpLogging ? debugPrint : null),
  ]);

  ref.onDispose(dio.close);
  return dio;
}

/// 生成客户端入口（keepAlive）：共享 [dioProvider] 的拦截器链。
@Riverpod(keepAlive: true, name: 'apiClientProvider')
ApiClient apiClient(Ref ref) =>
    ApiClient(baseUrl: AppConfig.apiBaseUrl, dio: ref.watch(dioProvider));
