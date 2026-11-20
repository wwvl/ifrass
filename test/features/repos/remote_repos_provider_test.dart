import 'dart:async';

import 'package:cna/core/error/failure.dart';
import 'package:cna/core/network/network_providers.dart';
import 'package:cna/core/network/pagination.dart';
import 'package:cna/features/repos/data/datasource/remote_repos_datasource.dart';
import 'package:cna/features/repos/data/repos_providers.dart';
import 'package:cna/features/repos/domain/entities/repo.dart';
import 'package:cna/features/repos/presentation/state/repos_list.dart';
import 'package:cna_api/cna_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/network/helpers/stub_adapter.dart';

void main() {
  test(
    'remote provider exposes loading then data without Riverpod retry',
    () async {
      final response = Completer<StubReply>();
      final container = _buildContainer(StubAdapter((_, _) => response.future));
      addTearDown(container.dispose);

      final subscription = container.listen(reposListProvider, (_, _) {});
      final future = container.read(reposListProvider.future);
      expect(
        container.read(reposListProvider),
        isA<AsyncLoading<PagedListState<Repo>>>(),
      );

      response.complete(
        const StubReply(
          status: 200,
          body: [
            {'path': 'owner/repo', 'name': 'repo'},
          ],
        ),
      );
      final state = await future;

      expect(state.items.single.path, 'owner/repo');
      expect(
        container.read(reposListProvider),
        isA<AsyncData<PagedListState<Repo>>>(),
      );
      subscription.close();
    },
  );

  test('remote provider exposes mapped error and does not retry', () async {
    var calls = 0;
    final container = _buildContainer(
      StubAdapter((_, _) async {
        calls++;
        return const StubReply(status: 403, body: 'scope denied');
      }),
    );
    addTearDown(container.dispose);

    final subscription = container.listen(reposListProvider, (_, _) {});
    await expectLater(
      container.read(reposListProvider.future),
      throwsA(isA<FailureHttp>()),
    );
    expect(calls, 1);
    expect(container.read(reposListProvider).error, isA<FailureHttp>());
    subscription.close();
  });

  test('remote provider maps empty response to data empty state', () async {
    final container = _buildContainer(
      StubAdapter((_, _) async => const StubReply(status: 200, body: [])),
    );
    addTearDown(container.dispose);

    final subscription = container.listen(reposListProvider, (_, _) {});
    final state = await container.read(reposListProvider.future);

    expect(state.items, isEmpty);
    expect(state.hasMore, isFalse);
    subscription.close();
  });
}

ProviderContainer _buildContainer(StubAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
  final client = ApiClient(baseUrl: 'https://api.example.test', dio: dio);
  return ProviderContainer.test(
    retry: (retryCount, error) => null,
    overrides: [
      apiClientProvider.overrideWithValue(client),
      reposDataSourceProvider.overrideWithValue(
        RemoteReposDataSource(api: client.repositories),
      ),
    ],
  );
}
