import 'package:cna/core/error/failure.dart';
import 'package:cna/features/auth/data/datasource/remote_auth_data_source.dart';
import 'package:cna/features/auth/domain/entities/auth_user.dart';
import 'package:cna_api/cna_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersApi extends Mock implements UsersApi;

Response<dynamic> _response(int status, [Object? data]) => Response<dynamic>(
  requestOptions: RequestOptions(path: '/user'),
  statusCode: status,
  data: data,
);

void main() {
  late _MockUsersApi usersApi;
  late RemoteAuthDataSource dataSource;

  setUp(() {
    usersApi = _MockUsersApi();
    dataSource = RemoteAuthDataSource(usersApi: usersApi);
  });

  test('通过 UsersApi sealed success 返回 mapper 领域结果并传候选 token', () async {
    when(() => usersApi.getUserInfo(options: any(named: 'options'))).thenAnswer(
      (_) async => const GetUserInfoResultHttp200(
        DtoUsersResult(id: 'id-1', nickname: 'nick', avatar: 'avatar'),
      ),
    );

    final user = await dataSource.verify('candidate-token');

    expect(
      user,
      const AuthUser(id: 'id-1', nickname: 'nick', avatar: 'avatar'),
    );
    final captured =
        verify(
              () => usersApi.getUserInfo(options: captureAny(named: 'options')),
            ).captured.single
            as Options;
    expect(captured.method, 'get');
    expect(captured.headers?['Authorization'], 'Bearer candidate-token');
  });

  test('sealed error 401 抛 FailureUnauthorized', () async {
    when(() => usersApi.getUserInfo(options: any(named: 'options'))).thenAnswer(
      (_) async => GetUserInfoResultError(_response(401, 'expired')),
    );

    await expectLater(
      dataSource.verify('candidate-token'),
      throwsA(isA<FailureUnauthorized>()),
    );
  });

  test('sealed error 保留其他 HTTP status', () async {
    when(
      () => usersApi.getUserInfo(options: any(named: 'options')),
    ).thenAnswer((_) async => GetUserInfoResultError(_response(403, 'scope')));

    await expectLater(
      dataSource.verify('candidate-token'),
      throwsA(
        isA<FailureHttp>().having((failure) => failure.status, 'status', 403),
      ),
    );
  });

  test('Dio 拦截器已映射的 Failure 原样传播', () async {
    const failure = FailureNetwork(message: 'offline');
    when(() => usersApi.getUserInfo(options: any(named: 'options'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/user'),
        error: failure,
      ),
    );

    await expectLater(
      dataSource.verify('candidate-token'),
      throwsA(same(failure)),
    );
  });

  test('无效成功体类型在 generated DTO 解码处精确映射为 FailureParse', () async {
    when(() => usersApi.getUserInfo(options: any(named: 'options'))).thenAnswer(
      (_) async => GetUserInfoResult.fromResponse(_response(200, {'id': 123})),
    );

    await expectLater(
      dataSource.verify('candidate-token'),
      throwsA(isA<FailureParse>()),
    );
  });

  test('空 token 不发起 API 请求', () async {
    await expectLater(
      dataSource.verify('  '),
      throwsA(
        isA<FailureHttp>().having((failure) => failure.status, 'status', 400),
      ),
    );
    verifyNever(() => usersApi.getUserInfo());
  });
}
