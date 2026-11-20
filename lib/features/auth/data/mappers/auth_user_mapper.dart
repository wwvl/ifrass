/// 认证用户生成 DTO → domain 值。
library;

import 'package:cna/features/auth/domain/entities/auth_user.dart';
import 'package:cna_api/cna_api.dart';

/// 把真实 `DtoUsersResult` 字段映射到 auth domain；可选字段保持 nullable。
AuthUser authUserFromDto(DtoUsersResult dto) => AuthUser(
  id: dto.id,
  nickname: dto.nickname,
  avatar: dto.avatar,
  email: dto.email,
  bio: dto.bio,
  company: dto.company,
  location: dto.location,
  createdAt: dto.createdAt,
);
