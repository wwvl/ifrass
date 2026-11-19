import 'package:cna/core/error/failure.dart';
import 'package:cna/core/theme/theme.dart';
import 'package:cna/features/repos/domain/entities/repo.dart' show Repo;
import 'package:cna/features/repos/domain/entities/repo.dart';
import 'package:cna/shared/widgets/async_state_view.dart';
import 'package:cna/shared/widgets/error_view.dart';
import 'package:cna/shared/widgets/paged_list.dart';
import 'package:cna/shared/widgets/repo_card.dart';
import 'package:cna/shared/widgets/skeleton_repo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// golden / 组件测试壳：真主题桥（浅/深各一套完整 Token）。
Widget _shell({required Brightness brightness, required Widget child}) {
  return MaterialApp(
    theme: brightness == Brightness.light
        ? buildLightAppTheme()
        : buildDarkAppTheme(),
    home: Scaffold(body: child),
  );
}

Repo _repo({
  String path = 'cnb/cna',
  String? description = 'cnb.cool 第三方移动端客户端（Flutter）',
  String? language = 'Dart',
  bool? stared = true,
  int starCount = 128,
}) {
  return Repo(
    path: path,
    name: path.split('/').last,
    description: description,
    language: language,
    starCount: starCount,
    forkCount: 12,
    openIssueCount: 5,
    openPullRequestCount: 2,
    license: 'MIT',
    lastUpdateUsername: 'cnb-dev',
  );
}

