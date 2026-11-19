import 'package:go_router/go_router.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 底部导航壳：`StatefulShellRoute.indexedStack` 的容器，
/// 各 Tab 独立导航栈（AGENTS.md §7）。
class AppShell extends StatelessWidget {
  /// 创建导航壳。
  const new({required this.navigationShell, super.key});

  /// 分支导航壳（切换 / 保留各 Tab 状态）。
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: TTabBar(
        type: TTabBarType.text,
        navigationTabs: const [
          TTabBarItemConfig(tabText: '首页'),
          TTabBarItemConfig(tabText: '仓库'),
          TTabBarItemConfig(tabText: '设置'),
        ],
        value: navigationShell.currentIndex,
        onChanged: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
