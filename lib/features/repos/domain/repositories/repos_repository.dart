import 'package:cna/core/error/failure.dart';
import 'package:cna/features/repos/domain/entities/repo.dart';

/// 仓库域仓储抽象（AGENTS.md §2 分层铁律：接口在 domain，实现在 data）。
///
/// 本接口是 §9 预留的替换缝：未来下沉 Rust 时只换 data 层实现，
/// 本文件与 UI / state 层一行不动。domain 纯 Dart——不认识 Dio、
/// 生成客户端与 Flutter；失败统一抛 [Failure]。
abstract interface class ReposRepository {
  /// 分页列出当前令牌可见的仓库（`page` 从 1 起）。
  ///
  /// 是否还有下一页由调用方以 `list.length == pageSize` 判定
  /// （CNB `GET /repos` 无 total 字段，与生成客户端 `getRepos` 对齐）。
  Future<List<Repo>> listRepos({
    required int page,
    required int pageSize,
    String? search,
  });

  /// 按 path（owner/name）取仓库详情；不存在抛 `FailureHttp(404)`。
  Future<Repo> getRepo({required String path});
}
