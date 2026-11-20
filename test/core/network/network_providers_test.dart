import 'package:cna/core/config/app_config.dart';
import 'package:cna/core/network/interceptors/auth_interceptor.dart';
import 'package:cna/core/network/interceptors/error_mapping_interceptor.dart';
import 'package:cna/core/network/interceptors/logging_interceptor.dart';
import 'package:cna/core/network/interceptors/retry_interceptor.dart';
import 'package:cna/core/network/interceptors/unauthorized_interceptor.dart';
import 'package:cna/core/network/network_providers.dart';
import 'package:cna/core/storage/in_memory_secure_storage.dart';
import 'package:cna/core/storage/secure_storage_provider.dart';
import 'package:cna_api/cna_api.dart'
    hide AuthInterceptor, LoggingInterceptor, RetryInterceptor;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/stub_adapter.dart';

void main() {
  test(
    'production Dio has configured baseUrl and ordered single auth chain',
    () async {
      final storage = InMemorySecureStorage();
      await storage.writeToken('stored-token');
      final container = ProviderContainer.test(
        retry: (retryCount, error) => null,
        overrides: [secureStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);
      expect(dio.options.baseUrl, AppConfig.apiBaseUrl);
      expect(
        dio.interceptors
            .where(
              (interceptor) =>
                  interceptor is AuthInterceptor ||
                  interceptor is RetryInterceptor ||
                  interceptor is ErrorMappingInterceptor ||
                  interceptor is UnauthorizedInterceptor ||
                  interceptor is LoggingInterceptor,
            )
            .map((interceptor) => interceptor.runtimeType),
        [
          AuthInterceptor,
          RetryInterceptor,
          ErrorMappingInterceptor,
          UnauthorizedInterceptor,
          LoggingInterceptor,
        ],
      );

      final adapter = StubAdapter(
        (_, _) async => const StubReply(status: 200, body: {'id': 'u1'}),
      );
      dio.httpClientAdapter = adapter;
      final client = container.read(apiClientProvider);
      final result = await client.users.getUserInfo();

      expect(result, isA<GetUserInfoResultHttp200>());
      expect(adapter.count, 1);
      expect(
        adapter.received.single.headers['Authorization'],
        'Bearer stored-token',
      );
      expect(adapter.received.single.headers['Accept'], 'application/json');
      expect(
        adapter.received.single.headers.keys.where(
          (key) => key.toLowerCase() == 'authorization',
        ),
        hasLength(1),
      );
    },
  );
}
