import 'package:cna/core/storage/in_memory_secure_storage.dart';
import 'package:cna/core/storage/secure_storage_provider.dart';
import 'package:cna/core/theme/tdesign_theme.dart';
import 'package:cna/core/theme/theme.dart';
import 'package:cna/features/auth/data/datasource/fake_auth_data_source.dart';
import 'package:cna/features/auth/presentation/pages/splash_page.dart';
import 'package:cna/features/auth/presentation/state/auth_notifier.dart';
import 'package:cna/features/home/presentation/pages/home_page.dart';
import 'package:cna/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

void main() {
  // M2 起从路由入口启动：整 App 浅/深 smoke。
  // M0 的三条 Token 断言原样保留（DESIGN.md §1.2 硬规则）：
  // 1) 主题扩展必须安装；2) 深色扩展必须是指向 root.dark 的同一实例；
  // 3) 浅深两套底色不同。
  Future<ProviderContainer> containerWith(
    WidgetTester tester,
    Brightness brightness,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final storage = InMemorySecureStorage();
    await storage.writeToken('smoke-token');
    final container = ProviderContainer.test(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        // 预置 token + 慢校验 → restore 期间稳定停留 splash，供断言取上下文
        authDataSourceProvider.overrideWithValue(FakeAuthDataSource()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  testWidgets('浅色：路由入口渲染，主题携带浅色 Token 扩展', (tester) async {
    final container = await containerWith(tester, Brightness.light);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const CnaApp()),
    );
    await tester.pump();

    expect(find.byType(SplashPage), findsOneWidget);
    final context = tester.element(find.text('CNB'));
    expect(Theme.of(context).brightness, Brightness.light);
    expect(
      identical(Theme.of(context).extension<TThemeData>(), AppThemeTokens.root),
      isTrue,
    );

    // restore 落定（预置 token 校验通过 → SignedIn）→ 守卫送首页占位
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byType(SplashPage), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('深色：主题随系统切深，扩展为深色 Token 且两套底色不同', (tester) async {
    final container = await containerWith(tester, Brightness.dark);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const CnaApp()),
    );
    await tester.pump();

    expect(find.byType(SplashPage), findsOneWidget);
    final context = tester.element(find.text('CNB'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(
      identical(
        Theme.of(context).extension<TThemeData>(),
        AppThemeTokens.root.dark,
      ),
      isTrue,
    );
    // 浅色底色取自浅色主题桥（当前 context 是深色，不能从 context 取「浅色」）
    final lightToken = buildLightAppTheme().extension<TThemeData>()!;
    final darkToken = AppThemeTokens.root.dark!;
    expect(darkToken.bgColorPage, isNot(lightToken.bgColorPage));

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });
}
