/// 401 单一失效入口（AGENTS.md §5：「清 SecureStorage → authNotifier.invalidate()
/// → 守卫跳登录」；任何页面禁止 `if (status == 401)`）。
///
/// 调用方只有两处：M2 的 `AuthNotifier`（signIn / restore 捕获 401 后）与
/// M4 的 Dio `UnauthorizedInterceptor`（provider 装配时注入依赖）。
/// 「守卫跳登录」不需要这里触发导航：`onInvalidated` 复位状态后，
/// refreshListenable 会令守卫重跑并把未登录访问送回 `/login`。
library;

import 'package:cna/features/auth/domain/auth_repository.dart';

/// 执行 401 失效：清 SecureStorage（经 [AuthRepository.invalidate]），
/// 然后回调 [onInvalidated] 复位认证状态。
Future<void> handleUnauthorized({
  required AuthRepository repository,
  required void Function() onInvalidated,
}) async {
  await repository.invalidate();
  onInvalidated();
}
