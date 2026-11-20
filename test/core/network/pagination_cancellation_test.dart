import 'dart:async';

import 'package:cna/core/network/pagination.dart';
import 'package:cna/core/network/request_cancellation_scope.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'PagedListNotifier dispose cancels the token available to its data call',
    () async {
      final response = Completer<List<int>>();
      CancelToken? token;
      final provider =
          AsyncNotifierProvider<_BlockingPagedList, PagedListState<int>>(
            () => _BlockingPagedList(response, (value) => token = value),
            retry: (retryCount, error) => null,
          );
      final container = ProviderContainer.test();
      final subscription = container.listen(provider, (_, _) {});

      await Future<void>.delayed(Duration.zero);
      expect(token, isNotNull);
      expect(RequestCancellationScope.currentToken, isNull);

      subscription.close();

      expect(token!.isCancelled, isTrue);
      response.complete([1]);
      await Future<void>.delayed(Duration.zero);
      container.dispose();
    },
  );
}

class _BlockingPagedList extends PagedListNotifier<int> {
  new(this.response, this.onToken);

  final Completer<List<int>> response;
  final void Function(CancelToken?) onToken;

  @override
  Future<PagedListState<int>> build() {
    registerDisposeGuard();
    return loadFirstPage();
  }

  @override
  Future<List<int>> fetch(int page, String? search) {
    onToken(RequestCancellationScope.currentToken);
    return response.future;
  }
}
