import 'package:cna/core/theme/app_tokens.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 提交摘要：message、等宽 hash、作者与已本地化的时间文案。
class CommitTile extends StatelessWidget {
  /// 创建提交摘要；数据转换与导航由调用方负责。
  const new({
    required this.hash,
    required this.message,
    required this.author,
    required this.timeLabel,
    super.key,
    this.onTap,
  });

  /// 完整或调用方截短的提交 hash。
  final String hash;

  /// 提交说明。
  final String message;

  /// 作者显示名。
  final String author;

  /// 已按业务上下文本地化的时间。
  final String timeLabel;

  /// 可选业务动作，不在组件里构造路由。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final token = context.tTheme;
    final metadataStyle = AppTypography.label.copyWith(
      color: token.textColorSecondary,
    );

    return Material(
      color: token.bgColorContainer,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  color: token.textColorPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                hash,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.code.copyWith(color: token.brandColor),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: metadataStyle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                timeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: metadataStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
