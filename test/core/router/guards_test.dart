import 'package:cna/core/router/guards.dart';
import 'package:cna/features/auth/domain/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  // GoRouterState 有公开 const 构造：appRedirect 可直接单测，无需路由 harness。
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink())],
  );

  GoRouterState state(
    String uri, {
    String? matchedLocation,
    GoException? error,
    Map<String, String> query = const {},
  }) {
    final parsed = Uri.parse(uri);
    return GoRouterState(
      router.configuration,
      uri: parsed.replace(
        queryParameters: query.isEmpty ? parsed.queryParameters : query,
      ),
      matchedLocation: matchedLocation ?? parsed.path,
      fullPath: parsed.path,
      pathParameters: const {},
      pageKey: const ValueKey('test'),
      error: error,
    );
  }

  test('AuthUnknown：受保护页统一送 /splash', () {
    expect(appRedirect(const AuthUnknown(), state('/repos')), '/splash');
  });

  test('AuthUnknown：/splash 自身放行（防死循环）', () {
    expect(appRedirect(const AuthUnknown(), state('/splash')), isNull);
  });

  test('未登录访问受保护页 → /login?from=<encoded>', () {
    expect(
      appRedirect(const AuthSignedOut(), state('/repos?a=1')),
      '/login?from=%2Frepos%3Fa%3D1',
    );
  });

  test('未登录访问 /login 自身放行', () {
    expect(appRedirect(const AuthSignedOut(), state('/login')), isNull);
  });

  test('已登录访问 /login 且无 from → /', () {
    expect(appRedirect(const AuthSignedIn('t'), state('/login')), '/');
  });

  test('已登录访问 /login 带站内 from → 回跳原目标（redirect 回跳）', () {
    expect(
      appRedirect(
        const AuthSignedIn('t'),
        state('/login', query: {'from': '/repos'}),
      ),
      '/repos',
    );
  });

  test('已登录访问 /splash → /', () {
    expect(appRedirect(const AuthSignedIn('t'), state('/splash')), '/');
  });

  test('恶意绝对 URL 的 from → 回落 /（防开放重定向）', () {
    expect(
      appRedirect(
        const AuthSignedIn('t'),
        state('/login', query: {'from': 'https://evil.com/x'}),
      ),
      '/',
    );
    expect(
      appRedirect(
        const AuthSignedIn('t'),
        state('/login', query: {'from': '//evil.com/x'}),
      ),
      '/',
    );
  });

  test('from 为 /login 自引用 → / 防死循环', () {
    expect(
      appRedirect(
        const AuthSignedIn('t'),
        state('/login', query: {'from': '/login'}),
      ),
      '/',
    );
  });

  test('大小写路径不误判：/Login 是未匹配路由，交给 404', () {
    expect(
      appRedirect(
        const AuthSignedOut(),
        state(
          '/Login',
          matchedLocation: '/Login',
          error: GoException('no match'),
        ),
      ),
      isNull,
    );
  });

  test('信息页（离线 / 会话过期）任何状态放行', () {
    expect(appRedirect(const AuthSignedOut(), state('/offline')), isNull);
    expect(appRedirect(const AuthUnknown(), state('/session-expired')), isNull);
    expect(appRedirect(const AuthSignedIn('t'), state('/offline')), isNull);
  });

  test('幂等：反复 refresh 不抖动（同输入恒同输出，无往复跳转）', () {
    final signedOutOnRepos = state('/repos');
    expect(
      appRedirect(const AuthSignedOut(), signedOutOnRepos),
      appRedirect(const AuthSignedOut(), signedOutOnRepos),
    );
    // 重定向后落点不再触发新跳转：/login 对 SignedOut 放行
    final landedOnLogin = state('/login');
    expect(appRedirect(const AuthSignedOut(), landedOnLogin), isNull);
    // /repos 对 SignedIn 放行
    final signedInOnRepos = state('/repos');
    expect(appRedirect(const AuthSignedIn('t'), signedInOnRepos), isNull);
    expect(appRedirect(const AuthSignedIn('t'), signedInOnRepos), isNull);
  });
}
