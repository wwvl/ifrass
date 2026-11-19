/// 路由常量表（AGENTS.md §7；禁止在 Widget 里拼字符串路径）。
///
/// M0 只落常量与 path builder：不建 GoRouter、不写 redirect（M1 接入）。
/// 标注 ✅ 为一期路由，⬜ 为占位路由（MVP 后续放开）。
abstract final class AppRoutes {
  /// 启动解析 AuthState。✅
  static const String splash = '/splash';

  /// PAT 登录 / 权限说明。✅
  static const String login = '/login';

  /// 首页（动态 / 最近仓库）。✅
  static const String home = '/';

  /// 仓库列表（分页 + 搜索）。✅
  static const String repos = '/repos';

  /// 全局搜索。⬜ 占位
  static const String search = '/search';

  /// 工作台。⬜ 占位
  static const String workspace = '/workspace';

  /// 制品库。⬜ 占位
  static const String registries = '/registries';

  /// 任务集。⬜ 占位
  static const String missions = '/missions';

  /// Wiki。⬜ 占位
  static const String wiki = '/wiki';

  /// 设置（主题、语言、列表密度、退出登录）。✅
  static const String settings = '/settings';

  /// 仓库详情（Shell：code / issues / pulls / releases / build）。✅
  static String repo({required String owner, required String name}) =>
      '/repo/$owner/$name';

  /// Issue 详情 + 评论。✅
  static String repoIssue({
    required String owner,
    required String name,
    required String id,
  }) => '/repo/$owner/$name/issue/$id';

  /// PR 详情 + review + files。✅
  static String repoPull({
    required String owner,
    required String name,
    required String id,
  }) => '/repo/$owner/$name/pull/$id';

  /// 构建日志流（只读）。✅
  static String buildLogs({required String id}) => '/build/$id/logs';
}
