import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cna/core/error/failure.dart';
import 'package:cna/core/network/network_providers.dart';
import 'package:cna/core/providers/data_source_overrides.dart';
import 'package:cna/core/storage/secure_storage.dart';
import 'package:cna/core/storage/secure_storage_provider.dart';
import 'package:cna/features/auth/presentation/state/auth_notifier.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer buildContainer(_StorageSpy storage) =>
      ProviderContainer.test(
        overrides: [
          ...dataSourceOverrides(),
          secureStorageProvider.overrideWithValue(storage),
        ],
      );

  testWidgets('dispose cancels remote auth Retry-After and force-closes Dio', (
    tester,
  ) async {
    final storage = _StorageSpy();
    final adapter = _LifecycleAdapter(
      (_, _) async => _response(429, retryAfter: '86400'),
    );
    final container = buildContainer(storage);
    container.read(dioProvider).httpClientAdapter = adapter;
    Object? failure;
    var completed = false;
    final result = container
        .read(authDataSourceProvider)
        .verify('candidate-token')
        .then<void>(
          (_) => completed = true,
          onError: (Object error) {
            failure = error;
            completed = true;
          },
        );
    await _flushRequests(tester);
    expect(adapter.received, hasLength(1));
    expect(adapter.received.single.path, '/user');
    expect(adapter.received.single.cancelToken, isNotNull);

    container.dispose();
    await _flushRequests(tester);

    expect(completed, isTrue);
    await result;
    expect(failure, isA<FailureUnknown>());
    expect(adapter.received.single.cancelToken!.isCancelled, isTrue);
    expect(adapter.closedForce, isTrue);
    expect(adapter.received, hasLength(1));
    expect(storage.deletes, 0);
    // The widget test binding also asserts that no Retry-After timer survives.
  });

  testWidgets(
    'late 401 after dispose settles as cancellation without auth IO',
    (tester) async {
      final storage = _StorageSpy();
      final response = Completer<ResponseBody>();
      final adapter = _LifecycleAdapter((_, _) => response.future);
      final container = buildContainer(storage);
      container.read(dioProvider).httpClientAdapter = adapter;
      final client = container.read(apiClientProvider);
      DioException? failure;
      final result = client.users.getUserInfo().then<void>(
        (_) => fail('request must be cancelled'),
        onError: (Object error) => failure = error as DioException,
      );
      await _flushRequests(tester);
      expect(adapter.received, hasLength(1));

      container.dispose();
      await _flushRequests(tester);
      await result;
      response.complete(_response(401));
      await _flushRequests(tester);

      expect(failure!.type, DioExceptionType.cancel);
      expect(storage.reads, 1);
      expect(storage.deletes, 0);
      expect(adapter.closedForce, isTrue);
    },
  );

  testWidgets('dispose retains explicit page cancellation across replay', (
    tester,
  ) async {
    final storage = _StorageSpy();
    final pageToken = CancelToken();
    final adapter = _LifecycleAdapter((_, attempt) async {
      return _response(429, retryAfter: attempt == 0 ? '0' : '86400');
    });
    final container = buildContainer(storage);
    container.read(dioProvider).httpClientAdapter = adapter;
    final client = container.read(apiClientProvider);
    DioException? failure;
    final result = client.users
        .getUserInfo(cancelToken: pageToken)
        .then<void>(
          (_) => fail('request must be cancelled'),
          onError: (Object error) => failure = error as DioException,
        );
    await _flushRequests(tester);
    await _flushRequests(tester);
    expect(adapter.received, hasLength(2));
    expect(
      adapter.received.every((r) => identical(r.cancelToken, pageToken)),
      isTrue,
    );

    container.dispose();
    await _flushRequests(tester);
    await result;

    expect(pageToken.isCancelled, isTrue);
    expect(failure!.type, DioExceptionType.cancel);
    expect(adapter.received, hasLength(2));
    expect(adapter.closedForce, isTrue);
  });

  testWidgets('concurrent default requests use separate lifetime tokens', (
    tester,
  ) async {
    final respond = Completer<void>();
    final storage = _StorageSpy();
    final adapter = _LifecycleAdapter(
      (_, _) => respond.future.then((_) => _response(200)),
    );
    final container = buildContainer(storage);
    container.read(dioProvider).httpClientAdapter = adapter;
    final client = container.read(apiClientProvider);
    final cancellations = <DioException>[];
    Future<void> startRequest() => client.users.getUserInfo().then<void>(
      (_) => fail('request must be cancelled'),
      onError: (Object error) {
        cancellations.add(error as DioException);
      },
    );
    final first = startRequest();
    final second = startRequest();
    await _flushRequests(tester);
    expect(adapter.received, hasLength(2));
    final firstToken = adapter.received.first.cancelToken;
    final secondToken = adapter.received.last.cancelToken;
    expect(firstToken, isNotNull);
    expect(secondToken, isNotNull);
    expect(identical(firstToken, secondToken), isFalse);

    container.dispose();
    await _flushRequests(tester);
    await Future.wait([first, second]);
    respond.complete();
    await _flushRequests(tester);

    expect(cancellations, hasLength(2));
    expect(
      cancellations.every((error) => error.type == DioExceptionType.cancel),
      isTrue,
    );
    expect(firstToken!.isCancelled, isTrue);
    expect(secondToken!.isCancelled, isTrue);
    expect(adapter.received, hasLength(2));
  });

  testWidgets('dispose cancels auth while SecureStorage read is pending', (
    tester,
  ) async {
    final read = Completer<String?>();
    final storage = _StorageSpy(read: () => read.future);
    final adapter = _LifecycleAdapter((_, _) async => _response(200));
    final container = buildContainer(storage);
    container.read(dioProvider).httpClientAdapter = adapter;
    final client = container.read(apiClientProvider);
    DioException? failure;
    final result = client.users.getUserInfo().then<void>(
      (_) => fail('request must be cancelled'),
      onError: (Object error) => failure = error as DioException,
    );
    await _flushRequests(tester);
    expect(storage.reads, 1);
    expect(adapter.received, isEmpty);

    container.dispose();
    await _flushRequests(tester);
    await result;
    read.complete('late-token');
    await _flushRequests(tester);

    expect(failure!.type, DioExceptionType.cancel);
    expect(adapter.received, isEmpty);
    expect(storage.deletes, 0);
  });

  test(
    'completed explicit tokens are detached before network disposal',
    () async {
      final storage = _StorageSpy();
      final successToken = CancelToken();
      final errorToken = CancelToken();
      final adapter = _LifecycleAdapter(
        (_, attempt) async => _response(attempt == 0 ? 200 : 403),
      );
      final container = buildContainer(storage);
      container.read(dioProvider).httpClientAdapter = adapter;
      final client = container.read(apiClientProvider);

      await client.users.getUserInfo(cancelToken: successToken);
      await expectLater(
        client.users.getUserInfo(cancelToken: errorToken),
        throwsA(isA<DioException>()),
      );
      container.dispose();

      expect(successToken.isCancelled, isFalse);
      expect(errorToken.isCancelled, isFalse);
      expect(adapter.closedForce, isTrue);
    },
  );

  test(
    'asynchronous storage failure completes and detaches the request',
    () async {
      final storage = _StorageSpy(
        read: () => Future<String?>.error(StateError('storage unavailable')),
      );
      final pageToken = CancelToken();
      final adapter = _LifecycleAdapter((_, _) async => _response(200));
      final container = buildContainer(storage);
      container.read(dioProvider).httpClientAdapter = adapter;
      final client = container.read(apiClientProvider);

      await expectLater(
        client.users.getUserInfo(cancelToken: pageToken),
        throwsA(isA<DioException>()),
      );
      container.dispose();

      expect(adapter.received, isEmpty);
      expect(pageToken.isCancelled, isFalse);
    },
  );
}

Future<void> _flushRequests(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}

ResponseBody _response(int status, {String? retryAfter}) =>
    ResponseBody.fromString(
      jsonEncode({'id': 'user-1'}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        if (retryAfter != null) 'retry-after': [retryAfter],
      },
    );

class _LifecycleAdapter implements HttpClientAdapter {
  new(this.reply);

  final Future<ResponseBody> Function(RequestOptions, int) reply;
  final List<RequestOptions> received = [];
  bool? closedForce;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    final attempt = received.length;
    received.add(options);
    return reply(options, attempt);
  }

  @override
  void close({bool force = false}) => closedForce = force;
}

class _StorageSpy implements SecureStorage {
  new({this.read});

  final Future<String?> Function()? read;
  int reads = 0;
  int deletes = 0;

  @override
  Future<String?> readToken() {
    reads++;
    return read?.call() ?? Future<String?>.value('stored-token');
  }

  @override
  Future<void> deleteToken() async => deletes++;

  @override
  Future<void> writeToken(String token) async {}
}
