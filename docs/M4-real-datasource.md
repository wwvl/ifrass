# M4 · 换真数据：FakeDataSource → cna_api 真实 client

> 用法：把下面整段发给 Agent。规则文件是 `@AGENTS.md` + `@DESIGN.md`。
> **前置条件（不满足就别发）**：M0、M1、M2、**M3 全部已合入**，全链门禁绿，工作区干净。
> M4 的验收线是「换真数据时 UI diff 必须为空」，它依赖 M3 的页面与 `AsyncStateView` 已经定稿；
> M3 没合入就发这个 prompt，等于让 Agent 边改 UI 边换数据，验收线直接失效。

---

读 @AGENTS.md 和 @DESIGN.md，再读以下已合入的源码，**全部按现状来，不要凭印象、不要臆造 API 或字段名**：

- `lib/generated/cna_api/` 的 **`core/` 与 `Users` / `Repositories` 两组 API** —— 先确认生成物自带的 auth 注入形态、`baseUrl` 来源、client 构造参数、方法名与返回类型（sealed response）。**这是本 PR 的第一件事**，读不明白就停下来说明，禁止猜
- `lib/features/repos/domain/repositories/repos_repository.dart`、`lib/features/repos/data/datasource/`、`lib/features/repos/data/mappers/`、`lib/features/repos/domain/entities/repo.dart`（M1 + M3）
- `lib/features/auth/domain/`（`AuthState` / `AuthRepository` / `AuthDataSource`）、`lib/features/auth/data/`（`PatAuthRepository` / `FakeAuthDataSource`）、`lib/features/auth/presentation/`（M2）
- `lib/core/storage/`（`SecureStorage` / `FlutterSecureStorageAdapter` / `InMemorySecureStorage`）
- `lib/core/network/unauthorized_handler.dart` —— **`handleUnauthorized({repository, onInvalidated})` 纯函数**（M2 定稿）
- `lib/core/error/failure.dart`、`lib/core/providers/`（M1 留的 fake / remote 切换骨架）、`lib/core/router/`（M2）
- `lib/shared/widgets/`（M3 的 `AsyncStateView` 实现、`PagedList` 留的取消缝）
- `test/` 下 **66 个既有用例**、`tool/filter_spec.dart`、`tool/generate.dart`、`.cnb.yml`

M0/M1/M2/M3 已合入，全链门禁绿，工作区干净。本次只做 **M4：把两条 Fake 链换成 `cna_api` 真实 client**。

## 关键范围变化（先看清这一条，别按旧口径只换一条链）

M1 留了 `FakeReposDataSource`，**M2 又引入了 `FakeAuthDataSource`**。所以现在有两条假链，M4 必须**同时**换真：

| 链 | 现在 | M4 换成 | 调用 |
|---|---|---|---|
| ① 登录校验 | `FakeAuthDataSource` | `RemoteAuthDataSource` | `UsersApi` 校验 token |
| ② 仓库数据 | `FakeReposDataSource` | `RemoteReposDataSource` | `RepositoriesApi` 列表 / 详情 / 搜索 |

只换 ② 的话，App 会停在「真仓库 + 假登录」的半吊子状态，`restore()` 仍靠假种子通过，M5 横向铺开时所有 401 语义都要返工。**两条链一起换，一个 PR。**

内部建议按「`core/network/` 基础设施 → ① auth 链 → ② repos 链」三次提交，便于 review，但对外是一个可独立回滚的 M4。

## 范围

### 1. `lib/core/network/` 首次落地（M1–M3 都没有 Dio 实例）
- `dioProvider`：唯一一处建 `Dio`。`baseUrl` 从生成物 `core/` 或 spec 的 `host/basePath` 取，**禁止硬编码第二份**；connect / send / receive 超时集中配置
- `interceptors/` 按 `AGENTS.md` §5 的 **1→4 顺序**注册，顺序不得调整：
  1. **Auth**：注入 `Authorization: Bearer ${token}` + `Accept: application/json`，token 从 `SecureStorage` 读
  2. **Retry**：仅 `GET/HEAD/PUT/DELETE/OPTIONS` 的 5xx / 408 / 429 / 网络错误，最多 3 次指数退避并尊重 `Retry-After`；**POST/PATCH 不重试**、**401 不重试**
  3. **ErrorMapping**：HTTP 状态与网络异常统一映射为 sealed `Failure`，保留 status 供 UI 决策
  4. **Log**：结构化日志，**脱敏**，禁止打印 `Authorization` 头 / token / 凭据字段
