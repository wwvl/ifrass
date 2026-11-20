import 'package:cna/core/error/failure.dart';
import 'package:cna/core/network/error_mapper.dart';
import 'package:cna/features/auth/data/datasource/auth_data_source.dart';
import 'package:cna/features/auth/data/mappers/auth_user_mapper.dart';
import 'package:cna/features/auth/domain/entities/auth_user.dart';
import 'package:cna_api/cna_api.dart';
import 'package:dio/dio.dart';

/// `UsersApi.getUserInfo()` 的远程 PAT 校验实现。
class RemoteAuthDataSource implements AuthDataSource {
  /// 创建远程认证数据源。
  new({required this.usersApi});

  /// 共用网络层装配的 UsersApi。
  final UsersApi usersApi;

  @override
  Future<AuthUser> verify(String token) async {
    if (token.trim().isEmpty) {
      throw const FailureHttp(400, body: 'token must not be empty');
    }

    final GetUserInfoResult result;
    try {
      result = await usersApi.getUserInfo(
        options: Options(
          method: 'get',
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (error) {
      final mapped = error.error;
      if (mapped is Failure) {
        throw mapped;
      }
      throw failureFromDioException(error);
      // DTO parsing reports response shape violations as TypeError.
      // ignore: avoid_catching_errors
    } on TypeError catch (error) {
      // Generated DTO parsing executes after Dio's interceptor chain returns.
      throw FailureParse('无法解析 /user 响应字段: $error');
    } on FormatException catch (error) {
      throw FailureParse('无法解析 /user 响应: $error');
    }

    return switch (result) {
      GetUserInfoResultHttp200(:final data) => authUserFromDto(data),
      GetUserInfoResultError(:final response) => _throwResponseFailure(
        response,
      ),
    };
  }

  Never _throwResponseFailure(Response<dynamic> response) {
    final status = response.statusCode;
    final body = response.data?.toString();
    if (status == 401) {
      throw FailureUnauthorized(body: body);
    }
    throw failureFromResponse(status, response.data);
  }
}
