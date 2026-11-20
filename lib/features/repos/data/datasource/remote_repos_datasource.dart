import 'package:cna/core/error/failure.dart';
import 'package:cna/core/network/error_mapper.dart';
import 'package:cna/core/network/request_cancellation_scope.dart';
import 'package:cna/features/repos/data/datasource/repos_datasource.dart';
import 'package:cna_api/cna_api.dart';
import 'package:dio/dio.dart';

/// Remote 实现：通过生成客户端取得 DTO，data 层负责解 sealed response。
///
/// `RepositoriesApi.getRepos` 与 `getByID` 的签名、参数名、response variant
/// 均以生成物为准；本类不构造 Dio，也不拼第二份 baseUrl。
class RemoteReposDataSource implements ReposDataSource {
  /// 创建远程仓库数据源。
  new({required this.api});

  /// 由 `apiClientProvider` 创建的 RepositoriesApi。
  final RepositoriesApi api;

  final Map<CancelToken, int> _activeTokens = <CancelToken, int>{};

  @override
  Future<List<DtoRepos4User>> listRepos({
    required int page,
    required int pageSize,
    String? search,
    CancelToken? cancelToken,
  }) async {
    final token = _track(cancelToken);
    try {
      final result = await _withMappedErrors(
        () => api.getRepos(
          page: page,
          pageSize: pageSize,
          search: search,
          cancelToken: token,
        ),
      );

      return switch (result) {
        GetReposResultHttp200(:final data) => data,
        GetReposResultError(:final response) => throw failureFromResponse(
          response.statusCode,
          response.data,
        ),
      };
    } finally {
      _untrack(token);
    }
  }

  @override
  Future<DtoRepos4User> getRepo({
    required String path,
    CancelToken? cancelToken,
  }) async {
    final token = _track(cancelToken);
    try {
      final result = await _withMappedErrors(
        () => api.getByID(repo: path, cancelToken: token),
      );

      return switch (result) {
        GetByIDResultHttp200(:final data) => data,
        GetByIDResultError(:final response) => throw failureFromResponse(
          response.statusCode,
          response.data,
        ),
      };
    } finally {
      _untrack(token);
    }
  }

  /// 取消当前 datasource 正在执行的请求。
  ///
  /// 由持有请求生命周期的调用方触发；本方法不创建或关闭 Dio。
  @override
  void cancelInFlight() {
    for (final token in _activeTokens.keys.toList(growable: false)) {
      if (!token.isCancelled) {
        token.cancel('Repository request lifecycle ended');
      }
    }
    _activeTokens.clear();
  }

  CancelToken _track(CancelToken? supplied) {
    final token =
        supplied ?? RequestCancellationScope.currentToken ?? CancelToken();
    _activeTokens.update(token, (count) => count + 1, ifAbsent: () => 1);
    return token;
  }

  void _untrack(CancelToken token) {
    final count = _activeTokens[token];
    if (count == null || count <= 1) {
      _activeTokens.remove(token);
    } else {
      _activeTokens[token] = count - 1;
    }
  }

  Future<T> _withMappedErrors<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on Failure {
      rethrow;
    } on DioException catch (error, stackTrace) {
      final failure = error.error is Failure
          ? error.error! as Failure
          : failureFromDioException(error);
      Error.throwWithStackTrace(failure, stackTrace);
    } on Object catch (error, stackTrace) {
      if (error is TypeError || error is FormatException) {
        Error.throwWithStackTrace(
          FailureParse('Invalid repository response: $error'),
          stackTrace,
        );
      }
      Error.throwWithStackTrace(
        FailureUnknown('RepositoriesApi failed: ${error.runtimeType}'),
        stackTrace,
      );
    }
  }
}
