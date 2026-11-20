import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

/// 已由 CNB `GET /user` 校验的当前用户信息。
///
/// 所有字段维持生成 DTO 的可空语义；PAT 是否有效以服务端 200 响应为准，
/// 不额外假定某个用户字段一定存在。
@freezed
sealed class AuthUser with _$AuthUser {
  /// 创建用户领域值。
  const factory({
    /// CNB 用户标识。
    String? id,

    /// 昵称。
    String? nickname,

    /// 头像地址。
    String? avatar,

    /// 邮箱。
    String? email,

    /// 个人简介。
    String? bio,

    /// 公司。
    String? company,

    /// 所在地。
    String? location,

    /// 创建时间（服务端字符串原样）。
    String? createdAt,
  }) = _AuthUser;
}
