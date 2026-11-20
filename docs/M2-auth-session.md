# M2 · PAT 登录 + Auth & Session + go_router 守卫

> 用法：把下面整段发给 Agent（CodeBuddy / DeepSeek Harness / Cline 均可）。
> 规则文件以仓库实际命名 `@AGENTS.md`（若仍叫 `CODEBUDDY.md` 就用那个名字）+ `@DESIGN.md`。

---

读 @AGENTS.md 和 @DESIGN.md，再读以下已合入的源码，全部按现状来，不要凭印象：

- `lib/main.dart`、`lib/core/router/routes.dart`、`lib/core/theme/`、`lib/core/error/failure.dart`
- `lib/features/repos/domain/repositories/repos_repository.dart`、`lib/features/repos/data/datasource/`
  （M1 的「抽象接口 + FakeDataSource 四模式 + mapper」分层范式，**照这个形状写 auth**）
- `lib/generated/cna_api/` 里 `Users` tag 的真实 DTO（先读源码，禁止臆造字段名）
- `lib/shared/widgets/async_state_view.dart`（M0 的接口合同）
- `test/` 下 M0 的 13 个用例、`test/tool/` 与 M1 的 32 个用例、`.cnb.yml`

M0、M1 已合入，全链门禁 6/6 绿，工作区干净。本次只做 **M2：PAT 登录 + Auth & Session + go_router 守卫**。

## 范围

1. **`lib/core/storage/`**
   `SecureStorage` 抽象接口 + `flutter_secure_storage` 真实现 + **内存 Fake 实现**（测试用）。token 唯一存放处；禁止 `shared_preferences` / 普通文件 / 日志。

2. **`lib/features/auth/domain/`**（纯 Dart，不 import material / flutter / `*.g.dart` / `cna_api`）
   - `AuthState` sealed：`AuthUnknown` / `AuthSignedOut` / `AuthSignedIn(token)`
   - `AuthRepository` 抽象接口：`signIn(token)` / `restore()` / `signOut()` / `invalidate()`
   - `AuthDataSource` 抽象接口：`verify(token)`
   - 两个维度各自解耦：token 来源（PAT / 二期 OAuth）靠 Repository，校验方式（Fake / 真 API）靠 DataSource

3. **`lib/features/auth/data/`**
   - `PatAuthRepository` 实现（一期；二期可换 `OAuthAuthRepository` 而不动 UI）
   - `FakeAuthDataSource`：任意非空 token 成功；三个可注入行为 —— 固定 token 触发 401 / 网络失败 / 慢响应
   - **M2 不真发 HTTP**。字段名对齐 `cna_api` 里 `Users` 的真实 DTO；M4 换 `cna_api.UsersApi` 时只换 datasource

4. **`lib/features/auth/presentation/`**
   - `/login`：PAT 输入 + 权限说明（最小权限引导、明示「token 只存本机 Keystore / Keychain」）。**一个主操作**，不放用户名密码框，用 `DESIGN.md` §4.1 白名单组件
   - `/splash`：`AuthUnknown` 期间停留并触发 `restore()`
   - 404 页、离线页、会话过期页（§7 要求）
   - **不实现 `AsyncStateView` 的渲染**（留给 M3），但不得删 M0 的接口合同

5. **状态层**
   - `authNotifierProvider`：**同步 `Notifier<AuthState>`，`@Riverpod(keepAlive: true)`**，初始 `AuthUnknown`
   - **禁止** `AsyncNotifier<AuthState>`——`appRedirect` 必须是同步纯函数，不能处理 `AsyncLoading`
   - `secureStorageProvider`、`authRepositoryProvider`（Fake / Real 可 override）

6. **`lib/core/router/`**
   - `app_router.dart`：接 `routes.dart` 的常量与 path builder，`StatefulShellRoute` 底部 Tab 骨架（各 Tab 独立栈，页面先占位）
   - `guards.dart`：`appRedirect(AuthState auth, GoRouterState state)` **同步纯函数** —— 不 await / 不做 IO / 不写 provider / 不读 `DateTime.now()`，只返回 `null` 或 location
   - go_router 的 redirect 回调体**只允许** `appRedirect(ref.read(authNotifierProvider), state)` 这一次同步读
   - `refreshListenable`：在 ProviderScope 之下由 provider 持有桥接对象（`ref.listen(authNotifierProvider, ...) → notifyListeners()`），`ref.onDispose` 释放；**禁止全局单例**。触发重跑只靠它，`ref.read` 不负责触发
   - **防死循环**：显式放行 `/login` 自身、`/splash` 自身；比较 `state.matchedLocation` 而非原始 URI；反复 refresh 不抖动
   - **深链**：未登录 → `/login?from=<encoded>`；登录成功后**由 redirect 回跳**，不在登录页里写 `context.go(from)`（§12 第 6 条）
   - `from` 必须校验为站内路径：`Uri.tryParse` 后要求非绝对、无 scheme/host、以 `/` 开头，否则回落 `/`（防开放重定向）
   - 路径大小写敏感（go_router 15+），一律用 `routes.dart` 常量，禁止拼字符串

