import 'package:cna/core/theme/app_tokens.dart';
import 'package:cna/core/theme/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

void main() {
  runApp(const ProviderScope(child: CnaApp()));
}

/// 应用根组件（M0 工程骨架）。
///
/// 主题：浅/深两套完整 Token 经 [buildLightAppTheme] / [buildDarkAppTheme]
/// 交给 MaterialApp，跟随系统；设置页落地后由 themeProvider 接管 themeMode。
/// 本地化：legacy 三 delegate 全量注册（DESIGN.md §1.1，禁止半迁移）。
/// M1 接入 go_router 后改为 `MaterialApp.router`，届时删除占位首页。
class CnaApp extends StatelessWidget {
  /// 创建应用根组件。
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CNB',
      theme: buildLightAppTheme(),
      darkTheme: buildDarkAppTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      home: const _BootstrapPlaceholder(),
    );
  }
}

/// M0 占位首页：仅证明「Token → ThemeData → 渲染」链路与本地化可用。
/// 不属于业务页面；M1 由路由表接管后删除。
class _BootstrapPlaceholder extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'CNB',
          style: AppTypography.title.copyWith(
            color: context.tTheme.textColorPrimary,
          ),
        ),
      ),
    );
  }
}
