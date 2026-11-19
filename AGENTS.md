# AGENTS.md

> 本文件是 **cnb.cool Flutter 移动端客户端** 的项目级 Agent 规则，所有对话自动加载。
> 视觉相关的一切以同目录 `DESIGN.md` 为准；本文件只管架构、技术栈、命令与禁令。
> 冲突优先级：用户在对话里的显式指令 > 离被编辑文件最近的规则 > 本文件 > `DESIGN.md` 中与之不冲突的部分。

---

## 0. 项目定位

一个面向 **cnb.cool（CNB 云原生构建 / 代码托管平台）** 的第三方移动客户端，Flutter 单代码库覆盖 Android / iOS。

- 后端唯一事实源：CNB OpenAPI，`https://api.cnb.cool`，Swagger：`https://api.cnb.cool/swagger.json`
- 认证：一期 **个人访问令牌（PAT）**，二期评估 OAuth 2.0
- 参考实现：Rust CLI/SDK 仓库 `cnb-rs`（`cnb` crate）。**它是参考，不是运行时依赖**
- 本仓库不写任何 Rust。Rust 下沉是二期选项，见 §9

一句话边界：**本项目是「类型安全的 HTTP 客户端 + 设计系统组合」，不是计算密集型应用。**

---

## 1. 技术栈与版本矩阵（锁定，不得整体升级）

### 1.0 版本基线决策（先读这一段）

本项目 **2026-11 起始基线**固定为：

| 项 | 版本 | 说明 |
|---|---|---|
| Flutter | **`3.47.9`** | 3.47 线最新 hotfix（2026-10-29） |
| Dart | **`3.13.7`** | 与 3.47.9 捆绑 |
| `environment` | `sdk: '>=3.13.7 <4.0.0'`、`flutter: '>=3.47.9'` | 语言版本门控由下限决定，不得随意抬高 |

**这不是当前最新稳定版**。最新稳定是 Flutter `3.50.0` / Dart `3.14.0`（2026-11-11）。选 3.47.9 而非 3.50 是有证据的取舍，完整推理与升级路线见 **§15**；**禁止 Agent 以「升到最新」为由自行改动本节**。

四条会影响每一行 UI 代码的事实：

1. **`tdesign_flutter` 1.1.0 的 changelog 明确修复了 Flutter 3.47 下的兼容问题**：`TSlider` / `TRangeSlider` 的滑块提示、`DropdownMenu` / `CupertinoSwitch` / `Swiper` 的跨版本 API 行为，并「兼顾 Flutter 3.32 与较新版本」。但 changelog **未声明支持 3.50 或 `material_ui`**，FAQ 仍只写 `Flutter ≥3.32.0 / Dart ≥3.8.0` 的下限
2. **`tdesign_flutter` 的单一入口 `package:tdesign_flutter/tdesign_flutter.dart` 导出的是 SDK 内 `package:flutter/material.dart` 的 `MaterialApp` / `Scaffold` / `Text`**（官方快速开始原文）。因此本项目属于「legacy Material」阵营，不是 `material_ui` 阵营
3. Flutter 3.47 中 SDK 内的 material / cupertino **已冻结但未标记 deprecated**；3.50 起才正式 deprecated，`flutter create` 默认切到 `material_ui`。3.47 是设计库解耦的迁移窗口期，不是终态
4. **`go_router` 18.0.0 起迁到 `material_ui`**，通过 `findAncestorWidgetOfExactType` 检测 `material_ui.MaterialApp`。在 legacy `MaterialApp.router` 下，所有 `builder:` 路由会**静默退化为 `NoTransitionPage`**：丢页面转场、丢 iOS 侧滑返回、404 页无 `Scaffold`。**不报编译错误，现有测试仍会通过**

因此本期组合是：**Flutter 3.47.9 + TDesign 1.1.0 + go_router 17.5.x + 其余依赖取已验证的最新版**。判据是「组件库明确适配」，不是「版本号最大」。

### 1.1 依赖矩阵