void main() {
  group('RepoCard', () {
    testWidgets('字段渲染：path / 描述 / 语言 / 计数 / 更新者', (tester) async {
      await tester.pumpWidget(
        _shell(
          brightness: Brightness.light,
          child: RepoCard(repo: _repo()),
        ),
      );

      expect(find.text('cnb/cna'), findsOneWidget);
      expect(find.text('cnb.cool 第三方移动端客户端（Flutter）'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('128'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Issue 5'), findsOneWidget);
      expect(find.text('PR 2'), findsOneWidget);
      expect(find.text('@cnb-dev'), findsOneWidget);
    });

    testWidgets('stared=false 时卡片头不出现 star 角标（MetaRow 计数图标除外）', (tester) async {
      await tester.pumpWidget(
        _shell(
          brightness: Brightness.light,
          child: RepoCard(repo: _repo(stared: false)),
        ),
      );

      // MetaRow 的计数图标（size 14）始终存在；角标（size 16）只在 stared 时渲染
      final icons = tester.widgetList<Icon>(find.byIcon(TIcons.star)).toList();
      expect(icons.where((icon) => icon.size == 16), isEmpty);
      expect(icons.where((icon) => icon.size == 14), isNotEmpty);
    });

    testWidgets('语言缺失 → 兜底「未知语言」（不裸取 hex）', (tester) async {
      await tester.pumpWidget(
        _shell(
          brightness: Brightness.light,
          child: RepoCard(repo: _repo(language: null)),
        ),
      );

      expect(find.text('未知语言'), findsOneWidget);
    });

    testWidgets('长仓库名与长描述按策略省略（防 RIGHT OVERFLOWED）', (tester) async {
      await tester.pumpWidget(
        _shell(
          brightness: Brightness.light,
          child: SizedBox(
            width: 200,
            child: RepoCard(
              repo: _repo(
                path:
                    'very-long-owner/very-long-repository-name-that-should-'
                    'be-truncated-with-ellipsis',
                description: '这是一个非常长的描述' * 20,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final nameText = tester
          .widget<Text>(
            find.text(
              'very-long-owner/very-long-repository-name-that-should-'
              'be-truncated-with-ellipsis',
            ),
          )
          .overflow;
      expect(nameText, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });

    testWidgets('点击回调触发', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _shell(
          brightness: Brightness.light,
          child: RepoCard(repo: _repo(), onTap: () => tapped++),
        ),
      );

      await tester.tap(find.text('cnb/cna'));
      expect(tapped, 1);
    });

    testWidgets('golden：浅色', (tester) async {
      await tester.pumpWidget(
        _shell(
          brightness: Brightness.light,
          child: RepoCard(repo: _repo()),
        ),
      );
      await expectLater(
        find.byType(RepoCard),
        matchesGoldenFile('goldens/repo_card_light.png'),
      );
    });

    testWidgets('golden：深色', (tester) async {
      await tester.pumpWidget(
        _shell(
          brightness: Brightness.dark,
          child: RepoCard(repo: _repo()),
        ),
      );
      await expectLater(
        find.byType(RepoCard),
        matchesGoldenFile('goldens/repo_card_dark.png'),
      );
    });
  });

  group('AsyncStateHost', () {
    Widget host(
      WidgetTester tester, {
      required Brightness brightness,
      required AsyncValue<List<Repo>> async,
      VoidCallback? onRetry,
    }) {
      return _shell(
        brightness: brightness,
        child: AsyncStateHost<List<Repo>>(
          async: async,
          isEmpty: (items) => items.isEmpty,
          onRetry: onRetry,
          contentBuilder: (context, items) => PagedList<Repo>(
            items: items,
            itemBuilder: (context, item) => RepoCard(repo: item),
            hasMore: false,
            loadingMore: false,
            loadMoreFailed: false,
            onLoadMore: () {},
            onRetryLoadMore: () {},
          ),
        ),
      );
    }

    testWidgets('loading → 骨架屏（同真实布局尺寸）', (tester) async {
      await tester.pumpWidget(
        host(
          tester,
          brightness: Brightness.light,
          async: const AsyncLoading<List<Repo>>(),
        ),
      );

      expect(find.byType(SkeletonRepoCard), findsWidgets);
      expect(find.text('重试'), findsNothing);
    });

    testWidgets('empty → 「为什么空 + 下一步」', (tester) async {
      await tester.pumpWidget(
        host(
          tester,
          brightness: Brightness.light,
          async: const AsyncData<List<Repo>>([]),
        ),
      );

      expect(find.text('这里还没有内容'), findsOneWidget);
    });

    testWidgets('error → 差异化文案 + 重试按钮', (tester) async {
      await tester.pumpWidget(
        host(
          tester,
          brightness: Brightness.light,
          async: AsyncError<List<Repo>>(
            const FailureHttp(403, body: 'denied'),
            StackTrace.current,
          ),
          onRetry: () {},
        ),
      );

      expect(find.text('令牌授权范围不足'), findsOneWidget);
      expect(find.text('请在 CNB「个人设置 → 访问令牌」检查令牌的授权范围后重试。'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('offline（FailureNetwork）→ 离线视图，不伪装成空态', (tester) async {
      await tester.pumpWidget(
        host(
          tester,
          brightness: Brightness.light,
          async: AsyncError<List<Repo>>(
            const FailureNetwork(),
            StackTrace.current,
          ),
          onRetry: () {},
        ),
      );

      expect(find.text('网络不可用'), findsOneWidget);
    });

    testWidgets('content → 数据渲染', (tester) async {
      await tester.pumpWidget(
        host(
          tester,
          brightness: Brightness.light,
          async: AsyncData<List<Repo>>([_repo()]),
        ),
      );

      expect(find.text('cnb/cna'), findsOneWidget);
    });

    // 「AsyncLoading 携带旧值（刷新保数据）→ 呈现内容不闪骨架」由框架在
    // invalidate/refresh 时构造（AsyncLoading._ 私有），公开 API 无法直接造；
    // 该分支由第 2 步列表页的 refresh 竞态测试驱动覆盖。

    testWidgets('golden：五态 × 浅/深（10 张基线）', (tester) async {
      final states = <String, AsyncValue<List<Repo>>>{
        'loading': const AsyncLoading<List<Repo>>(),
        'empty': const AsyncData<List<Repo>>([]),
        'error': AsyncError<List<Repo>>(
          const FailureHttp(403, body: 'denied'),
          StackTrace.current,
        ),
        'offline': AsyncError<List<Repo>>(
          const FailureNetwork(),
          StackTrace.current,
        ),
        'content': AsyncData<List<Repo>>([_repo(stared: false)]),
      };
      for (final entry in states.entries) {
        for (final brightness in Brightness.values) {
          final label = brightness == Brightness.light ? 'light' : 'dark';
          await tester.pumpWidget(
            host(
              tester,
              brightness: brightness,
              async: entry.value,
              onRetry: () {},
            ),
          );
          await expectLater(
            find.byType(AsyncStateHost<List<Repo>>),
            matchesGoldenFile('goldens/async_state_${entry.key}_$label.png'),
          );
        }
      }
    });
  });

  group('ErrorView 文案分类', () {
    final cases = <Failure, String>{
      const FailureUnauthorized(): '登录已失效',
      const FailureHttp(403, body: 'denied'): '令牌授权范围不足',
      const FailureHttp(404, body: 'missing'): '资源不存在',
      const FailureHttp(500, body: 'boom'): '请求失败',
      const FailureParse('bad json'): '数据解析失败',
      const FailureNetwork(): '网络不可用',
      const FailureUnknown('???'): '出错了',
    };
    for (final entry in cases.entries) {
      testWidgets('Failure ${entry.key.runtimeType} → 「${entry.value}」', (
        tester,
      ) async {
        await tester.pumpWidget(
          _shell(
            brightness: Brightness.light,
            child: ErrorView(failure: entry.key),
          ),
        );
        expect(find.text(entry.value), findsOneWidget);
      });
    }
  });

  group('PagedList', () {
    testWidgets('footer：到底文案（hasMore=false）', (tester) async {
      await tester.pumpWidget(
        _shell(
          brightness: Brightness.light,
          child: PagedList<Repo>(
            items: [_repo()],
            itemBuilder: (context, item) => RepoCard(repo: item),
            hasMore: false,
            loadingMore: false,
            loadMoreFailed: false,
            onLoadMore: () {},
            onRetryLoadMore: () {},
          ),
        ),
      );

      expect(find.text('已经到底了'), findsOneWidget);
    });

    testWidgets('footer：加载中骨架行', (tester) async {
      await tester.pumpWidget(
        _shell(
          brightness: Brightness.light,
          child: PagedList<Repo>(
            items: [_repo()],
            itemBuilder: (context, item) => RepoCard(repo: item),
            hasMore: true,
            loadingMore: true,
            loadMoreFailed: false,
            onLoadMore: () {},
            onRetryLoadMore: () {},
          ),
        ),
      );

      expect(find.text('已经到底了'), findsNothing);
      expect(find.text('加载更多失败'), findsNothing);
    });

    testWidgets('footer：失败 + 重试回调', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        _shell(
          brightness: Brightness.light,
          child: PagedList<Repo>(
            items: [_repo()],
            itemBuilder: (context, item) => RepoCard(repo: item),
            hasMore: true,
            loadingMore: false,
            loadMoreFailed: true,
            onLoadMore: () {},
            onRetryLoadMore: () => retried++,
          ),
        ),
      );

      expect(find.text('加载更多失败'), findsOneWidget);
      await tester.tap(find.text('重试'));
      expect(retried, 1);
    });

    testWidgets('滚动到底触发 onLoadMore；加载中不重复触发', (tester) async {
      var loadMoreCalls = 0;
      final items = List.generate(30, (i) => _repo(path: 'cnb/repo-$i'));
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _shell(
          brightness: Brightness.light,
          child: PagedList<Repo>(
            items: items,
            itemBuilder: (context, item) => RepoCard(repo: item),
            hasMore: true,
            loadingMore: false,
            loadMoreFailed: false,
            onLoadMore: () => loadMoreCalls++,
            onRetryLoadMore: () {},
            controller: controller,
          ),
        ),
      );
      await tester.pump();
      expect(loadMoreCalls, 0); // 初始在顶部，未到底

      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      expect(loadMoreCalls, 1); // 到底触发一次

      // loadingMore=true 期间不重复触发
      await tester.pumpWidget(
        _shell(
          brightness: Brightness.light,
          child: PagedList<Repo>(
            items: items,
            itemBuilder: (context, item) => RepoCard(repo: item),
            hasMore: true,
            loadingMore: true,
            loadMoreFailed: false,
            onLoadMore: () => loadMoreCalls++,
            onRetryLoadMore: () {},
            controller: controller,
          ),
        ),
      );
      await tester.pump();
      expect(loadMoreCalls, 1);
    });

    testWidgets('golden：列表 loading / empty / error 骨架态 × 浅/深', (tester) async {
      for (final brightness in Brightness.values) {
        final label = brightness == Brightness.light ? 'light' : 'dark';
        await tester.pumpWidget(
          _shell(brightness: brightness, child: const SkeletonList(count: 2)),
        );
        await expectLater(
          find.byType(SkeletonList),
          matchesGoldenFile('goldens/list_skeleton_$label.png'),
        );
      }
    });
  });
}
