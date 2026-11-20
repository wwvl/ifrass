import 'package:meta/meta.dart';

/// 已由 CNB `GET /user` 校验的当前用户信息。
///
/// 所有字段维持生成 DTO 的可空语义；PAT 是否有效以服务端 200 响应为准，
/// 不额外假定某个用户字段一定存在。
@immutable
final class AuthUser {
  /// 创建用户领域值。
  const new({
    this.id,
    this.nickname,
    this.avatar,
    this.email,
    this.bio,
    this.company,
    this.location,
    this.createdAt,
  });

  /// CNB 用户标识。
  final String? id;

  /// 昵称。
  final String? nickname;

  /// 头像地址。
  final String? avatar;

  /// 邮箱。
  final String? email;

  /// 个人简介。
  final String? bio;

  /// 公司。
  final String? company;

  /// 所在地。
  final String? location;

  /// 创建时间（服务端字符串原样）。
  final String? createdAt;

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.id == id &&
      other.nickname == nickname &&
      other.avatar == avatar &&
      other.email == email &&
      other.bio == bio &&
      other.company == company &&
      other.location == location &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    nickname,
    avatar,
    email,
    bio,
    company,
    location,
    createdAt,
  );
}