| 层 | 选型 | 版本 / 约束 | 关键理由 |
|---|---|---|---|
| UI 组件 | `tdesign_flutter` | **`>=1.1.0 <1.2.0`** | 禁止 `^1.0.0`（会解析到含破坏性变更的 1.1.0）；1.x 内也曾出现 breaking，故锁到 `<1.2.0`。`pubspec.lock` 入库，升级必跑 golden 回归 |
| 状态运行时 | `flutter_riverpod` | **3.x**（3.4.3+） | 需 Dart ≥3.12。Riverpod 3 把 `StateProvider` / `StateNotifierProvider` / `ChangeNotifierProvider` 移入 `legacy.dart`，**禁止使用**；失败 provider 默认自动重试（与 §5 的重试拦截器叠加会放大请求量，见 §5） |
| 状态生成器 | `riverpod_annotation` + `riverpod_generator` | **4.x**，两者同主版本 | **生成器主版本 4 ≠ 运行时 3**，这是正常现象，但两者必须锁同一主版本；provider 一律接收普通 `Ref`，不存在 `UserProfileRef` 之类生成的子类 |
| 路由 | `go_router` | **`>=17.5.0 <18.0.0`** | **刻意不升 18**，理由见 §1.0 第 4 条。17.2.1 已修复链式顶层 redirect，17.5.0 支持 route metadata。URL 自 15.0.0 起大小写敏感 |
| 网络 | `dio` | **5.11.1+** | 5.11 新增 `DioExceptionType.transformTimeout`，exhaustive switch 需补分支；`connection closed before full header` 改判为 `connectionError`（见 §5） |
| 领域模型 | `freezed` **4.0.2+** + `freezed_annotation` + `json_annotation` + `json_serializable` | freezed 需 Dart 3.13 | **freezed 3.x 生成代码含 `final` 参数，Dart 3.13 语言版本下会报 `extraneous_modifier`**；4.0.0 起移除。类需 `sealed` / `abstract`。禁止手改 `*.freezed.dart`，必须重跑生成器 |
| API 客户端 | 由 `api/spec/mvp.json` 用 **`openapi_flutter_gen`** 生成 | 生成器置于 `tool/` 独立工程 | 见 §4.2。主 app 的 `pubspec.yaml` **不含任何生成器依赖** |
| 代码生成 | `build_runner` | **2.16.1+** | **`--delete-conflicting-outputs` 已被移除**（传入会告警并被忽略）；2.16 默认修正错误的生成文件；CI 用 `--only-check` 做新鲜度门禁（见 §3） |
| 安全存储 | `flutter_secure_storage` | 由 `flutter pub add` 解析 | token 唯一存放处（Keystore / Keychain） |
| 偏好存储 | `shared_preferences` | 由 `flutter pub add` 解析 | 仅非敏感项 |
| 本地化 | `flutter_localizations` + `intl` | 中文优先 | **3.47 起 `flutter_localizations` 已 unbundle**，delegates 迁往 `material_ui` / `cupertino_ui`；本期仍按 legacy 方式注册（见 `DESIGN.md` §9），迁移 `material_ui` 时一并改 |
| 内容渲染 | `flutter_markdown`、`flutter_highlight` + `highlight`、`cached_network_image`、`flutter_svg` | 由 `flutter pub add` 解析 | `flutter_markdown` 仍依赖 legacy Material，`MaterialUiCompatibilityBridge` 场景下需重点回归 |
| 质量 | `very_good_analysis` / `flutter_lints`、`riverpod_lint` **3.1.9+**、`mocktail`、`flutter_test`、`integration_test` | riverpod_lint 需 Dart 3.13 | 见 §1.2 / §10 |

**依赖安装纪律**：用 `flutter pub add <pkg>` 让 pub 按当前 SDK 解析兼容版本，**禁止**手工把版本号敲进 `pubspec.yaml`，也禁止 `flutter pub upgrade --major-versions` 一把梭。装完立刻把 `pubspec.lock` 提交，`flutter pub get --enforce-lockfile` 是 CI 第一步。

**硬性写法要求**：在任何规则、注释、文档里提到技术栈时必须带主版本或版本范围，**禁止**只写「Flutter」「Riverpod」「TDesign」这类裸名词。

### 1.2 `riverpod_lint` 的特殊规则

`riverpod_lint` 基于 analysis server 插件（**不是**旧的 `custom_lint`），**禁止**加入 `pubspec.yaml` 的 dependencies / dev_dependencies（会钉死 riverpod 精确版本并与 analyzer 冲突）。只在 `analysis_options.yaml` 顶层启用：

```yaml
plugins:
  riverpod_lint: ^3.1.9
```

禁止写成 `analyzer.plugins`（旧格式）；版本从 pub.dev 取最新，不要从 `pubspec.yaml` 复制。

---

## 2. 目录结构（feature-first）

```
lib/
├── core/
│   ├── config/          # 环境、baseUrl、常量；禁止放密钥
│   ├── network/         # dioProvider、interceptors/、error_mapper、pagination
│   ├── providers/       # 跨 feature 的核心 provider
│   ├── router/          # app_router.dart、routes.dart、guards.dart
│   ├── storage/         # secure_storage、prefs；封装后才允许被 Repository 使用
│   ├── theme/           # 见 DESIGN.md；TThemeData / TThemeBuilder / app_tokens.dart
│   └── error/           # sealed Failure、AppError
├── features/
│   └── <feature>/       # auth, repos, issues, pulls, build, releases,
│       ├── data/        #   dto/、mappers/、datasource/、repo_impl/
│       ├── domain/      #   entities/（Freezed）、repositories/（抽象接口）
│       └── presentation/#   pages/、widgets/、state/（AsyncNotifier）
├── shared/
│   ├── extensions/
│   └── widgets/         # 自建业务组件（见 DESIGN.md §6）
├── generated/           # OpenAPI 生成产物；禁止手改、禁止手删单个文件
└── main.dart
api/spec/
├── swagger.full.json    # 全量 Swagger 2.0 快照，单一事实源
└── mvp.json             # 按白名单裁剪后的一期子集（脚本产出，commit）
tool/                    # 独立 Dart 工程，与主 app 的 SDK 约束隔离
├── pubspec.yaml         #   仅放生成器与脚本依赖
├── spec_whitelist.yaml  #   tag 白名单，顺序固定
├── filter_spec.dart     #   swagger.full.json → mvp.json
└── generate.dart        #   mvp.json → lib/generated/
docs/prompts/            # 里程碑 prompt 归档
test/  integration_test/
```