- `error_mapper.dart`：`Failure` 五类映射，注意 dio 5.11.1 的两条新增语义 ——
  - exhaustive `switch` 必须补 `DioExceptionType.transformTimeout` 分支（归超时类、不重试）
  - `connection closed before full header` 已改判 `connectionError`，**必须在 Retry 里显式排除该子类或严格只按 method 白名单重试**，否则 POST 会被重发
- `pagination.dart`：`page` / `page_size` 统一分页 Notifier，feature 不得各写一套
- **Authorization 只注入一次**：若生成物 `core/` 已自带 auth 拦截器，配置它；否则由 `auth_interceptor.dart` 注入。两层同时注入 = 头重复，**禁止**
- **401 单一入口**：Dio 侧 `UnauthorizedInterceptor` **复用 M2 的纯函数 `handleUnauthorized({repository, onInvalidated})`**，通过构造注入 `AuthRepository` 与翻转回调。禁止把它改成 provider、禁止在拦截器里 `ref.read(authNotifierProvider)`（会造成 `handler → notifier → repository → handler` 循环）、禁止新建第二个 handler
- **重试只留一处**：Riverpod 3 失败 provider 默认自动重试，会与 Dio Retry 叠成 3×3 次请求。Repository / provider 侧对已知业务错误显式终止重试，重试统一交给 Dio 拦截器（§5）

### 2. ① auth 链
- `RemoteAuthDataSource implements AuthDataSource`：调 `UsersApi` 校验 token，返回类型按生成物 sealed response 穷尽处理
- 补 `data/mappers/`：真实 DTO → `AuthRepository` 需要的领域结果。**字段名复用 M2 已对齐的 `DtoUsersResult` 真实字段（`id` / `nickname` / `avatar` / …）**，禁止另造
- `PatAuthRepository` 的「401 原样上抛、不在本层处理」语义**不变**；`restore()` 的三态语义**不变**：
  - 校验通过 → `AuthSignedIn`
  - 401 → 走 `handleUnauthorized` → `AuthSignedOut` → 守卫跳登录
  - **网络失败 → 保持 `AuthUnknown` 并提供重试**（断网不等于被登出，不许加第四态）

### 3. ② repos 链
- `RemoteReposDataSource implements` 同一 `ReposRepository` 接口：列表 / 详情 / 搜索全部走 `RepositoriesApi`，分页参数走 `core/network/pagination.dart`
- 补 `data/mappers/`：DTO → M1 的 Freezed `Repo` 实体，字段缺失 / null 按 M1 mapper 既有策略收敛（计数 null → 0、path/name 缺失 → `FailureParse`）
- **接上 M3 的 `CancelToken` 缝**：`PagedList` 销毁时取消在途请求；但**只改 datasource / Notifier 层，`PagedList` 与所有 Widget 一行不动**

### 4. provider 切换
- 填 M1 留的 fake / remote 切换骨架：默认按环境选 remote，测试仍可 override 回 FakeDataSource（**66 条既有用例靠这个继续跑**）
- 新增 `dioProvider` / `apiClientProvider` / 两个 remote datasource provider 时，**每个 `@riverpod` 必须显式 `@Riverpod(name: '...')`** —— M2 实测 `riverpod_generator 4.x` 会自动剥掉 `Notifier` 后缀导致契约名静默漂移。生成后逐个核对 `AGENTS.md` §7 核心 provider 清单
- `ref.onDispose` 释放 Dio / CancelToken 等长生命周期资源

## 硬性验收线（本 PR 存在的唯一理由）

```
lib/features/**/presentation/   →  git diff 必须为空
lib/shared/widgets/             →  git diff 必须为空
lib/core/router/                →  git diff 必须为空
lib/core/theme/                 →  git diff 必须为空
```

**如果为了让真数据编译通过而需要改任何一个 UI 文件，立刻停下来**，说明是哪一层接口 / mapper 没设计好，回去修 `domain/` 或 `data/mappers/`，**不许改 UI 将就**。这条不成立就说明 M1/M3 的抽象没定对，M4 不合并。

## 明确不做

