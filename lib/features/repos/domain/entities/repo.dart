import 'package:freezed_annotation/freezed_annotation.dart';

part 'repo.freezed.dart';

/// 仓库实体（domain 层，字段对齐生成 DTO `DtoRepos4User`，经 mapper 转入）。
///
/// 只收录仓库列表 / 详情页（M3 垂直切片）需要的字段；DTO 全字段可空，
/// 可空语义在 mapper 中收敛（计数类缺失归 0，path/name 缺失视为契约破坏）。
/// 字段名与真实 DTO 保持一致，便于 mapper 对照与后续扩展。
@freezed
sealed class Repo with _$Repo {
  /// 创建仓库实体。
  const factory({
    /// 仓库全路径（owner/name），详情与跳转的唯一标识。
    required String path,

    /// 仓库名（path 的最后一段）。
    required String name,

    /// 简介。
    String? description,

    /// 主语言（`AppLanguageColors` 色条依据）。
    String? language,

    /// star 数。
    @Default(0) int starCount,

    /// fork 数。
    @Default(0) int forkCount,

    /// 开放 Issue 数。
    @Default(0) int openIssueCount,

    /// 开放 PR 数。
    @Default(0) int openPullRequestCount,

    /// 开源协议。
    String? license,

    /// 最后更新者用户名。
    String? lastUpdateUsername,

    /// 创建时间（服务端字符串原样）。
    String? createdAt,

    /// 当前访问者是否已 star（visitor 视角，DTO 同名字段）。
    bool? stared,

    /// 是否置顶。
    bool? pinned,
  }) = _Repo;
}