### 分层铁律

```
Widget  →  AsyncNotifier(Riverpod)  →  Repository(抽象接口)  →  RemoteDataSource
                                          ↑                        ↑
                                     domain 层纯 Dart          生成的 API client
```

- **依赖方向单向**：`presentation → application/state → domain ← data`。`domain` 不得 import `package:flutter/material.dart`、不得 import 任何 `*.g.dart`、不得知道 Dio / TDesign / 生成客户端的存在
- **DTO 不得进 UI**：`data/dto` 的对象必须在 `mappers/` 转成 `domain/entities` 的 Freezed 实体；Widget 只渲染实体
- **Repository 接口在 domain，实现在 data**：这是 §9 预留的替换缝，任何时候不得为了省事让 Widget 直接调 datasource
- 每个 feature 自带 `state/`，禁止跨 feature 直接读别人的 Notifier；跨模块数据走 `core/providers`
- 禁止全局服务定位、禁止 `Get.put` / `Get.find` 式的隐式单例

---

## 3. 开发命令（Agent 每次交付前必须跑）

```bash
# 依赖（CI 必须带 --enforce-lockfile）
flutter pub get --enforce-lockfile

# OpenAPI 链：仅当 api/spec/*.json 或白名单变更时跑，在项目根执行
# （tool/ 是独立工程，生成器依赖锁在 tool/pubspec.lock，不进主 app）
dart run tool/filter_spec.dart        # swagger.full.json → mvp.json
dart run tool/generate.dart           # mvp.json → lib/generated/
# 跑两次确认幂等；产物禁止手改、禁止手删

# Dart 代码生成（顺序固定）
dart run build_runner build           # 注意：2.16 起不要再加 --delete-conflicting-outputs
dart run build_runner build --only-check   # CI 专用：磁盘产物与生成器不一致即失败

# 静态与格式
dart format lib test                 # 本地
dart format --output=none --set-exit-if-changed .   # CI：只检查不改写
flutter analyze
dart fix --dry-run                   # 升级 SDK / 依赖后查看待迁移项

# 测试
flutter test
flutter test integration_test        # 需要真机/模拟器时

# 启动
flutter run
```

**门禁顺序**：`依赖 → spec 生成 → build_runner → 幂等/新鲜度检查 → format → analyze → test`。任何一步失败，先修再交付，不得把红灯留给用户。

**新鲜度门禁**（CI，强制）：重新执行 `filter_spec.dart` + `generate.dart` + `build_runner build` 后，`git diff --exit-code -- api/spec/mvp.json lib/generated/` 必须为空。生成器版本由 `tool/pubspec.lock` 钉死，避免工具链漂移造成「巨大 diff 其实只是格式化变了」。

修改 `pubspec.yaml`、`tool/spec_whitelist.yaml`、`api/spec/*.json`、路由表或 SDK 版本后必须重跑完整链。`lib/generated/**` 在 `.gitattributes` 标记为 `linguist-generated=true`，PR 中折叠显示。

**Safety**：动手前先读目标文件现状；禁止盲目覆盖、禁止删除无关用户代码；删除文件、改路由表结构、改依赖主版本、改 `main.dart` 入口等破坏性操作必须先征得确认。

---

## 4. API 契约与生成

### 4.0 契约事实

- 唯一契约源：`https://api.cnb.cool/swagger.json`，快照存 `api/spec/swagger.full.json`
- **它是 Swagger 2.0（`"swagger": "2.0"`），不是 OpenAPI 3.x**。`openapi.json` 端点存在但返回 401 需登录，**禁止**当作契约源
- 规模：约 **184 个 path / 282 个 definitions**（`cnb` Rust crate 口径为 241 个操作 / 28 个资源模块 / 271 个模型，一个 path 可挂多个 method，两者不矛盾）
- 全量生成约 550 个文件 / 3–6 万行。**本项目不生成全量**，按 §4.2 裁剪后只生成一期子集
- 生成产物落在 `lib/generated/`，**禁止手工编辑、禁止手工删单个文件**，禁止拆散到 features
- 生成客户端不负责业务语义。重试、错误映射、分页语义写在本仓库 `core/network/`（照抄 §5）
- 与 `cnb-rs` 的关系：其 SDK 由 `codegen/cnb-codegen` 从**同一份** swagger 生成；**两者是同源兄弟，不是父子**。我们的 feature 划分照抄它的模块名，不照抄它的代码，也不把 Rust 仓库喂给 Agent

### 4.1 生成器选型（已收敛）

**只用 `openapi_flutter_gen`**（`dev_dependencies` 放在 `tool/pubspec.yaml`，作为独立 CLI）：

