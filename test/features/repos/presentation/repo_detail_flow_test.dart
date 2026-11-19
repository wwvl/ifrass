import 'dart:async';

import 'package:cna/core/router/app_router.dart';
import 'package:cna/core/router/routes.dart';
import 'package:cna/core/storage/in_memory_secure_storage.dart';
import 'package:cna/core/storage/secure_storage_provider.dart';
import 'package:cna/features/auth/data/datasource/fake_auth_data_source.dart';
import 'package:cna/features/auth/presentation/pages/login_page.dart';
import 'package:cna/features/auth/presentation/state/auth_notifier.dart';
import 'package:cna/features/repos/data/datasource/fake_repos_datasource.dart';
import 'package:cna/features/repos/data/repos_providers.dart';
import 'package:cna/features/repos/presentation/pages/repo_shell_page.dart';
import 'package:cna/main.dart';
import 'package:cna/shared/widgets/repo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

void main() {
  late InMemorySecureStorage storage;
  late FakeReposDataSource fakeRepos;
  late ProviderContainer container;

  setUp(() {
    storage = InMemorySecureStorage();
    fakeRepos = FakeReposDataSource(delay: Duration.zero);
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        authDataSourceProvider.overrideWithValue(
          FakeAuthDataSource(delay: Duration.zero),
        ),
        reposDataSourceProvider.overrideWithValue(fakeRepos),
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

  testWidgets('主链路：登录 → ?from= 回跳 /repos → 点击进详情 → Tab 切换 → 返回', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(location(), '/login');

    // 深链：未登录访问 /repos 被守卫拦到 login?from=
    container.read(appRouterProvider).go('/repos');
    await tester.pumpAndSettle();
    expect(location(), '/login?from=%2Frepos');

    // 登录成功 → 由守卫按 from 回跳（页面内不写导航）
    await tester.enterText(find.byType(TextField), 'good-token');
    await tester.tap(find.widgetWithText(TButton, '登录'));
    await tester.pumpAndSettle();
    expect(location(), '/repos');
    expect(find.byType(RepoCard), findsNWidgets(3));

    // 点击进详情：卡片 onTap → context.push 已由 probe 用例证明挂接正确
    // （AuthUnknown 时 push 执行并被守卫送 /splash）；widget 测试里
    // shell + TPullDownRefresh 手势竞技场的 tap 行为不稳定，此处用
    // router.push 直驱渲染链路，真机 tap 由 integration_test 覆盖。
    unawaited(
      container
          .read(appRouterProvider)
          .push(AppRoutes.repo(owner: 'cnb', name: 'cna')),
    );
    await tester.pumpAndSettle();
    // push 压栈不更新 routeInformationProvider 的 URL——渲染证据断言
    expect(find.byType(RepoShellPage), findsOneWidget);
    expect(find.text('Code'), findsNWidgets(2)); // Tab 标签 + 占位页 label
    expect(find.text('cnb/cna 的 Code 内容将在后续里程碑提供。'), findsOneWidget);

    // Tab 切换到 Issues（TabBarView 联动）
    await tester.tap(find.text('Issues'));
    await tester.pumpAndSettle();
    expect(find.text('cnb/cna 的 Issues 内容将在后续里程碑提供。'), findsOneWidget);

    // 返回列表
    container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    expect(find.byType(RepoShellPage), findsNothing);
    expect(find.byType(RepoCard), findsNWidgets(3));
  });

  testWidgets('未登录深链到详情页仍被守卫拦到 /login', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/repo/cnb/cna');
    await tester.pumpAndSettle();

    expect(location(), '/login?from=%2Frepo%2Fcnb%2Fcna');
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
