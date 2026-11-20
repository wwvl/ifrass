/// 401 单一失效入口的 Dio 侧拦截器（AGENTS.md §5 / §6 M2 决策 3）。
///
/// 复用 M2 纯函数 `handleUnauthorized({repository, onInvalidated})`：清
/// SecureStorage → 回调翻转 AuthState → refreshListenable 令守卫跳登录。
/// 依赖经**构造注入**（M2 设计原文：「M2 的 Fake 401 与 M4 的 Dio
/// UnauthorizedInterceptor 复用同一个入口」）；装配层（dioProvider）传
/// **延迟闭包**而非实例——build 期不触碰 auth 图，避免
/// `dio → authRepository → authDataSource → apiClient → dio` 的 Riverpod
/// 环形依赖（§12.23：本类不得 ref.read 任何 auth provider，也不 import
/// auth 的 provider 文件）。
///
/// 401 不重试（Retry 白名单不含）、本拦截器不吞错误：处理完失效动作后
/// 原样放行，调用方仍收到携带 `FailureUnauthorized` 的异常，由登录页 /
/// splash 呈现差异化文案。登录页 signIn 的 401 也会走到这里——state 本就
/// 是 SignedOut，失效动作幂等，不做旁路开关以维持「唯一入口」。
library;

import 'dart:async';

import 'package:cna/core/network/unauthorized_handler.dart';
import 'package:cna/features/auth/domain/auth_repository.dart';
import 'package:dio/dio.dart';

/// 401 失效处理器：触发 `handleUnauthorized` 恰好一次。
class UnauthorizedInterceptor extends Interceptor {
  /// 创建拦截器；[repository] 惰性解析（401 时刻才读 provider，规避装配
  /// 环），[onInvalidated] 由装配层接到 `authNotifierProvider.notifier` 的
  /// 状态复位。
  new({required this.repository, required this.onInvalidated});

  /// 惰性取当前 [AuthRepository]（401 时刻解析）。
  final AuthRepository Function() repository;

  /// 失效后翻转认证状态的回调（装配层接 `authNotifier.invalidate()`）。
  final FutureOr<void> Function() onInvalidated;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      FutureOr<void> invalidation;
      await handleUnauthorized(
        repository: repository(),
        onInvalidated: () => invalidation = onInvalidated(),
      );
      await invalidation;
    }
    handler.next(err);
  }
}