- 支持 Swagger 2.0（`SwaggerNormalizer.normalize`）；产出不可变模型、sealed exhaustive responses、typed auth interceptor、分页助手、可选 `Isolate.run` 反序列化
- **零 build_runner**：生成一次得到纯 `.dart` 源码，commit 即用；主 app 不需要任何生成器依赖
- 置于 `tool/` 独立工程后，生成器自身的依赖（`freezed 4` / `retrofit 4` 等）与版本锁不污染主 app 的 `pubspec.yaml` / `pubspec.lock`；主 app 只吃生成好的纯 Dart 源码，未来升级生成器不会动到 app 的依赖树

**备选**：`swagger_parser` 2.3.0（按 tag 分 client 目录、`--check` 只比对不写文件），但需 `serializer: plain` 且 Retrofit/Freezed 组合会引入 build_runner，性价比更低。`dart_openapi_generator` **明确不支持 Swagger 2.0**，禁止使用。OpenAPI Generator（Java）过滤能力最强但要引 Java 工具链，本期不引入。

**生成层用 plain DTO，禁止 Freezed**：

```
lib/generated/      plain class + fromJson/toJson   ← 零 build_runner，机器所有
data/mappers/       DTO → Entity 转换                ← 手写，可测
domain/entities/    @freezed 不可变实体              ← 手写，build_runner
```

这样 `build_runner` 只服务 Riverpod / Freezed 一条链，上游改字段名时编译错误精确落在 `mappers/` 一处。

**契约变更流程**：更新 `swagger.full.json` → 重跑裁剪与生成 → `flutter analyze` 暴露 breaking change → 修 `mappers/` 与 `repo_impl/` → 跑 golden/单测 → 提交。

### 4.2 spec 裁剪流程（全量入库，子集生成）

```
api/spec/swagger.full.json     ← 全量快照，单一事实源，CI 定期 diff 上游
        ↓  tool/filter_spec.dart（tag 白名单 + $ref 可达性剪枝）
api/spec/mvp.json              ← 一期子集，纳入版本控制，可 review
        ↓  tool/generate.dart（openapi_flutter_gen CLI）
lib/generated/                 ← commit，禁止手改
```

**裁剪必须发生在 spec 层，不是生成后删文件**。删生成文件破坏可复现性——下次生成又回来，且无法解释「为什么少了这几个」；裁剪 spec 是声明式的，白名单进 git，谁改了、为什么改一目了然。

`tool/filter_spec.dart` 的三项职责：

1. 遍历 `paths`，只保留 `operation.tags` 命中 `tool/spec_whitelist.yaml` 的 method；无剩余 method 的 path 整条删除
2. **递归解析 `$ref`**（Swagger 2.0 为 `#/definitions/xxx`），保留被保留操作间接引用的全部 definitions，传递闭包不得断
3. 保留顶层 `securityDefinitions` / `host` / `basePath` / `info`；**白名单顺序固定**

第 3 点的顺序必须稳定：生成器按「首个使用该共享模型的 client」决定模型归属目录，白名单顺序一变，import 路径会整体漂移。

**一期白名单固定为 7 个 tag**：`Users` / `Repositories` / `Issues` / `Pulls` / `Git` / `Build` / `Activities`（对齐 M3 垂直切片）。粗估从 184 paths 砍到 ~50、282 definitions 砍到 ~70，生成文件从 ~550 降到 ~120。

**加 feature 时只改 `spec_whitelist.yaml`**，重跑生成，一个 PR。禁止为了少生成文件而手写 DTO，也禁止把全量 28 个 tag 一次放开。

### 4.3 feature 划分（对齐 cnb-rs 资源模块）

`auth` · `repos` · `issues` · `pulls` · `git` · `releases` · `build` · `workspace` · `organizations` · `members` · `search` · `starring` · `activities` · `assets` · `artifactory` · `registries` · `missions` · `wiki` · `knowledge_base` · `labels` · `contributors` · `settings` · `users`

一期 MVP 只做：`auth`、`repos`、`issues`、`pulls`、`build`（只读状态）。其余 feature 建空目录占位即可，禁止提前铺开。

---

## 5. 网络层约定（语义照搬 cnb-rs）

`core/network/interceptors/` 按以下顺序注册，顺序不得调整：

1. **Auth**：注入 `Authorization: Bearer ${token}` 与 `Accept: application/json`。token 从 `SecureStorage` 读，禁止硬编码、禁止从 `shared_preferences` 读
2. **Retry**：对 `GET/HEAD/PUT/DELETE/OPTIONS` 的 `5xx` / `408` / `429` / 网络错误最多 **3 次**指数退避，尊重 `Retry-After`。**POST/PATCH 不自动重试**（防重复创建 Issue/PR）
3. **ErrorMapping**：把 HTTP 状态与网络异常统一映射为 sealed `Failure`（`Failure.http(status, body)` / `Failure.network` / `Failure.unauthorized` / `Failure.parse` / `Failure.unknown`）。保留 status 供 UI 决策
4. **Log**：结构化日志，**必须脱敏**——禁止打印 `Authorization` 头、token、完整请求体中的凭据字段

其他约定：

