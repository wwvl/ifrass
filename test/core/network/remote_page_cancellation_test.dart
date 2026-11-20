import 'dart:async';

import 'package:cna/core/network/pagination.dart';
import 'package:cna/features/repos/data/datasource/remote_repos_datasource.dart';
import 'package:cna/features/repos/data/repos_providers.dart';
import 'package:cna/features/repos/domain/entities/repo.dart';
import 'package:cna/features/repos/presentation/state/repos_list.dart';
import 'package:cna_api/cna_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/stub_adapter.dart';

const _repoReply = StubReply(
  status: 200,
  body: [
    {'path': 'owner/repo', 'name': 'repo'},
  ],
);

void main() {
  ProviderContainer buildContainer(StubAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    addTearDown(() => dio.close(force: true));
    final dataSource = RemoteReposDataSource(api: RepositoriesApi(dio: dio));
    final container = ProviderContainer.test(
      retry: (retryCount, error) => null,
      overrides: [reposDataSourceProvider.overrideWithValue(dataSource)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('unobserved remote page aborts then fetches again on resume', () async {
    final firstStarted = Completer<RequestOptions>();
    final secondStarted = Completer<RequestOptions>();
    final pendingReply = Completer<StubReply>();
    final adapter = StubAdapter((request, attempt) async {
      if (attempt == 0) {
        firstStarted.complete(request);
        return await pendingReply.future;
      }
      secondStarted.complete(request);
      return _repoReply;
    });
    final container = buildContainer(adapter);
    final subscription = container.listen(reposListProvider, (_, _) {});
    final firstRequest = await firstStarted.future;
    final firstToken = firstRequest.cancelToken!;

    subscription.close();
    await firstToken.whenCancel;
    expect(firstToken.isCancelled, isTrue);

    final resumed = container.listen(reposListProvider, (_, _) {});
    addTearDown(resumed.close);
    final secondRequest = await secondStarted.future;
    final state = await container.read(reposListProvider.future);

    expect(adapter.count, 2);
    expect(secondRequest.cancelToken, isNot(same(firstToken)));
    expect(secondRequest.cancelToken!.isCancelled, isFalse);
    expect(state.items.single.path, 'owner/repo');
    expect(state.hasMore, isFalse);
  });

  test(
    'remote page preserves a completed search after abort and resume',
    () async {
      final refreshStarted = Completer<RequestOptions>();
      final resumedStarted = Completer<RequestOptions>();
      final pendingReply = Completer<StubReply>();
      final adapter = StubAdapter((request, attempt) async {
        if (attempt == 2) {
          refreshStarted.complete(request);
          return await pendingReply.future;
        }
        if (attempt == 3) resumedStarted.complete(request);
        return _repoReply;
      });
      final container = buildContainer(adapter);
      final subscription = container.listen(reposListProvider, (_, _) {});
      await container.read(reposListProvider.future);
      final notifier = container.read(reposListProvider.notifier);
      await notifier.search('Dart');
      expect(container.read(reposListProvider).requireValue.search, 'Dart');

      final refresh = notifier.refresh();
      final refreshRequest = await refreshStarted.future;
      subscription.close();
      await refreshRequest.cancelToken!.whenCancel;
      await refresh;

      final resumed = container.listen(reposListProvider, (_, _) {});
      addTearDown(resumed.close);
      final resumedRequest = await resumedStarted.future;
      final state = await container.read(reposListProvider.future);

      expect(refreshRequest.cancelToken!.isCancelled, isTrue);
      expect(resumedRequest.queryParameters['search'], 'Dart');
      expect(state.search, 'Dart');
      expect(state.items.single.path, 'owner/repo');
      expect(state.loadingMore, isFalse);
      expect(state.loadMoreFailed, isFalse);
    },
  );

  test(
    'separate paged lists do not cancel each other through one data source',
    () async {
      final firstStarted = Completer<RequestOptions>();
      final secondStarted = Completer<RequestOptions>();
      final firstReply = Completer<StubReply>();
      final secondReply = Completer<StubReply>();
      final adapter = StubAdapter((request, attempt) async {
        if (attempt == 0) {
          firstStarted.complete(request);
          return await firstReply.future;
        }
        secondStarted.complete(request);
        return await secondReply.future;
      });
      final container = buildContainer(adapter);
      final otherList = AsyncNotifierProvider<ReposList, PagedListState<Repo>>(
        ReposList.new,
        retry: (retryCount, error) => null,
      );
      final firstSubscription = container.listen(reposListProvider, (_, _) {});
      final firstRequest = await firstStarted.future;
      final secondSubscription = container.listen(otherList, (_, _) {});
      addTearDown(secondSubscription.close);
      final secondRequest = await secondStarted.future;

      firstSubscription.close();
      await firstRequest.cancelToken!.whenCancel;

      expect(firstRequest.cancelToken!.isCancelled, isTrue);
      expect(secondRequest.cancelToken, isNot(same(firstRequest.cancelToken)));
      expect(secondRequest.cancelToken!.isCancelled, isFalse);

      secondReply.complete(_repoReply);
      final secondState = await container.read(otherList.future);
      expect(secondState.items.single.path, 'owner/repo');
      expect(adapter.count, 2);
    },
  );

  test(
    'search survives a second pause while the resumed request is pending',
    () async {
      final refreshStarted = Completer<RequestOptions>();
      final resumedStarted = Completer<RequestOptions>();
      final finalStarted = Completer<RequestOptions>();
      final blockedRefresh = Completer<StubReply>();
      final blockedResume = Completer<StubReply>();
      final adapter = StubAdapter((request, attempt) async {
        if (attempt == 2) {
          refreshStarted.complete(request);
          return await blockedRefresh.future;
        }
        if (attempt == 3) {
          resumedStarted.complete(request);
          return await blockedResume.future;
        }
        if (attempt == 4) finalStarted.complete(request);
        return _repoReply;
      });
      final container = buildContainer(adapter);
      final original = container.listen(reposListProvider, (_, _) {});
      await container.read(reposListProvider.future);
      final notifier = container.read(reposListProvider.notifier);
      await notifier.search('Dart');

      final refresh = notifier.refresh();
      final refreshRequest = await refreshStarted.future;
      original.close();
      await refreshRequest.cancelToken!.whenCancel;
      await refresh;

      final firstResume = container.listen(reposListProvider, (_, _) {});
      final resumedRequest = await resumedStarted.future;
      firstResume.close();
      await resumedRequest.cancelToken!.whenCancel;
      await Future<void>.delayed(Duration.zero);

      final secondResume = container.listen(reposListProvider, (_, _) {});
      addTearDown(secondResume.close);
      final finalRequest = await finalStarted.future;
      final state = await container.read(reposListProvider.future);

      expect(finalRequest.queryParameters['search'], 'Dart');
      expect(state.search, 'Dart');
      expect(state.items.single.path, 'owner/repo');
    },
  );
}
