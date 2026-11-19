import 'package:cna/core/theme/app_tokens.dart';
import 'package:cna/shared/widgets/repo_card.dart' show RepoCard;
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 骨架基础块：与真实布局同尺寸的灰块，无动画（M3 形态；shimmer 后续统一加）。
class SkeletonBlock extends StatelessWidget {
  /// 创建骨架块。
  const new({required this.height, super.key, this.width});

  /// 块宽（null = 占满可用宽度）。
  final double? width;

  /// 块高。
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.tTheme.bgColorSecondaryComponent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}

/// 仓库卡片骨架：与 [RepoCard] 布局同尺寸（标题行 / 描述两行 / 语言 / 元信息）。
class SkeletonRepoCard extends StatelessWidget {
  /// 创建仓库卡片骨架。
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.tTheme.bgColorContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBlock(width: 16, height: 16),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: SkeletonBlock(height: 16)),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          SkeletonBlock(height: 12),
          SizedBox(height: AppSpacing.xs),
          SkeletonBlock(height: 12),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              SkeletonBlock(width: 64, height: 12),
              SizedBox(width: AppSpacing.sm),
              SkeletonBlock(width: 120, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// 列表骨架：若干张仓库卡片骨架（loading 态默认视图，与真实布局同尺寸）。
class SkeletonList extends StatelessWidget {
  /// 创建列表骨架（[count] 张骨架卡）。
  const new({super.key, this.count = 4});

  /// 骨架卡数量。
  final int count;

  @override
  Widget build(BuildContext context) {
    // 可滚动容器承载：骨架数量不受视口高度约束（防 RenderFlex overflowed）
    return SingleChildScrollView(
      child: Column(
        children: List.generate(count, (_) => const SkeletonRepoCard()),
      ),
    );
  }
}