- 超时：connect / send / receive 分别设定并集中配置，禁止散落魔法数字
- 分页：统一 `page` / `page_size`；分页状态放在 `core/network/pagination.dart` 的通用 Notifier，feature 不得各写一套
- 取消：页面销毁时取消在途请求，使用 `CancelToken`
- 附件上传/下载、构建日志流走流式响应；禁止把整段日志一次性读进 `List<int>` 再解析
- **401 统一处理**：清空安全存储中的 token → 翻转 `AuthState` → 由路由守卫跳登录，禁止在各页面分散写 `if (401)`
- **dio 5.11+ 两条新增语义**：① `DioExceptionType.transformTimeout` 已加入枚举，`Failure` 映射的 exhaustive `switch` 必须补分支（归为超时类、不重试）；② `connection closed before full header was received` 从 `unknown` 改判为 `connectionError`。若 Retry 拦截器按「网络错误」笼统重试，**POST 会被重发**。必须在 Retry 里显式排除该子类，或严格只按第 2 条的白名单 method 重试
- **Riverpod 3 默认自动重试失败的 provider**（指数退避），会与 Dio 的 Retry 拦截器叠加放大请求量。Repository 层必须只保留一处重试（优先 Dio 侧），并在 provider 侧对已知业务错误显式终止，避免 3×3 次请求

---

## 6. Auth & Session

### 一期：PAT（实现这个）

- 入口：用户粘贴 / 扫码填入访问令牌 → 调一次用户信息接口校验 → 建立 Session
- 令牌由用户在 CNB「个人设置 → 访问令牌」创建，可设到期时间、使用范围、授权范围。**App 侧按最小权限引导，不索要超出需要的 scope**
- 默认权限现实：公开组织/仓库/制品库/任务集默认只读，私有仓库/制品库默认无权限，账号相关权限默认无权限。UI 必须优雅处理「有 token 但看不到该资源」，不得当成崩溃
- token 生命周期：只在内存 + `flutter_secure_storage`；App 进入后台不做额外处理；退出登录必须显式清除
- `AuthState` 为 sealed：`AuthUnknown`（启动解析中，渲染 Splash）/ `AuthSignedOut` / `AuthSignedIn`

### 二期：OAuth（**本轮不实现，仅预留**）

- 前置门槛：官方 OAuth 应用需提交管理员审核上架；流程是 `code + ClientID + ClientSecret` 换 `access_token`；`redirect_uri` 域名需与审核登记一致
- 移动端是 public client，**无法安全内嵌 ClientSecret**。落地前必须先确认平台是否支持 PKCE、是否允许 HTTPS App Links / Universal Links 回调；否则维持 PAT 或走后端 BFF
- 禁止用 WebView 承载授权页；必须用系统浏览器组件（Chrome Custom Tabs / ASWebAuthenticationSession）
- 据此，**登录页与 `AuthRepository` 接口必须与「token 从哪来」解耦**：一期实现 `PatAuthRepository`，二期可换 `OAuthAuthRepository` 而不动 UI

---

## 7. 状态管理与路由约定

### Riverpod

- 用 `@riverpod` 注解生成 provider，禁止手写 `Provider((ref) => ...)` 之外的重复样板
- 异步 UI 状态一律用 `AsyncNotifier` / `FutureProvider`，通过 `AsyncValue.when` 显式渲染 loading / error / data；**禁止**把 loading 藏在 `bool isLoading` 里
- 核心 provider：`authNotifierProvider`、`dioProvider`、`apiClientProvider`、`routerProvider`、`themeProvider`、`secureStorageProvider`、`prefsProvider`
- 测试用 `ProviderContainer.test()` + override 做隔离；禁止依赖全局状态、禁止为测试引入 mock 框架 hack
- provider 的 dispose 交给 `ref.onDispose`，长生命周期资源必须显式清理

### go_router

- 顶层 `redirect` 写成**纯函数** `appRedirect(AuthState, GoRouterState)`：不 await、不做 IO、不写 provider、不读 `DateTime.now()`；返回 `null` 或目标 location
- 用 `refreshListenable` 把 `authNotifierProvider` 桥接成 `Listenable`（`ref.listen(...)` → `ValueNotifier`），登录/登出立即重跑守卫
- **防死循环**：显式放行 `/login` 自身；比较 `state.matchedLocation` 而不是原始 URI
- 深链保留：跳登录时用 `?from=<encoded>` 携带原目标，登录成功后回到原页面
- 底部 Tab 用 `StatefulShellRoute`，各 Tab 独立导航栈
- 路由表集中放在 `core/router/routes.dart`，禁止在 Widget 里拼字符串路径
- 必须提供 404、离线页、会话过期页

### 路由表（对齐 cnb-rs 命令组）

| 路径 | 页面 | 一期 |
|---|---|---|
| `/splash` | 启动解析 AuthState | ✅ |
| `/login` | PAT 登录 / 权限说明 | ✅ |
| `/` | 首页（动态 / 最近仓库） | ✅ |
| `/repos` | 仓库列表（分页 + 搜索） | ✅ |
| `/repo/:owner/:name` | 仓库详情（Shell：code / issues / pulls / releases / build / settings） | ✅ |
| `/repo/:owner/:name/issue/:id` | Issue 详情 + 评论 | ✅ |
| `/repo/:owner/:name/pull/:id` | PR 详情 + review + files | ✅ |
| `/build/:id/logs` | 构建日志流 | ✅（只读） |
| `/search` | 全局搜索 | ⬜ |
| `/org/:name`、`/workspace`、`/registries`、`/missions`、`/wiki` | 对应资源 | ⬜ 占位 |
| `/settings` | 主题、语言、列表密度、退出登录 | ✅ |

