import 'package:cna/core/error/failure.dart';
import 'package:cna/features/repos/data/datasource/repos_datasource.dart';
import 'package:cna_api/cna_api.dart';

/// Fake 行为模式：对应 UI 五态的可测试输入（DESIGN.md §8）。
enum FakeReposMode {
  /// 正常返回种子数据。
  normal,

  /// 空列表（empty 态）。
  empty,

  /// 403：有令牌但无权限（「令牌授权范围不足」差异化文案）。
  forbidden,

  /// 网络不可达（offline 态）。
  offline,
}

/// 假数据源：字段名与生成 DTO `DtoRepos4User` 完全对齐。
///
/// 用途：M3 UI 联调与 Widget 测试在接入真数据前驱动五态；带模拟延时，
/// `delay` 可注入 `Duration.zero` 加速测试。仅用于开发与测试装配，
/// 生产装配（M2）必须使用远程数据源实现。
class FakeReposDataSource implements ReposDataSource {
  /// 创建假数据源。
  new({
    this.delay = const Duration(milliseconds: 300),
    this.mode = FakeReposMode.normal,
  });

  /// 模拟网络延时。
  final Duration delay;

  /// 当前行为模式。
  final FakeReposMode mode;

  /// 种子数据：与 cnb.cool 真实仓库形态对齐（path/name/language/计数）。
  static final List<DtoRepos4User> _seedRepos = <DtoRepos4User>[
    const DtoRepos4User(
      path: 'cnb/cna',
      name: 'cna',
      description: 'cnb.cool 第三方移动端客户端（Flutter）',
      language: 'Dart',
      starCount: 128,
      forkCount: 12,
      openIssueCount: 5,
      openPullRequestCount: 2,
      license: 'MIT',
      lastUpdateUsername: 'cnb-dev',
      createdAt: '2026-11-01T00:00:00Z',
      stared: false,
      pinned: true,
    ),
    const DtoRepos4User(
      path: 'cnb/cnb-rs',
      name: 'cnb-rs',
      description: 'CNB OpenAPI 的 Rust CLI / SDK（参考实现）',
      language: 'Rust',
      starCount: 342,
      forkCount: 28,
      openIssueCount: 11,
      openPullRequestCount: 4,
      license: 'Apache-2.0',
      lastUpdateUsername: 'cnb-dev',
      createdAt: '2026-08-15T00:00:00Z',
      stared: true,
      pinned: false,
    ),
    const DtoRepos4User(
      path: 'tencent/tdesign-flutter',
      name: 'tdesign-flutter',
      description: 'TDesign 组件库 Flutter 实现',
      language: 'Dart',
      starCount: 2048,
      forkCount: 196,
      openIssueCount: 42,
      openPullRequestCount: 9,
      license: 'MIT',
      lastUpdateUsername: 'tdesign-bot',
      createdAt: '2025-03-20T00:00:00Z',
      stared: true,
      pinned: false,
    ),
  ];

  @override
  Future<List<DtoRepos4User>> listRepos({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    await Future<void>.delayed(delay);
    switch (mode) {
      case FakeReposMode.offline:
        throw const FailureNetwork(message: 'fake offline');
      case FakeReposMode.forbidden:
        throw const FailureHttp(403, body: 'token scope insufficient');
      case FakeReposMode.empty:
        return const <DtoRepos4User>[];
      case FakeReposMode.normal:
        final filtered = _filterBySearch(search);
        final start = (page - 1) * pageSize;
        return List<DtoRepos4User>.unmodifiable(
          filtered.skip(start).take(pageSize),
        );
    }
  }

  @override
  Future<DtoRepos4User> getRepo({required String path}) async {
    await Future<void>.delayed(delay);
    switch (mode) {
      case FakeReposMode.offline:
        throw const FailureNetwork(message: 'fake offline');
      case FakeReposMode.forbidden:
        throw const FailureHttp(403, body: 'token scope insufficient');
      case FakeReposMode.empty:
      case FakeReposMode.normal:
        for (final dto in _seedRepos) {
          if (dto.path == path) return dto;
        }
        throw FailureHttp(404, body: 'repo not found: $path');
    }
  }

  /// search 命中 path / name / description（大小写不敏感，模拟服务端过滤）。
  List<DtoRepos4User> _filterBySearch(String? search) {
    final query = search?.trim().toLowerCase() ?? '';
    if (query.isEmpty) return _seedRepos;
    return _seedRepos
        .where(
          (dto) =>
              (dto.path ?? '').toLowerCase().contains(query) ||
              (dto.name ?? '').toLowerCase().contains(query) ||
              (dto.description ?? '').toLowerCase().contains(query),
        )
        .toList(growable: false);
  }
}
