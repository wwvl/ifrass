import 'package:cna/core/error/failure.dart';
import 'package:cna/features/repos/data/mappers/repo_mappers.dart';
import 'package:cna_api/cna_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('repoFromDto', () {
    test('全字段映射：计数/文本/布尔原样进入实体', () {
      const dto = DtoRepos4User(
        path: 'cnb/cna',
        name: 'cna',
        description: 'CNB 客户端',
        language: 'Dart',
        starCount: 128,
        forkCount: 12,
        openIssueCount: 5,
        openPullRequestCount: 2,
        license: 'MIT',
        lastUpdateUsername: 'cnb-dev',
        createdAt: '2026-11-01T00:00:00Z',
        stared: true,
        pinned: false,
      );

      final repo = repoFromDto(dto);

      expect(repo.path, 'cnb/cna');
      expect(repo.name, 'cna');
      expect(repo.description, 'CNB 客户端');
      expect(repo.language, 'Dart');
      expect(repo.starCount, 128);
      expect(repo.forkCount, 12);
      expect(repo.openIssueCount, 5);
      expect(repo.openPullRequestCount, 2);
      expect(repo.license, 'MIT');
      expect(repo.lastUpdateUsername, 'cnb-dev');
      expect(repo.createdAt, '2026-11-01T00:00:00Z');
      expect(repo.stared, true);
      expect(repo.pinned, false);
    });

    test('可空计数缺失收敛为 0（DTO 全字段可空的语义收敛）', () {
      const dto = DtoRepos4User(path: 'a/b', name: 'b');

      final repo = repoFromDto(dto);

      expect(repo.starCount, 0);
      expect(repo.forkCount, 0);
      expect(repo.openIssueCount, 0);
      expect(repo.openPullRequestCount, 0);
      expect(repo.description, isNull);
    });

    test('path 缺失视为契约破坏 → FailureParse', () {
      const dto = DtoRepos4User(name: 'b');

      expect(() => repoFromDto(dto), throwsA(isA<FailureParse>()));
    });

    test('path 为空字符串视为契约破坏 → FailureParse', () {
      const dto = DtoRepos4User(path: '', name: 'b');

      expect(() => repoFromDto(dto), throwsA(isA<FailureParse>()));
    });

    test('name 缺失视为契约破坏 → FailureParse', () {
      const dto = DtoRepos4User(path: 'a/b');

      expect(() => repoFromDto(dto), throwsA(isA<FailureParse>()));
    });

    test('批量映射保持顺序', () {
      const dtos = <DtoRepos4User>[
        DtoRepos4User(path: 'a/one', name: 'one'),
        DtoRepos4User(path: 'a/two', name: 'two'),
      ];

      final repos = reposFromDtos(dtos);

      expect(repos.map((r) => r.path), <String>['a/one', 'a/two']);
    });
  });
}