---

## 8. Design System 接口

UI 的一切以 `DESIGN.md` 为准。本文件只强调三条架构级约束：

1. `lib/core/theme/` 是主题唯一出口；feature 目录下禁止出现第二份 `ThemeData` / 色板定义
2. 组件优先级：TDesign 组件 → `lib/shared/widgets` 自建业务组件 → Material 原生组件
3. 禁止硬编码 `Color(0xFF…)`、裸 `EdgeInsets` 数值、内联 `TextStyle`；一律走 `context.tTheme` / `AppSpacing` / `Theme.textTheme`

---

## 9. Rust / flutter_rust_bridge 边界（二期选项，本期禁止）

**本期不引入 `flutter_rust_bridge`、不引入任何 Rust 代码、不引入 NDK / cargo 构建链。** 理由：cnb-rs 的核心资产是从 swagger 生成的 HTTP 客户端，Dart 侧从同一 spec 生成即可等价获得；FRB 只替换 remote datasource，省不掉 Riverpod / go_router / Auth / 设计系统任何一层，却新增整套交叉编译、双 codegen、包体积与 FFI 取消安全性成本。

**但仍须预留替换缝**（这是本期就要做对的唯一一件事）：

- `Repository` 抽象接口放 `domain/`，`RemoteDataSource` 单独一层放 `data/datasource/`
- 将来若因「离线 git 对象解析 / 超大构建日志流式处理 / 端侧加密」下沉 Rust，**只换 datasource 实现**，UI / state / router 一行不动
- 若真要下沉：只暴露**窄而重**的函数，token 由 Dart 侧传入、Rust 不持久化；Rust 侧保持 `rustls-tls`（禁止 OpenSSL）；所有导出函数 `catch_unwind` 兜底；Stream 必须配一个显式 `cancel()`（FRB 的 `StreamSink` 缺 `onCancel`，Dart 取消订阅不会通知 Rust，会泄漏长连接）
- 引入条件：必须有 benchmark 证明瓶颈真实存在，且 benchmark  gates 进 CI。**没有证据不得合入**

---

## 10. 测试与验收门禁

| 类型 | 覆盖 |
|---|---|
| 单元测试 | `mappers/`（DTO→Entity 边界，含字段缺失/null）、`Failure` 映射、`appRedirect` 纯函数、分页 Notifier |
| Provider 测试 | `ProviderContainer.test()` + override datasource，覆盖 loading / error / data 三态 |
| Widget 测试 | 登录页、仓库卡片、五态渲染；禁止依赖真实网络 |
| Golden test | `lib/shared/widgets` 与 TDesign 主题组合，**早加**，专门防 AI 把视觉改漂 |
| 集成测试 | 登录 → 仓库列表 → 详情 → 退出登录 主链路 |
| 静态 | `flutter analyze` 零警告；`riverpod_lint` 零告警 |

**每个 PR 的完成定义**：

- [ ] 上述命令链全绿
- [ ] 新增/修改代码有对应测试
- [ ] 无裸 hex / 无魔法间距 / 无内联 TextStyle
- [ ] 涉及列表的页面实现 loading / empty / error / offline / dark 五态
- [ ] 日志脱敏检查通过（grep 无 `Authorization` / token 打印）
- [ ] 未引入 `GetX`、未手写 API DTO、未手改 `lib/generated/`
- [ ] 一个 PR 只做一个 feature，改动可独立回滚

CI 跑在 **cnb.cool 云原生流水线**上（本项目即给 CNB 写客户端，用 CNB 构建自家 App）；流水线临时令牌 `CNB_TOKEN` 只用于联网 e2e，禁止写进仓库。

---

## 11. 安全与密钥卫生

- `.env`、`keystore`、签名配置、`google-services.json`、任何 token 一律 `.gitignore`，禁止进入 prompt、禁止贴给模型、禁止上传
- 使用 DeepSeek / CodeBuddy 等云端 Agent 时：prompt、Agent 读过的文件内容、命令输出会发往模型服务端，会话日志包含输入输出与工具调用。**提交前检查工作区不含敏感文件**
- 日志脱敏是硬门禁（§5 第 4 条）
- token 不写入 `shared_preferences`、不写普通文件、不进崩溃上报的自定义字段
- 发布构建：`--obfuscate --split-debug-info`；调试日志在 release 关闭

---

## 12. 硬禁令（Don'ts）

