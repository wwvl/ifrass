import 'package:cna/core/router/app_router.dart';
import 'package:cna/core/theme/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

void main() {
  runApp(
    ProviderScope(
      // AGENTS.md §5：Riverpod 3 自动重试全局关闭（默认 10 次指数退避会放大
      // 请求量并让 error 态闪烁）。错误态由 AsyncStateHost 稳定呈现，
      // 重试只走用户驱动的 UI 按钮；M4 网络层重试收口在 Dio interceptor 一处。
      retry: (retryCount, error) => null,
      child: const CnaApp(),
    ),
  );
}

/// 应用根组件（M2：go_router 接管导航，M0 占位首页已删）。
///
/// 主题：浅/深两套完整 Token 经 [buildLightAppTheme] / [buildDarkAppTheme]
/// 交给 MaterialApp，跟随系统；设置页落地后由 themeProvider 接管 themeMode。
/// 本地化：legacy 三 delegate 全量注册（DESIGN.md §1.1，禁止半迁移）。
/// 守卫与 refreshListenable 桥接见 `core/router/app_router.dart`。
class CnaApp extends ConsumerWidget {
  /// 创建应用根组件。
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'CNB',
      routerConfig: ref.watch(appRouterProvider),
      theme: buildLightAppTheme(),
      darkTheme: buildDarkAppTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
    );
  }
}
