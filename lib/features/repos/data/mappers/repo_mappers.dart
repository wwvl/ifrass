/// 生成 DTO → domain 实体。DTO 到此为止，绝不进 UI（AGENTS.md §2）。
///
/// 可空语义收敛：计数类缺失归 0；`path` / `name` 是仓库的唯一定位，
/// 缺失视为契约破坏，抛 [FailureParse]（宁可早失败，不渲染脏数据）。
library;

import 'package:cna/core/error/failure.dart';
import 'package:cna/features/repos/domain/entities/repo.dart';
import 'package:cna_api/cna_api.dart';

/// `DtoRepos4User` → `Repo`（列表与详情共用同一 DTO 模型）。
Repo repoFromDto(DtoRepos4User dto) {
  final path = dto.path;
  final name = dto.name;
  if (path == null || path.isEmpty) {
    throw FailureParse('Repo DTO missing path (id=${dto.id})');
  }
  if (name == null || name.isEmpty) {
    throw FailureParse('Repo DTO missing name (path=$path)');
  }
  return Repo(
    path: path,
    name: name,
    description: dto.description,
    language: dto.language,
    starCount: dto.starCount ?? 0,
    forkCount: dto.forkCount ?? 0,
    openIssueCount: dto.openIssueCount ?? 0,
    openPullRequestCount: dto.openPullRequestCount ?? 0,
    license: dto.license,
    lastUpdateUsername: dto.lastUpdateUsername,
    createdAt: dto.createdAt,
    stared: dto.stared,
    pinned: dto.pinned,
  );
}

/// 批量映射。
List<Repo> reposFromDtos(List<DtoRepos4User> dtos) =>
    dtos.map(repoFromDto).toList(growable: false);
