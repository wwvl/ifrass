import 'package:cna/core/theme/app_tokens.dart';
import 'package:cna/features/repos/domain/entities/repo.dart';
import 'package:cna/shared/widgets/language_bar.dart';
import 'package:cna/shared/widgets/meta_row.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 仓库卡片（DESIGN.md §6 点名组件）：字段严格取自 Repo 实体。
///
/// 防溢出：仓库名单行省略、描述两行省略（DESIGN.md §9）；
/// 颜色走 `context.tTheme`，间距走 [AppSpacing]，字排走 [AppTypography]。
class RepoCard extends StatelessWidget {
  /// 创建仓库卡片。
  const new({required this.repo, super.key, this.onTap});

  /// 仓库实体（UI 只认实体，DTO 不得进入本层）。
  final Repo repo;

  /// 点击回调（列表页跳详情）。
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Material(
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        repo.path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(
                          color: context.tTheme.textColorPrimary,
                        ),
                      ),
                    ),
                    if (repo.stared == true) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        TIcons.star,
                        size: 16,
                        color: context.tTheme.brandColor,
                      ),
                    ],
                  ],
                ),
                if (repo.description != null &&
                    repo.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    repo.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: context.tTheme.textColorSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                LanguageBar(language: repo.language),
                const SizedBox(height: AppSpacing.sm),
                MetaRow(
                  items: [
                    MetaItem(icon: TIcons.star, label: '${repo.starCount}'),
                    MetaItem(icon: TIcons.fork, label: '${repo.forkCount}'),
                    MetaItem(label: 'Issue ${repo.openIssueCount}'),
                    MetaItem(label: 'PR ${repo.openPullRequestCount}'),
                    if (repo.lastUpdateUsername != null)
                      MetaItem(label: '@${repo.lastUpdateUsername}'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
