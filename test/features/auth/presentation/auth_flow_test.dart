import 'dart:async';

import 'package:cna/core/router/app_router.dart';
import 'package:cna/core/storage/in_memory_secure_storage.dart';
import 'package:cna/core/storage/secure_storage_provider.dart';
import 'package:cna/features/auth/data/datasource/fake_auth_data_source.dart';
import 'package:cna/features/auth/presentation/pages/login_page.dart';
import 'package:cna/features/auth/presentation/pages/splash_page.dart';
import 'package:cna/features/auth/presentation/state/auth_notifier.dart';
import 'package:cna/main.dart';
import 'package:cna/shared/pages/not_found_page.dart';
import 'package:cna/shared/pages/offline_page.dart';
import 'package:cna/shared/pages/session_expired_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

void main() {
  late InMemorySecureStorage storage;
  late ProviderContainer container;

  setUp(() {
    storage = InMemorySecureStorage();
    container = ProviderContainer.test(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        authDataSourceProvider.overrideWithValue(
          FakeAuthDataSource(
            delay: Duration.zero,
            invalidToken: 'invalid-token',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  Widget app() =>
      UncontrolledProviderScope(container: container, child: const CnaApp());

  String location() => container
      .read(appRouterProvider)
      .routeInformationProvider
      .value
      .uri
      .toString();

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
  }

  testWidgets('未登录深链：/repos → /login?from=%2Frepos', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(location(), '/login');
    expect(find.byType(LoginPage), findsOneWidget);

    container.read(appRouterProvider).go('/repos');
    await tester.pumpAndSettle();

    expect(location(), '/login?from=%2Frepos');
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('登录成功：由守卫按 from 回跳 /repos（页面内不写导航）', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go('/repos');
    await tester.pumpAndSettle();
    expect(location(), '/login?from=%2Frepos');

    await tester.enterText(find.byType(TextField), 'good-token');
    await tester.tap(find.widgetWithText(TButton, '登录'));
    await tester.pumpAndSettle();

    expect(location(), '/repos');
  });

  testWidgets('已登录直接访问 /login → 守卫送回 /', (tester) async {
    await storage.writeToken('good-token');
    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(location(), '/');

    container.read(appRouterProvider).go('/login');
    await tester.pumpAndSettle();

    expect(location(), '/');
  });

  testWidgets('登出：回 /login（守卫触发，页面不写导航）', (tester) async {
    await storage.writeToken('good-token');
    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(location(), '/');

    await container.read(authNotifierProvider.notifier).signOut();
    await tester.pumpAndSettle();

    // 登出前停在 home：from=/ 登录后正好回首页
    expect(location(), '/login?from=%2F');
  });

  testWidgets('splash：restore 慢响应期间停留解析态', (tester) async {
    final slowStorage = InMemorySecureStorage();
    unawaited(slowStorage.writeToken('good-token'));
    final slowContainer = ProviderContainer.test(
      overrides: [
        secureStorageProvider.overrideWithValue(slowStorage),
        authDataSourceProvider.overrideWithValue(
          FakeAuthDataSource(delay: const Duration(milliseconds: 400)),
        ),
      ],
    );
    addTearDown(slowContainer.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: slowContainer,
        child: const CnaApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.text('正在恢复会话…'), findsOneWidget);

    // fake clock 不推进纯 Future.delayed：显式越过 400ms 慢校验
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byType(SplashPage), findsNothing);
  });

  testWidgets('404 页：未匹配路由由 errorBuilder 呈现', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/no/such/route');
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundPage), findsOneWidget);
    expect(find.text('页面不存在'), findsOneWidget);
  });

  testWidgets('离线页与会话过期页可直达', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/offline');
    await tester.pumpAndSettle();
    expect(find.byType(OfflinePage), findsOneWidget);
    expect(find.text('网络不可用'), findsOneWidget);

    container.read(appRouterProvider).go('/session-expired');
    await tester.pumpAndSettle();
    expect(find.byType(SessionExpiredPage), findsOneWidget);
    expect(find.text('会话已过期'), findsOneWidget);
  });
}
