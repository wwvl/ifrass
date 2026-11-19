import 'package:cna/core/error/failure.dart';
import 'package:cna/features/auth/data/datasource/fake_auth_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('任意非空 token 校验成功，返回字段名对齐真实 DtoUsersResult 的种子', () async {
    final ds = FakeAuthDataSource(delay: Duration.zero);

    final user = await ds.verify('good-token');

    expect(user.id, 'user-1');
    expect(user.nickname, 'cnb-dev');
    expect(user.avatar, isNotNull);
    expect(user.email, isNotNull);
  });

  test('固定 invalid token 触发 401', () async {
    final ds = FakeAuthDataSource(
      delay: Duration.zero,
      invalidToken: 'invalid-token',
    );

    await expectLater(
      ds.verify('invalid-token'),
      throwsA(isA<FailureUnauthorized>()),
    );
    // 其他 token 不受影响
    await expectLater(ds.verify('good-token'), completes);
  });

  test('固定 networkFail token 触发网络失败', () async {
    final ds = FakeAuthDataSource(
      delay: Duration.zero,
      networkFailToken: 'net-fail',
    );

    await expectLater(ds.verify('net-fail'), throwsA(isA<FailureNetwork>()));
  });

  test('空 token 抛 400（表单校验的 DS 兜底）', () async {
    final ds = FakeAuthDataSource(delay: Duration.zero);

    await expectLater(
      ds.verify('   '),
      throwsA(isA<FailureHttp>().having((f) => f.status, 'status', 400)),
    );
  });

  test('可注入慢响应：delay 下限生效（供 splash 停留态驱动）', () async {
    final ds = FakeAuthDataSource(delay: const Duration(milliseconds: 80));

    final watch = Stopwatch()..start();
    await ds.verify('good-token');
    watch.stop();

    expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(80));
  });
}
