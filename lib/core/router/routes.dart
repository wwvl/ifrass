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

  /// 离线提示页（网络不可达，不伪装成空态）。✅
  static const String offline = '/offline';

  /// 会话过期页（401 复位后的信息页）。✅
  static const String sessionExpired = '/session-expired';

  /// 仓库详情（Shell：code / issues / pulls / releases / build / settings）。✅
  static String repo({required String owner, required String name}) =>
      '/repo/$owner/$name';

  /// 仓库详情 · code 子页（各子页独立导航栈）。✅
  static String repoCode({required String owner, required String name}) =>
      '/repo/$owner/$name/code';

  /// 仓库详情 · issues 子页。✅
  static String repoIssues({required String owner, required String name}) =>
      '/repo/$owner/$name/issues';

  /// 仓库详情 · pulls 子页。✅
  static String repoPulls({required String owner, required String name}) =>
      '/repo/$owner/$name/pulls';

  /// 仓库详情 · releases 子页。✅
  static String repoReleases({required String owner, required String name}) =>
      '/repo/$owner/$name/releases';

  /// 仓库详情 · build 子页。✅
  static String repoBuild({required String owner, required String name}) =>
      '/repo/$owner/$name/build';

  /// 仓库详情 · settings 子页。✅
  static String repoSettings({required String owner, required String name}) =>
      '/repo/$owner/$name/settings';

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