- **不装 `flutter_markdown_plus`、不渲染任何 Markdown、不做 README / Issue 正文** —— 方案已定但顺延到 **M5**（M4 的 UI diff 必须为空，装渲染库必然改 UI；见 `DESIGN.md` §6.1）
- 不改 `tool/spec_whitelist.yaml`、不改 `api/spec/*.json`、不改 `lib/generated/cna_api/` 任何文件 —— 7 个 tag 已含 `Users` 与 `Repositories`，**不需要重生成**；门禁仍跑 `--check` 验幂等
- 不写 issues / pulls / build 子页内容（M5），不改路由表、不动三 Tab 的 `StatefulShellRoute.indexedStack` / `TTabBar`
- 不改 `AuthState`（`@immutable` 值语义 sealed 三态，**不是 Freezed**），不改 M2 的 auth / 守卫 / `refreshListenable` 架构
- 不改 `lib/core/theme/` 的 Token 定义；不改 `AGENTS.md` / `DESIGN.md` 的禁令
- **不新增任何运行时依赖**（`dio` / `flutter_secure_storage` / `cna_api` 已足够）；不装 `material_ui` / `cupertino_ui`、不跑 `migrate_design_widgets`、不升 `go_router` 18+ 或 Flutter / Dart 基线
- 不让 widget 测试打真实 `https://api.cnb.cool`；真实 e2e 只留给 `integration_test` 且需流水线 `CNB_TOKEN`
- 不「顺便」重构无关页面、不实现 `FileTree` / `DiffView` / `CodeBlock` / `LogTerminal`（M5）

## 测试（66 条既有用例一条都不许删或放宽）

- **既有 66 条保持全绿**：它们 override 回 `FakeAuthDataSource` / `FakeReposDataSource`，正是「换 datasource 不动 UI」的活证明。**若 Agent 需要改这些用例才能过，说明抽象漏了**
- 新增 `core/network/` 单测：
  - 拦截器顺序、Auth 头只注入一次、`Authorization` 不进日志（断言脱敏）
  - Retry：GET 5xx/408/429 退避 3 次、尊重 `Retry-After`；**POST/PATCH 零重试**；`connectionError` 不触发 POST 重发；`transformTimeout` 不重试
  - ErrorMapping：401/403/404/422/5xx / 网络异常 / 解析失败 → `Failure` 各类，status 保留
  - `handleUnauthorized`：清存储 → 回调翻转 → 401 不重试；Fake 401 与 Dio 401 走同一入口
- 新增两条 remote 链的 mapper 契约测试：真实 DTO 字段缺失 / null / 类型变化，错误精确落在 `mappers/`
- 新增 `RemoteReposDataSource` 分页 / 搜索 / `CancelToken` 取消用例（mocktail mock 生成 client 或 Dio `HttpClientAdapter` 打桩）
- 新增 `ProviderContainer.test()`：remote 链 loading / error / data 三态；**验证 Riverpod 自动重试已被显式终止**（error 态可稳定断言，不 flaky）
- 带模拟延时的 widget 用例沿用 M2 经验：`pumpAndSettle` 不推进纯 `Future.delayed`，用 `pump(Duration)` 显式推钟
- M3 新增的 golden / 五态用例原样保留，浅深两套都要过；**禁止在门禁里传 `--update-goldens`**

## 门禁（改完自己跑完并修到绿，别把红灯留给我）

```bash
dart run tool/filter_spec.dart --check      # 白名单未变，必须字节级幂等
dart run tool/generate.dart                 # 清理并重生成 cna_api，确认 git diff 为空
dart run build_runner build                 # 新增注解类产出的 *.g.dart / *.freezed.dart 必须提交
dart format lib test
flutter analyze
flutter test
```

再本地复跑 `.cnb.yml` 完整链，确认：

- freshness gate 的 `git diff --exit-code` 仍覆盖四项：`api/spec/mvp.json`、`lib/generated/`、`lib/**/*.g.dart`、`lib/**/*.freezed.dart`（M2 已补齐，本次新增注解类会产出新 `.g.dart`，**不得退回只查两项**）
- `flutter pub get --enforce-lockfile` 通过、`pubspec.lock` 未变（本 PR 不新增依赖）、`git diff --exit-code` 全绿
- **单独打印一次 `git diff --stat -- lib/features/**/presentation lib/shared/widgets lib/core/router lib/core/theme`，输出必须为空**，作为验收线证据附在 PR 描述里

## 交付格式

**先输出 3–5 步计划**，其中必须专门说明四件事：

1. 你读 `lib/generated/cna_api/core/` 后，确认生成物自带的 auth 形态是什么、**Authorization 打算在哪一层注入一次**
2. `UnauthorizedInterceptor` 怎么注入 `repository` / `onInvalidated` 来复用 `handleUnauthorized` 纯函数，且**不引入 Riverpod 循环**
3. 两条链（auth + repos）的 mapper 分别怎么处理 sealed response 与字段缺失 / null
4. 怎么保证 `lib/**/presentation` 与 `lib/shared/widgets/` 的 diff 为空；若哪一处分不开，打算回哪一层修

等我确认再改文件。
一个 PR 只做 M4；内部按「core/network → auth 链 → repos 链」三次提交，改动可独立回滚。
