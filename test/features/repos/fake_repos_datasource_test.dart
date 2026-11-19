import 'package:cna/core/error/failure.dart';
import 'package:cna/features/repos/data/datasource/fake_repos_datasource.dart';
import 'package:cna/features/repos/data/mappers/repo_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeReposDataSource.listRepos', () {
    test('normal：按 page/pageSize 切片（page 2 取余量，page 3 为空）', () async {
      final ds = FakeReposDataSource(delay: Duration.zero);

      final page1 = await ds.listRepos(page: 1, pageSize: 2);
      final page2 = await ds.listRepos(page: 2, pageSize: 2);
      final page3 = await ds.listRepos(page: 3, pageSize: 2);

      expect(page1, hasLength(2));
      expect(page1.first.path, 'cnb/cna');
      expect(page2, hasLength(1));
      expect(page3, isEmpty);
    });

    test('normal：search 命中 path/name/description，大小写不敏感', () async {
      final ds = FakeReposDataSource(delay: Duration.zero);

      final hit = await ds.listRepos(page: 1, pageSize: 10, search: 'TDESIGN');
      final byPath = await ds.listRepos(
        page: 1,
        pageSize: 10,
        search: 'cnb-rs',
      );
      final miss = await ds.listRepos(page: 1, pageSize: 10, search: '不存在关键字');

      expect(hit, hasLength(1));
      expect(hit.single.path, 'tencent/tdesign-flutter');
      expect(byPath, hasLength(1));
      expect(byPath.single.path, 'cnb/cnb-rs');
      expect(miss, isEmpty);
    });

    test('empty：返回空列表（empty 态输入）', () async {
      final ds = FakeReposDataSource(
        delay: Duration.zero,
        mode: FakeReposMode.empty,
      );

      expect(await ds.listRepos(page: 1, pageSize: 10), isEmpty);
    });

    test('forbidden：抛 FailureHttp(403)', () async {
      final ds = FakeReposDataSource(
        delay: Duration.zero,
        mode: FakeReposMode.forbidden,
      );

      await expectLater(
        ds.listRepos(page: 1, pageSize: 10),
        throwsA(isA<FailureHttp>().having((f) => f.status, 'status', 403)),
      );
    });

    test('offline：抛 FailureNetwork（offline 态输入）', () async {
      final ds = FakeReposDataSource(
        delay: Duration.zero,
        mode: FakeReposMode.offline,
      );

      await expectLater(
        ds.listRepos(page: 1, pageSize: 10),
        throwsA(isA<FailureNetwork>()),
      );
    });
  });

  group('FakeReposDataSource.getRepo', () {
    test('命中种子 path 返回详情', () async {
      final ds = FakeReposDataSource(delay: Duration.zero);

      final dto = await ds.getRepo(path: 'cnb/cna');

      expect(dto.name, 'cna');
    });

    test('未命中抛 FailureHttp(404)', () async {
      final ds = FakeReposDataSource(delay: Duration.zero);

      await expectLater(
        ds.getRepo(path: 'ghost/nope'),
        throwsA(isA<FailureHttp>().having((f) => f.status, 'status', 404)),
      );
    });
  });

  test('种子数据字段名与真实 DTO 对齐：全部可经 repoFromDto 转实体', () async {
    // 用户要求「假数据字段名必须对齐真实 DTO」——用 mapper 链路做契约验证：
    // 任何字段名拼错（DTO 里不存在）在 const 构造期就会编译失败；
    // 本测试再保证种子数据无 path/name 缺失，FakeDS → mapper 链路可用。
    final ds = FakeReposDataSource(delay: Duration.zero);

    final dtos = await ds.listRepos(page: 1, pageSize: 10);

    expect(dtos, isNotEmpty);
    for (final dto in dtos) {
      expect(() => repoFromDto(dto), returnsNormally);
    }
  });
}
