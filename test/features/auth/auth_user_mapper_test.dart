import 'package:cna/features/auth/data/mappers/auth_user_mapper.dart';
import 'package:cna/features/auth/domain/entities/auth_user.dart';
import 'package:cna_api/cna_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DtoUsersResult 真实字段映射到领域结果', () {
    const dto = DtoUsersResult(
      id: 'user-id',
      nickname: 'display-name',
      username: 'login-name',
      avatar: 'https://example.test/avatar.png',
      email: 'user@example.test',
      bio: 'bio',
      company: 'company',
      location: 'location',
      createdAt: '2026-01-02T03:04:05Z',
    );

    final user = authUserFromDto(dto);

    expect(
      user,
      const AuthUser(
        id: 'user-id',
        nickname: 'display-name',
        avatar: 'https://example.test/avatar.png',
        email: 'user@example.test',
        bio: 'bio',
        company: 'company',
        location: 'location',
        createdAt: '2026-01-02T03:04:05Z',
      ),
    );
  });

  test('生成 DTO 的 null/缺失字段保持 nullable，不造默认值', () {
    const dto = DtoUsersResult();

    expect(authUserFromDto(dto), const AuthUser());
  });
}