1. 禁止 `GetX` 及任何 `Get.put` / `Get.find` / `.obs` 全局单例
2. 禁止 `GetX` 路由与 `go_router` 并存（两套路由 = 灾难）
3. 禁止手写 API DTO / HTTP 调用 / `fromJson`；必须来自 swagger 生成
4. 禁止把 DTO、`*.g.dart`、生成客户端直接 import 进 Widget
5. 禁止 `Color(0xFF…)`、`Colors.*` 裸用、`EdgeInsets.all(13)` 这类魔法值、内联 `TextStyle(fontSize: …)`
6. 禁止在 Widget 里写业务逻辑、网络调用、路由跳转字符串
7. 禁止 token 进日志 / `shared_preferences` / prompt / git
8. 禁止 `^1.0.0` 形式的 tdesign 依赖；禁止把 `riverpod_lint` 写进 `pubspec.yaml`
9. 禁止在 `go_router` 的 `redirect` 里 await / 做 IO / 写 provider
10. 禁止 POST/PATCH 自动重试
11. 禁止本期引入 Rust / FRB / NDK / cargo
12. 禁止一次性生成多个 feature；禁止「顺便」重构无关页面
13. 禁止臆造 TDesign 组件名或 API（以当前依赖版本实际导出为准，不确定先查 `example/` 或文档）
14. 禁止把 GitHub 客户端截图当作 UI 输入（见 §13）
15. 禁止把 Flutter / Dart 基线自行升到 `3.50.x` / `3.14.x`（见 §15：需独立 PR，且先等 TDesign 与内容渲染库适配 `material_ui`）
16. 禁止 `go_router >=18.0.0`（在 legacy Material 树下会静默丢失页面转场、iOS 侧滑与 404 的 Scaffold）
17. 禁止引入 `material_ui` / `cupertino_ui` 与 `package:flutter/material.dart` 混用；禁止对 `lib/` 执行 `dart fix --apply --code=migrate_design_widgets`
18. 禁止给 `build_runner build` 传 `--delete-conflicting-outputs`（2.16 起已移除，传入只会告警并被忽略）
19. 禁止 `flutter pub upgrade --major-versions`、禁止手填依赖版本号、禁止手工删 `lib/generated/` 里的单个文件

---

## 13. AI 协作流程（Spec-First）

1. **开工前**先读本文件 + `DESIGN.md`，再读目标目录现状；不要凭印象开工
2. **一次一个 feature / 一个页面**。提示词里显式 @ 上 `DESIGN.md` 和该 feature 的 `Repository` 接口
3. 生成 UI 时的固定话术：「只组合白名单组件，不新建等价组件，不改其他页面，五态齐全，Token 优先」
4. 改完立刻跑 §3 命令链；失败先修再交付，不把红灯留给用户
5. **截图规则**：
   - 唯一值得传图的环节是 **自家 App 真机截图做视觉回归**，配结构化指令「这张只定布局，配色以 `DESIGN.md` 为准；只修间距溢出，不改交互与暗色 Token」
   - 允许参考 cnb.cool 自家 Web 端 / TDesign 组件示例页来对齐品牌视觉
   - **禁止把 GitHub 客户端截图当输入**：产品是 cnb.cool 客户端，信息架构不匹配、有原创性风险，且静态截图不携带组件层级 / 响应式 / 交互 / 暗色 / 五态
   - 若要传图，须确认所用 Agent 通道真的把图片透传给支持视觉的模型；「SDK 能调通」不等于「Agent 能读图」
6. 一个 feature = 一个 PR；CI 门禁不过不合并
7. 规则文件本身随架构演进更新，但**不得由 Agent 自行放宽 §12 的禁令**

---

## 14. 术语与参考

| 词 | 含义 |
|---|---|
| CNB / cnb.cool | 腾讯云原生构建平台，本项目服务对象 |
| PAT | 个人访问令牌，一期登录方式 |
| OpenAPI / swagger.json | `https://api.cnb.cool/swagger.json`，241 个操作 / 28 个资源模块 |
| cnb-rs | 用户自有的 Rust CLI + `cnb` SDK 仓库，**参考实现，非依赖** |
| Token（TDesign） | `TThemeData` 中的全局颜色/字体/间距变量，与「访问令牌」不同义 |
| 五态 | loading / empty / error / offline / dark |
| FRB | flutter_rust_bridge，二期选项 |

外部权威来源（按需查证，禁止凭记忆写 API）：
- CNB OpenAPI：`https://docs.cnb.cool/zh/develops/openapi.html`
- 访问令牌：`https://docs.cnb.cool/zh/guide/access-token.html`
- OAuth 应用：`https://docs.cnb.cool/zh/oauth/developer`
- TDesign Flutter 更新日志 / 自定义主题 / FAQ：`https://tdesign.tencent.com/`
- `cnb` crate 文档：`https://docs.rs/cnb`
- Flutter 版本与 Dart 对应关系：`https://docs.flutter.dev/release/archive`
- Flutter breaking changes：`https://docs.flutter.dev/release/breaking-changes`

---

## 15. 版本升级策略（本项目专有，Agent 不得自行触发）

### 15.1 现状（2026-11-20）

| 版本 | 状态 | 本项目的态度 |
|---|---|---|
| Flutter `3.47.9` / Dart `3.13.7` | 3.47 线最新 hotfix | **✅ 当前基线** |
| Flutter `3.50.0` / Dart `3.14.0` | 2026-11-11 发布的最新稳定 | **⏸ 暂不升**，等条件 |
| Flutter `3.51.0-0.1.pre` / Dart `3.15.0` | beta | 禁止 |

