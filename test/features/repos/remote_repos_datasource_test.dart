import 'dart:async';

import 'package:cna/core/error/failure.dart';
import 'package:cna/features/repos/data/datasource/remote_repos_datasource.dart';
import 'package:cna/features/repos/data/repo_impl/remote_repos_repository.dart';
import 'package:cna_api/cna_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/network/helpers/stub_adapter.dart';

void main() {
  RemoteReposDataSource buildDataSource(StubAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    return RemoteReposDataSource(api: RepositoriesApi(dio: dio));
  }

  group('RemoteReposDataSource.listRepos', () {
    test(
      'uses generated page/page_size/search query names and maps DTOs',
      () async {
        final adapter = StubAdapter(
          (_, _) async => const StubReply(
            status: 200,
            body: [
              {
                'id': 'repo-id',
                'path': 'owner/repo',
                'name': 'repo',
                'star_count': 7,
              },
            ],
          ),
        );
        final source = buildDataSource(adapter);

        final result = await source.listRepos(
          page: 2,
          pageSize: 20,
          search: 'Dart tools',
        );

        expect(result, hasLength(1));
        expect(result.single.path, 'owner/repo');
        expect(result.single.starCount, 7);
        expect(adapter.received.single.uri.path, '/user/repos');
        expect(adapter.received.single.queryParameters, {
          'page': '2',
          'page_size': '20',
          'search': 'Dart tools',
        });
      },
    );

    test('HTTP error maps to FailureHttp and retains the status', () async {
      final source = buildDataSource(
        StubAdapter(
          (_, _) async =>
              const StubReply(status: 403, body: {'message': 'scope denied'}),
        ),
      );

      await expectLater(
        source.listRepos(page: 1, pageSize: 20),
        throwsA(
          isA<FailureHttp>().having((failure) => failure.status, 'status', 403),
        ),
      );
    });

    test('generated DTO type mismatch maps to FailureParse', () async {
      final source = buildDataSource(
        StubAdapter(
          (_, _) async => const StubReply(
            status: 200,
            body: [
              {'path': 'owner/repo', 'name': 'repo', 'star_count': 'seven'},
            ],
          ),
        ),
      );

      await expectLater(
        source.listRepos(page: 1, pageSize: 20),
        throwsA(isA<FailureParse>()),
      );
    });

    test(
      'cancelInFlight aborts the active Dio request using its token',
      () async {
        final started = Completer<void>();
        final blockedResponse = Completer<StubReply>();
        final adapter = StubAdapter((_, _) {
          if (!started.isCompleted) started.complete();
          return blockedResponse.future;
        });
        final source = buildDataSource(adapter);
        final token = CancelToken();

        final request = source.listRepos(
          page: 1,
          pageSize: 20,
          cancelToken: token,
        );
        await started.future;

        source.cancelInFlight();

        expect(token.isCancelled, isTrue);
        await expectLater(request, throwsA(isA<FailureUnknown>()));
      },
    );
  });

  group('RemoteReposDataSource.getRepo', () {
    test('uses the generated getByID path and returns the DTO', () async {
      final adapter = StubAdapter(
        (_, _) async => const StubReply(
          status: 200,
          body: {'path': 'owner/repo', 'name': 'repo'},
        ),
      );
      final source = buildDataSource(adapter);

      final result = await source.getRepo(path: 'owner/repo');

      expect(result.path, 'owner/repo');
      expect(adapter.received.single.uri.path, '/owner/repo');
    });

    test('2xx non-200 sealed error maps its response status', () async {
      final source = buildDataSource(
        StubAdapter((_, _) async => const StubReply(status: 204)),
      );

      await expectLater(
        source.getRepo(path: 'owner/repo'),
        throwsA(
          isA<FailureHttp>().having((failure) => failure.status, 'status', 204),
        ),
      );
    });

    test(
      'repo mapper rejects missing required path/name as FailureParse',
      () async {
        final source = RemoteReposRepository(
          dataSource: buildDataSource(
            StubAdapter(
              (_, _) async =>
                  const StubReply(status: 200, body: {'name': 'repo'}),
            ),
          ),
        );

        await expectLater(
          source.getRepo(path: 'owner/repo'),
          throwsA(isA<FailureParse>()),
        );
      },
    );
  });
}