7. **`lib/core/network/unauthorized_handler.dart`**：401 **单一失效入口**
   （清 `SecureStorage` → `authNotifier.invalidate()` → 守卫跳登录）。M2 的 Fake 401 与 M4 的 Dio `UnauthorizedInterceptor` 复用同一个入口；**任何页面禁止 `if (status == 401)`**。

8. **`main.dart`**：删掉 M0 的约 20 行占位首页，`MaterialApp` → `MaterialApp.router(routerConfig: ...)`。
   - **浅深主题桥接原样保留**（`TThemeBuilder.light/dark` 是 `ThemeData` 静态工厂，不是 Widget，见 `DESIGN.md` §1.2）
   - `ProviderScope` 保持在根；legacy 三 delegate 不动；不动主题 Token 定义

## 明确不做

- 不写仓库列表 / 详情 / Issue / PR / 构建日志任何页面（M3）
- 不接真实 HTTP、不在 M2 调 `cna_api` 发请求（M4）
- **不装 `flutter_markdown`**（官方已 discontinued，M4 前由人决策替代品）
- 不引入 `material_ui` / `cupertino_ui`、不跑 `dart fix --code=migrate_design_widgets`
- 不升 `go_router` 到 18+、不升 Flutter / Dart 基线（§15）
- 不改 `lib/generated/cna_api/` 任何一个文件、不改 `tool/spec_whitelist.yaml`、不改 `api/spec/*.json`、不改 M1 的 filter / generate 脚本
- 不改 `CODEBUDDY.md` / `DESIGN.md` 的禁令；不改 `lib/core/theme/` 的 Token 定义
- 不「顺便」实现 `AsyncStateView`、重构无关页面、或一次性铺多个 feature

## 设计硬约束（违反即打回）

- 四层不变：`Widget → Notifier → Repository(抽象) → DataSource`；DTO 不进 UI
- `appRedirect` 同步纯函数、可单测；go_router 层不许出现业务逻辑
- `AuthRepository` / `AuthDataSource` 在 domain 且纯 Dart
- UI 一律 `context.tTheme` / `AppSpacing` / `Theme.of(context).textTheme`；禁止裸 hex、魔法间距、内联 `TextStyle`
- token 禁止进日志、禁止进 prompt、禁止写 `shared_preferences`、禁止打印 `Authorization` 头
- 依赖一律 `flutter pub add`，提交 `pubspec.lock`；禁止手填版本号

## 测试（必须新增；M0 的 13 + M1 的 32 一条都不许删或放宽）

- **`appRedirect` 纯函数单测**：`AuthUnknown → /splash`；未登录访问 `/repos → /login?from=`；已登录访问 `/login → /`；`/login` 与 `/splash` 自身放行；恶意绝对 URL 的 `from` 回落 `/`；大小写路径不误判；反复 refresh 不抖动
- **`AuthNotifier`**（`ProviderContainer.test()` + override FakeDataSource / 内存 SecureStorage）：`restore` 无 token → `SignedOut`；有 token → `SignedIn`；`signOut` 清空存储；401 `invalidate` → `SignedOut` 且 token 清除
- `FakeAuthDataSource` 三种可注入行为各一例
- **Widget**：未登录深链落登录页；登录成功由 redirect 回原目标；登出回登录页；`/splash` 解析态；404 / 离线 / 会话过期页各一条
- M0 的「整 App 浅深 smoke」允许改为从 router 入口启动，但 **Token 断言、「深色扩展必须是指向 `root.dark` 的同一实例」、「两套底色不同」三条断言一条都不许删或放宽**

## 门禁（改完自己跑完并修到绿，别把红灯留给我）

```bash
dart run tool/filter_spec.dart --check
dart run tool/generate.dart            # 会清理并重生成 cna_api，确认 git diff 为空
dart run build_runner build           # M2 首次产出 *.g.dart / *.freezed.dart，必须提交
dart format lib test
flutter analyze
flutter test
```

再本地复跑 `.cnb.yml` 的完整链，并额外做两件事：

1. **把 freshness gate 的 `git diff --exit-code` 路径补上 `lib/**/*.g.dart` 与 `lib/**/*.freezed.dart`**——M1 的 gate 只覆盖 `mvp.json` + `lib/generated/`（当时 0 outputs 没暴露），M2 起 build_runner 产物会静默漂移
2. 确认 `pubspec.lock` 已提交、`flutter pub get --enforce-lockfile` 通过、`git diff --exit-code` 全绿

## 交付格式

**先输出 3–5 步计划**，其中要专门说明你打算怎么落 `authNotifierProvider` 与 `refreshListenable` 的桥接（在哪一层持有、怎么 dispose），等我确认再改文件。

一个 PR 只做 M2，改动可独立回滚。
