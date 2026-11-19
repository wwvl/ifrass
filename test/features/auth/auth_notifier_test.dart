import 'package:cna/core/error/failure.dart';
import 'package:cna/core/storage/in_memory_secure_storage.dart';
import 'package:cna/core/storage/secure_storage_provider.dart';
import 'package:cna/features/auth/data/datasource/fake_auth_data_source.dart';
import 'package:cna/features/auth/domain/auth_state.dart';
import 'package:cna/features/auth/presentation/state/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemorySecureStorage storage;
  late ProviderContainer container;

  ProviderContainer build() {
    return ProviderContainer.test(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        authDataSourceProvider.overrideWithValue(
          FakeAuthDataSource(
            delay: Duration.zero,
            invalidToken: 'invalid-token',
            networkFailToken: 'net-fail',
          ),
        ),
      ],
    );
  }

  setUp(() {
    storage = InMemorySecureStorage();
    container = build();
    addTearDown(container.dispose);
  });

  group('AuthNotifier.restore', () {
    test('无本地 token → SignedOut', () async {
      await container.read(authNotifierProvider.notifier).restore();

      expect(container.read(authNotifierProvider), const AuthSignedOut());
    });

    test('有本地 token 且校验通过 → SignedIn(token)', () async {
      await storage.writeToken('good-token');

      await container.read(authNotifierProvider.notifier).restore();

      expect(
        container.read(authNotifierProvider),
        const AuthSignedIn('good-token'),
      );
    });

    test('网络失败保持 Unknown（不加第四态，splash 重试）', () async {
      await storage.writeToken('net-fail');
      final notifier = container.read(authNotifierProvider.notifier);

      await expectLater(notifier.restore(), throwsA(isA<FailureNetwork>()));
      expect(container.read(authNotifierProvider), const AuthUnknown());
    });

    test('401 → 唯一失效入口：token 清除 + SignedOut', () async {
      await storage.writeToken('invalid-token');
      final notifier = container.read(authNotifierProvider.notifier);

      await notifier.restore();

      expect(container.read(authNotifierProvider), const AuthSignedOut());
      expect(await storage.readToken(), isNull);
    });
  });

  group('AuthNotifier.signIn', () {
    test('成功 → SignedIn(token) 且 token 已写入存储', () async {
      final failure = await container
          .read(authNotifierProvider.notifier)
          .signIn('good-token');

      expect(failure, isNull);
      expect(
        container.read(authNotifierProvider),
        const AuthSignedIn('good-token'),
      );
      expect(await storage.readToken(), 'good-token');
    });

    test('401 → 返回 FailureUnauthorized，state 不变', () async {
      final failure = await container
          .read(authNotifierProvider.notifier)
          .signIn('invalid-token');

      expect(failure, isA<FailureUnauthorized>());
      expect(container.read(authNotifierProvider), const AuthUnknown());
    });

    test('网络失败 → 返回 FailureNetwork，state 不变', () async {
      final failure = await container
          .read(authNotifierProvider.notifier)
          .signIn('net-fail');

      expect(failure, isA<FailureNetwork>());
      expect(container.read(authNotifierProvider), const AuthUnknown());
    });
  });

  group('AuthNotifier.signOut / invalidate', () {
    test('signOut：清存储 + SignedOut', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn('good-token');
      await notifier.signOut();

      expect(container.read(authNotifierProvider), const AuthSignedOut());
      expect(await storage.readToken(), isNull);
    });

    test('401 invalidate：SignedOut 且 token 清除', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn('good-token');
      await notifier.invalidate();

      expect(container.read(authNotifierProvider), const AuthSignedOut());
      expect(await storage.readToken(), isNull);
    });
  });

  test('初始态：build() → AuthUnknown', () {
    expect(container.read(authNotifierProvider), const AuthUnknown());
  });
}
