import 'package:cna/core/theme/app_tokens.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 仓库详情壳（页面内部 Tab：TTabsBar + IndexedStack）。
///
/// 与 M2 底部导航的 `StatefulShellRoute` 是两层概念，互不混淆。
/// 形态说明：go_router 断言「StatefulShellBranch 的 default location 不得
/// 参数化」（configuration.dart:149），而本页路径 `/repo/:owner/:name/*`
/// 必带参——因此子页独立状态用**页内 IndexedStack**（各子页状态独立保留），
/// 子路径的路由化深链（`routes.dart` 的 repoCode 等 builder）留 M5 内容化时
/// 配合 query 方案扩展。
class RepoShellPage extends StatefulWidget {
  /// 创建详情壳。
  const new({required this.owner, required this.name, super.key});

  /// 仓库 owner。
  final String owner;

  /// 仓库名。
  final String name;

  @override
  State<RepoShellPage> createState() => _RepoShellPageState();
}

class _RepoShellPageState extends State<RepoShellPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  static const List<String> _tabLabels = <String>[
    'Code',
    'Issues',
    'Pulls',
    'Releases',
    'Build',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TNavBar(
        title: Text(
          widget.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.title.copyWith(
            color: context.tTheme.textColorPrimary,
          ),
        ),
        useDefaultBack: true,
        belowTitleWidget: Text(
          widget.owner,
          style: AppTypography.label.copyWith(
            color: context.tTheme.textColorSecondary,
          ),
        ),
      ),
      body: Column(
        children: [
          TTabsBar(
            controller: _tabController,
            tabs: _tabLabels.map((label) => TTab(text: label)).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabLabels.length, (i) {
                return RepoTabPlaceholder(
                  label: _tabLabels[i],
                  owner: widget.owner,
                  name: widget.name,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// 详情子页占位（M5 填真实内容；展示参数验证深链带参）。
class RepoTabPlaceholder extends StatelessWidget {
  /// 创建子页占位。
  const new({
    required this.label,
    required this.owner,
    required this.name,
    super.key,
  });

  /// 子页名（Code / Issues / …）。
  final String label;

  /// 仓库 owner。
  final String owner;

  /// 仓库名。
  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.title.copyWith(
              color: context.tTheme.textColorPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$owner/$name 的 $label 内容将在后续里程碑提供。',
            style: AppTypography.body.copyWith(
              color: context.tTheme.textColorSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
