/// 顶层路由守卫（AGENTS.md §7）。
///
/// [appRedirect] 是同步纯函数：不 await、不做 IO、不写 provider、
/// 不读 `DateTime.now()`；go_router 的 redirect 回调体只允许
/// `appRedirect(ref.read(authNotifierProvider), state)` 这一次同步读。
/// 触发重跑只靠 refreshListenable（app_router.dart 桥接），本文件不触碰。
library;

import 'package:cna/core/router/routes.dart';
import 'package:cna/features/auth/domain/auth_state.dart';
import 'package:go_router/go_router.dart';

/// 纯函数守卫：返回 `null` 放行，或返回目标 location。
String? appRedirect(AuthState auth, GoRouterState state) {
  final location = state.matchedLocation;

  // 未匹配路由交给 errorBuilder（404 页），守卫不劫持
  if (state.error != null) {
    return null;
  }

  // 信息页（离线 / 会话过期）任何认证状态都可访问
  if (location == AppRoutes.offline || location == AppRoutes.sessionExpired) {
    return null;
  }

  switch (auth) {
    case AuthUnknown():
      // splash 自身放行（restore 停留期）；其余一律去 splash 等待解析
      return location == AppRoutes.splash ? null : AppRoutes.splash;

    case AuthSignedOut():
      if (location == AppRoutes.login) {
        return null;
      }
      if (location == AppRoutes.splash) {
        // 未登录离开 splash 不带 from（回跳 splash 无意义）
        return AppRoutes.login;
      }
      // 深链保留：携带原始 uri（含 query）供登录后由 redirect 回跳
      final from = Uri.encodeComponent(state.uri.toString());
      return '${AppRoutes.login}?from=$from';

    case AuthSignedIn():
      if (location == AppRoutes.login) {
        final target = safeFromTarget(state.uri.queryParameters['from']);
        if (target == null || target == location) {
          // 无有效 from（含恶意 / 自引用）→ 回首页，防死循环
          return AppRoutes.home;
        }
        return target;
      }
      if (location == AppRoutes.splash) {
        return AppRoutes.home;
      }
      return null;
  }
}

/// 校验深链 `from` 为站内路径：非绝对、无 scheme / host、以 `/` 开头。
/// 不合法（开放重定向防护）返回 null，由调用方回落首页。
String? safeFromTarget(String? from) {
  if (from == null || from.isEmpty || !from.startsWith('/')) {
    return null;
  }
  final uri = Uri.tryParse(from);
  if (uri == null || uri.isAbsolute || uri.host.isNotEmpty) {
    return null;
  }
  return from;
}
