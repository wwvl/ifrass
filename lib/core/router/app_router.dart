/// 应用路由（AGENTS.md §7：路由表用 [AppRoutes] 常量，守卫是纯函数）。
///
/// refreshListenable 桥接（禁止全局单例）：
/// - 桥接对象为本文件私有类，由 [appRouter] provider 闭包持有；
/// - provider 内 `ref.listen(authNotifierProvider, ...)` 在 build 期注册，
///   `AuthState` 一变即 `notifyListeners()`，守卫随之重跑；
/// - `ref.onDispose` 释放监听与桥（测试容器 dispose 同样生效）；
/// - redirect 回调体只做 `ref.read(authNotifierProvider, ...)` 这一次同步读。
library;

import 'package:cna/core/router/guards.dart';
import 'package:cna/core/router/pages/app_shell.dart';
import 'package:cna/core/router/pages/placeholder_pages.dart';
import 'package:cna/core/router/routes.dart';
import 'package:cna/features/auth/presentation/pages/login_page.dart';
import 'package:cna/features/auth/presentation/pages/splash_page.dart';
import 'package:cna/features/auth/presentation/state/auth_notifier.dart';
import 'package:cna/shared/pages/not_found_page.dart';
import 'package:cna/shared/pages/offline_page.dart';
import 'package:cna/shared/pages/session_expired_page.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// 创建全局 [GoRouter]（app 生命周期持有，keepAlive）。
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final listenable = AuthStateListenable();
  ref
    ..listen(authNotifierProvider, (_, _) => listenable.notify())
    ..onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: listenable,
    redirect: (context, state) =>
        appRedirect(ref.read(authNotifierProvider), state),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: AppRoutes.offline, builder: (_, _) => const OfflinePage()),
      GoRoute(
        path: AppRoutes.sessionExpired,
        builder: (_, _) => const SessionExpiredPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const PlaceholderPage(title: '首页'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.repos,
                builder: (_, _) => const PlaceholderPage(title: '仓库'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (_, _) => const PlaceholderPage(title: '设置'),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, _) => const NotFoundPage(),
  );
}

/// `AuthState` → `Listenable` 桥（provider 闭包私有，非全局单例）。
class AuthStateListenable extends ChangeNotifier {
  /// 通知 GoRouter 重跑守卫。
  void notify() => notifyListeners();
}
