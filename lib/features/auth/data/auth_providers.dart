import 'package:cna/core/network/network_providers.dart';
import 'package:cna/features/auth/data/datasource/auth_data_source.dart';
import 'package:cna/features/auth/data/datasource/remote_auth_data_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

/// 远程认证数据源：复用全局 ApiClient 的 UsersApi。
@Riverpod(keepAlive: true, name: 'remoteAuthDataSourceProvider')
AuthDataSource remoteAuthDataSource(Ref ref) =>
    RemoteAuthDataSource(usersApi: ref.watch(apiClientProvider).users);
