import 'package:cna/core/config/app_config.dart';
import 'package:cna/features/auth/data/auth_providers.dart';
import 'package:cna/features/auth/presentation/state/auth_notifier.dart';
import 'package:cna/features/repos/data/repos_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Riverpod 3 composition for the app entry point and remote contract tests.
/// The original provider slots stay available to the existing fake tests.
List<Override> dataSourceOverrides({bool useFakeApi = AppConfig.useFakeApi}) =>
    useFakeApi
    ? const []
    : [
        authDataSourceProvider.overrideWith(
          (ref) => ref.watch(remoteAuthDataSourceProvider),
        ),
        reposDataSourceProvider.overrideWith(
          (ref) => ref.watch(remoteReposDataSourceProvider),
        ),
      ];
