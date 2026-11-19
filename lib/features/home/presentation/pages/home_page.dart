import 'package:cna/core/router/routes.dart';
import 'package:cna/core/theme/app_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 首页（M3 占位入口）：动态 / 最近仓库两个入口块，不做瀑布卡片。
/// M3 只负责把「登录 → 列表」主链路的入口挂上；动态流在后续里程碑接入。
class HomePage extends StatelessWidget {
  /// 创建首页。
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TNavBar(title: Text('CNB')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _EntryCard(
            title: '动态',
            description: '你关注仓库与用户的最新动态。后续里程碑接入。',
            onTap: () {}, // 占位：动态流未接入，无跳转
          ),
          const SizedBox(height: AppSpacing.md),
          _EntryCard(
            title: '最近仓库',
            description: '进入仓库列表查看与搜索你的仓库。',
            onTap: () => context.push(AppRoutes.repos),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const new({
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.tTheme.bgColorContainer,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.title.copyWith(
                  color: context.tTheme.textColorPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: AppTypography.body.copyWith(
                  color: context.tTheme.textColorSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
