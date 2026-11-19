import 'package:cna/core/theme/theme.dart';
import 'package:cna/features/repos/data/datasource/fake_repos_datasource.dart';
import 'package:cna/features/repos/data/repos_providers.dart';
import 'package:cna/features/repos/presentation/pages/repos_page.dart';
import 'package:cna/shared/widgets/error_view.dart';
import 'package:cna/shared/widgets/offline_view.dart';
import 'package:cna/shared/widgets/repo_card.dart';
import 'package:cna/shared/widgets/skeleton_repo_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeReposDataSource fakeDS;
  late ProviderContainer container;

  setUp(() {
    fakeDS = FakeReposDataSource(delay: Duration.zero);
    container = ProviderContainer.test(
      retry: (_, _) => null, // AGENTS.md §5：自动重试关闭，error 态稳定断言
      overrides: [reposDataSourceProvider.overrideWithValue(fakeDS)],
    );
    addTearDown(container.dispose);
  });

  Widget page() => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: buildLightAppTheme(), home: const ReposPage()),
  );

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(page());
    await tester.pump(); // 首屏 AsyncLoading（骨架）
    await tester.pump(const Duration(milliseconds: 100)); // 越过 FakeDS 延时
    await tester.pumpAndSettle();
  }

  testWidgets('normal：列表渲染种子仓库卡片', (tester) async {
    await pumpPage(tester);

    expect(find.byType(RepoCard), findsNWidgets(3));
    expect(find.text('cnb/cna'), findsOneWidget);
    expect(find.byType(SkeletonRepoCard), findsNothing);
  });

  testWidgets('forbidden：403 差异化文案（检查令牌授权范围）+ 重试', (tester) async {
    fakeDS.mode = FakeReposMode.forbidden;
    await pumpPage(tester);

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('令牌授权范围不足'), findsOneWidget);
    expect(find.text('请在 CNB「个人设置 → 访问令牌」检查令牌的授权范围后重试。'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.byType(OfflineView), findsNothing);
  });

  testWidgets('offline：离线视图（不伪装成空态或错误）', (tester) async {
    fakeDS.mode = FakeReposMode.offline;
    await pumpPage(tester);

    expect(find.byType(OfflineView), findsOneWidget);
    expect(find.text('网络不可用'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('empty：空态说明「为什么空 + 下一步」', (tester) async {
    fakeDS.mode = FakeReposMode.empty;
    await pumpPage(tester);

    expect(find.text('还没有可见的仓库'), findsOneWidget);
    expect(find.text('你的令牌可见的仓库会出现在这里；也可能是令牌授权范围未覆盖。'), findsOneWidget);
  });

  testWidgets('重试：error 态点击重试，模式恢复后列表出现', (tester) async {
    fakeDS.mode = FakeReposMode.forbidden;
    await pumpPage(tester);
    expect(find.byType(ErrorView), findsOneWidget);

    fakeDS.mode = FakeReposMode.normal;
    await tester.tap(find.text('重试'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.byType(RepoCard), findsNWidgets(3));
  });

  testWidgets('搜索命中：结果态 1 条', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), 'tdesign');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.byType(RepoCard), findsNWidgets(1));
    expect(find.text('tencent/tdesign-flutter'), findsOneWidget);
  });

  testWidgets('搜索无结果：定制空态 + 清除搜索', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), '不存在的仓库');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('没有找到「不存在的仓库」'), findsOneWidget);
    await tester.tap(find.text('清除搜索'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.byType(RepoCard), findsNWidgets(3));
  });

  testWidgets('golden：列表页 loading / empty / error(403) × 浅/深', (tester) async {
    for (final brightness in Brightness.values) {
      final label = brightness == Brightness.light ? 'light' : 'dark';
      final theme = brightness == Brightness.light
          ? buildLightAppTheme()
          : buildDarkAppTheme();

      // loading
      final slowDS = FakeReposDataSource(
        delay: const Duration(milliseconds: 400),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderContainer.test(
            retry: (_, _) => null,
            overrides: [reposDataSourceProvider.overrideWithValue(slowDS)],
          ),
          child: MaterialApp(theme: theme, home: const ReposPage()),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byType(ReposPage),
        matchesGoldenFile('goldens/repos_page_loading_$label.png'),
      );

      // empty
      fakeDS.mode = FakeReposMode.empty;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderContainer.test(
            retry: (_, _) => null,
            overrides: [reposDataSourceProvider.overrideWithValue(fakeDS)],
          ),
          child: MaterialApp(theme: theme, home: const ReposPage()),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ReposPage),
        matchesGoldenFile('goldens/repos_page_empty_$label.png'),
      );

      // error(403)
      fakeDS.mode = FakeReposMode.forbidden;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderContainer.test(
            retry: (_, _) => null,
            overrides: [reposDataSourceProvider.overrideWithValue(fakeDS)],
          ),
          child: MaterialApp(theme: theme, home: const ReposPage()),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ReposPage),
        matchesGoldenFile('goldens/repos_page_error403_$label.png'),
      );
    }
  });
}