**注意**：本项目 2026-11 才起步、尚无业务代码，因此这里讨论的是「**选起始基线**」而不是「升级存量项目」。这反而更该保守——第一版就要跑通全链路，不该同时承担生态迁移。

### 15.2 为什么不「全部升到最新」

四条硬理由，逐条对应本项目的依赖：

1. **TDesign 1.1.0 只声明修了 3.47 兼容，未声明支持 3.50 / `material_ui`**。它的入口导出 legacy Material 组件，而 3.50 正式 deprecate 了 SDK 内的 material / cupertino 与 `flutter_localizations` delegates。直接上 3.50 会让整个设计系统落在 deprecated 路径上
2. **`go_router` 18+ 已迁到 `material_ui`**。在 legacy `MaterialApp.router` 下，所有 `builder:` 路由静默变成 `NoTransitionPage`——丢转场、丢 iOS 侧滑、404 无 Scaffold，**不报编译错误、现有测试照样通过**。这是最危险的一类回归
3. **`flutter_markdown` 等仍用 legacy Material 的包**需要 `MaterialUiCompatibilityBridge` 兜底；桥接只能顶住主题/本地化继承，顶不住跨包同名类型（`ThemeData` / `ColorScheme` / `MaterialApp` 是两个不同的 Dart 类型）
4. **3.50 才发布 9 天**，且附带 AGP 9.3.1 / Gradle 9.5.0 / Java 17、`minSdk 24`、Xcode 27 的 `UIScene` 生命周期要求、release 构建收紧外部 Intent。这些都是 CI/签名链的变量，不该和 M0–M4 一起动

另外「其他依赖全升最新」本身也有坑，已在 §1.1 逐条标注：freezed 3.x 在 Dart 3.13 下报 `extraneous_modifier`、`riverpod_generator` 主版本 4 与运行时 3 不同、`build_runner` 2.16 移除了旧 flag、dio 5.11 改了异常分类。**「最新」是一组需要互相验证的组合，不是一个动作。**

### 15.3 触发升级到 3.50 的条件（全部满足才准动）

- [ ] `tdesign_flutter` 发布明确支持 `material_ui` 或 Flutter 3.50 的版本，并跑过 golden 回归
- [ ] `flutter_markdown`、`flutter_highlight`、`cached_network_image`、`flutter_secure_storage` 等直接依赖完成迁移或确认可用桥接
- [ ] `go_router` 18.x 与 `material_ui.MaterialApp` 的组合有嵌套 Hero / ShellRoute 转场的实测通过
- [ ] M4 已完成（「换真数据时 UI diff 为空」验收通过），项目不再处于架构验证期
- [ ] 有独立的一个升级窗口（约 1 人日）与可回滚的 pinned 旧版本

### 15.4 升级流程（两个 PR，绝不合并）

**PR-A：只换 import 与本地化，不动 SDK 版本**
```
dart fix --apply --code=migrate_design_widgets
flutter pub add material_ui cupertino_ui     # 若 fix 没自动加；禁止留 `any`，立刻改 caret
# localizationsDelegates: GlobalMaterialLocalizations.delegates
# MaterialApp.builder 挂 MaterialUiCompatibilityBridge（只包一层，不要每页包）
flutter analyze && flutter test && 浅/深 golden 全量
```
验收：`grep -rn "package:flutter/material.dart\|package:flutter/cupertino.dart" lib test --include="*.dart"` 的命中数归零；嵌套 Hero、ShellRoute 转场、iOS 侧滑逐项人工过。

**PR-B：再升 SDK 与依赖**
```
fvm use 3.50.0（或 flutter upgrade 后钉版本）
dart migrate --dry-run        # Dart 3.14 的逐语言版本升级工具，不直接手改 sdk 下限
dart migrate --apply --step=prepare,bump
flutter pub get --enforce-lockfile
dart fix --dry-run → dart fix --apply
dart run build_runner build --only-check
flutter analyze && flutter test && golden 全量 && 真机核心页面
```
`dart migrate` 只处理 `sdk >=3.0` 的包、一次走一个 minor、失败时源码与 pubspec 保持原样；**不要**手工把 `environment.sdk` 从 `^3.13.7` 直接改成 `^3.14.0`。

### 15.5 日常依赖升级纪律

- 每季度 stable 发布后留一个升级窗口，**不追 stable 首日**（patch 最密的头两周）
- 升级前固定体检：`flutter doctor -v` → `dart fix --dry-run` → `flutter pub outdated` → `flutter analyze` → `flutter test` → 真机核心页面目检（Impeller 渲染差异静态检查查不出）
- 判断包是否跟上，看它的 `pubspec.yaml` 依赖写的是 `flutter` 还是 `material_ui`，不要只看 README 更新时间
- 每次升级单开一个 PR，只升一类东西；CI 门禁（§3、§10）全绿才合
- 任何升级都不得放宽 §12 的禁令；§1 的版本矩阵由人更新，不由 Agent 自行改动
