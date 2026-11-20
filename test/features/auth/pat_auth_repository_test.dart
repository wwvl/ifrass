import 'package:cna/core/storage/secure_storage.dart';
import 'package:cna/features/auth/data/datasource/fake_auth_data_source.dart';
import 'package:cna/features/auth/data/repo_impl/pat_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repeated 401 invalidation clears token storage once', () async {
    final storage = _CountingSecureStorage();
    final repository = PatAuthRepository(
      storage: storage,
      dataSource: FakeAuthDataSource(delay: Duration.zero),
    );

    await repository.invalidate();
    await repository.invalidate();

    expect(storage.deleteCount, 1);
  });

  test('concurrent 401 invalidation shares the storage clear', () async {
    final storage = _CountingSecureStorage()
      ..delay = const Duration(milliseconds: 1);
    final repository = PatAuthRepository(
      storage: storage,
      dataSource: FakeAuthDataSource(delay: Duration.zero),
    );

    await Future.wait([repository.invalidate(), repository.invalidate()]);

    expect(storage.deleteCount, 1);
  });
}

class _CountingSecureStorage implements SecureStorage {
  int deleteCount = 0;
  Duration delay = Duration.zero;

  @override
  Future<String?> readToken() async => null;

  @override
  Future<void> writeToken(String token) async {}

  @override
  Future<void> deleteToken() async {
    deleteCount++;
    await Future<void>.delayed(delay);
  }
}
