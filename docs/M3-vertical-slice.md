# M3 · 垂直切片：仓库列表 → 仓库详情（全程 FakeDataSource）

> 用法：把下面整段发给 Agent。规则文件是 `@AGENTS.md` + `@DESIGN.md`。
> **前置条件（不满足就别发）**：M0、M1、**M2 全部已合入**，全链门禁绿，工作区干净。
> M3 依赖 M2 的 auth 守卫、`refreshListenable` 与 `MaterialApp.router`；M2 没落地就发这个 prompt，
> 会让 Agent 自己补一套路由，直接破坏 §7 的守卫约定。

---

读 @AGENTS.md 和 @DESIGN.md，再读以下已合入的源码，**全部按现状来，不要凭印象、不要臆造 API 或字段名**：

- `lib/shared/widgets/async_state_view.dart` —— M0 的 `AsyncPhase` 五态枚举 + `abstract interface class` 合同，**零实现，本次要实现它**
- `lib/features/repos/domain/entities/repo.dart` —— M1 的 Freezed 实体，字段名已对齐 `DtoRepos4User`
- `lib/features/repos/domain/repositories/repos_repository.dart` —— M1 的抽象接口
- `lib/features/repos/data/datasource/` —— M1 的 `FakeReposDataSource`（分页切片 / search / 四模式：延时可注入、403、空列表、断网）
- `lib/features/repos/data/mappers/`、`lib/core/error/failure.dart` —— DTO→Entity、`Failure` 五类
- `lib/core/router/routes.dart`（全表常量 + path builder）、`lib/core/router/app_router.dart`、`guards.dart`（M2）
- `lib/features/auth/`（M2 的 `AuthState` / `authNotifierProvider` / 守卫 / `unauthorized_handler`）
- `lib/core/theme/` 四文件（**`TThemeBuilder.light/dark` 是 ThemeData 静态工厂，不是 Widget**，见 `DESIGN.md` §1.2）
- `test/` 下 M0 的 13 例、M1 的 32 例、M2 新增的守卫/Notifier/Widget 用例、`.cnb.yml`

M0/M1/M2 已合入，全链门禁绿，工作区干净。本次只做 **M3：一条完整垂直切片「登录 → 仓库列表 → 仓库详情」**，全程走 FakeDataSource，把五态、主题、golden、截图闭环全跑通。

## 范围

### 1. 先实现 M0 留下的合同（不许另起炉灶）
- 在 `lib/shared/widgets/` 实现 `AsyncStateView`：**严格遵循 M0 的 `AsyncPhase` 与 `abstract interface class` 合同**，禁止删合同、禁止改枚举语义、禁止新建等价组件
- 五态宿主统一收敛 `AsyncValue.when` 的样板，各页面不得再各写一遍

### 2. 本切片需要的自建组件（其余 12 个先不动）
`RepoCard` · `LanguageBar` · `MetaRow` · `PagedList` · `SkeletonRepoCard` / `SkeletonList` · `EmptyView` · `ErrorView` · `OfflineView`

- 全部放 `lib/shared/widgets/`，内部消费 Token，外部只暴露业务参数；**禁止它们各自定义颜色 / 间距 / 字号**
- `RepoCard` 字段严格取自 M1 的 `Repo` 实体；语言色条取 `app_colors.dart`（24 种 + 兜底）；**禁止臆造 `starCount` / `repoName` 之类字段名**
- `PagedList` 接 M1 `FakeReposDataSource` 的分页切片：下拉刷新、上拉加载、到底状态、加载失败重试、页面销毁时取消在途（Fake 下用可取消 Future 语义，**为 M4 的 `CancelToken` 留好位置**）
- `ErrorView` 按 `Failure` 分类给文案，`Failure.http(403)` 必须差异化（见下）

### 3. 页面（按 `DESIGN.md` §5 的七项规格逐页写清再动手）
- **`/repos` 仓库列表**：`TNavBar` + `TRefresh` + `PagedList` + `RepoCard` + `AsyncStateView`；搜索（先读 M1 接口现状：已有方法就直接用；没有则在同一 PR 里**最小扩展接口**并同步补测，**禁止绕过接口直接调 datasource**）；点击进详情
- **`/repo/:owner/:name` 仓库详情**：顶部 `TNavBar` + `TTabs`，Shell 子页 `code / issues / pulls / releases / build / settings` **只建占位骨架**，各自独立栈。注意这是**页面内部 Tab**，不要和 M2 底部导航的 `StatefulShellRoute` 混为一谈
- **`/` 首页**：作为动态 / 最近仓库的占位入口即可，不做瀑布卡片
- 路由一律用 `routes.dart` 常量与 path builder，**禁止在 Widget 里拼字符串路径**；go_router 15+ URL 大小写敏感

### 4. 串起主链路
登录（M2）→ `?from=` 深链回跳 → `/repos` → 点击 → `/repo/:owner/:name` → 返回。
全程只经 `ReposRepository` 抽象接口拿数据，**UI 一行都不许 import `package:cna_api/...`，也不许碰 `remote_*` datasource**。

## 明确不做

- **不装 `flutter_markdown_plus`、不渲染任何 Markdown、不做 README / Issue 正文**（方案已定但属 M4，见 `DESIGN.md` §6.1）
- 不接真实 HTTP、不调 `cna_api` 发请求、不实现 `remote` datasource（M4）
- 不写 issues / pulls / build 子页的**内容**，只建 Shell 占位（M5）
- 不改 `lib/generated/cna_api/` 任何文件、不改 `api/spec/*.json`、不改 `tool/spec_whitelist.yaml`、不改 M1 的 filter / generate 脚本
- 不改 `AGENTS.md` / `DESIGN.md` 的禁令、不改 `lib/core/theme/` 的 Token 定义、不改 M2 的 auth / router 架构
- 不装 `material_ui` / `cupertino_ui`、不跑 `migrate_design_widgets`、不升 `go_router` 18+ 或 Flutter / Dart 基线
- 不「顺便」实现 `FileTree` / `DiffView` / `CodeBlock` / `LogTerminal` / `CommitTile` / `StatusBadge`，不重构无关页面
- 不把 GitHub / GitLab 客户端截图当输入

## 本切片最容易翻车的六点（违反即打回）

1. **假数据只准在 datasource 层**。复用 M1 的 `FakeReposDataSource` 四模式，通过 `ReposRepository` 注入；**Widget 里禁止出现任何写死的数组 / 字符串 / `['repo-a', ...]`**。这是 M4「换真数据时 UI diff 必须为空」的唯一保障
2. **Riverpod 3 失败 provider 默认自动重试**，会和 FakeDS 的 error / 403 / 断网模式叠加 → error 态一闪而过、测试 flaky、请求被放大。按 `AGENTS.md` §5：Repository 层只保留一处重试，测试里对已知业务错误**显式终止重试**；`AsyncValue` 的 error 必须能稳定断言。这一条要在计划里专门说明你怎么处理
3. **五态齐全且互不串味**：loading 用**与真实布局同尺寸的骨架屏**（不是全屏转圈）；empty 要「为什么空 + 下一步」；**offline 不许伪装成 empty**；403 归 `Failure.http(403)` 差异化文案——提示检查访问令牌授权范围，**不得显示崩溃或空白页**（有 token 看不到私有资源是 CNB 的常态）；改浅色不许把深色改坏，改空态不许把 loading 改坏
4. **设计系统**：颜色走 `context.tTheme`，间距走 `AppSpacing`，字排走 `Theme.of(context).textTheme` / `AppTypography`；**禁止裸 hex、`Colors.*`、魔法 `EdgeInsets`、内联 `TextStyle`**；状态色只有 `success/warning/error`，info 用 brand（§1.2 实测无 `infoColor`）。**`TThemeBuilder` 不是 Widget，不要在页面里 `return TThemeBuilder(child: ...)`**
5. **Toast / Overlay** 用目标 Navigator 与 Theme 子树里仍挂载、能访问 Overlay 的局部 context；异步后检查 `context.mounted`；禁止缓存 / 全局 context（`DESIGN.md` §4.2）
6. **防 `RIGHT OVERFLOWED`**：长仓库名、长描述、长 URL 一律明确省略或换行策略；安全区、`SafeArea`、键盘、大字体缩放都要过（`DESIGN.md` §9）

## 测试（M0 13 + M1 32 + M2 全部，一条都不许删或放宽）

- `AsyncStateView`：五态各一例 × 浅/深
- `RepoCard`：字段渲染、语言色条兜底、长仓库名省略、点击回调；**浅/深 golden**
- `PagedList`：分页切片、下拉刷新、上拉加载、到底、失败重试、销毁取消
- `/repos` 五态：用 FakeDS 四模式逐一切换（延时 / 403 / 空 / 断网），**403 差异化文案单测**；搜索态与结果态各一例
- `/repo/:owner/:name` Shell：Tab 切换、子页独立栈、深链带参进入
- **Golden**：`AsyncStateView` 五态、列表页 loading/empty/error、`RepoCard`，全部浅 + 深两套。CI 用非 update 命令，**禁止在门禁里传 `--update-goldens`**
- Widget / 集成：登录 → `?from=` 回跳 → `/repos` → 详情 → 返回 主链路；未登录深链仍被守卫拦到 `/login`
- M0 的「整 App 浅深 smoke」、Token 断言、「深色扩展必须是指向 `root.dark` 的同一实例」、「两套底色不同」**四条断言一条都不许删或放宽**；M1 的 mapper / FakeDS / trimSpec 用例全部保留

## 门禁（改完自己跑完并修到绿，别把红灯留给我）

```bash
dart run tool/filter_spec.dart --check
dart run tool/generate.dart            # 清理并重生成 cna_api，确认 git diff 为空
dart run build_runner build           # 新增 *.g.dart / *.freezed.dart 必须提交
dart format lib test
flutter analyze
flutter test
```

再本地复跑 `.cnb.yml` 完整链，确认：

- `git diff --exit-code` 的 freshness gate 仍覆盖四项：`api/spec/mvp.json`、`lib/generated/`、`lib/**/*.g.dart`、`lib/**/*.freezed.dart`（M2 已补，本次不许退回）
- `flutter pub get --enforce-lockfile` 通过、`pubspec.lock` 已提交、`git diff --exit-code` 全绿
- 若本次新增了任何依赖，一律 `flutter pub add`，禁止手填版本号、禁止 `pub upgrade --major-versions`

## 真机截图闭环（M3 验收的最后一步，不是输入规格）

页面跑起来后，截**自家 App 的真机图**回传，配结构化指令：

```
这张只定布局，配色以 DESIGN.md 为准。
只修间距溢出 / 对齐问题；不改交互逻辑、不改暗色 Token、不动其他页面。
```

禁止整包 GitHub 客户端截图、禁止把截图当唯一规格。回传后把修正结果补进 golden test。

## 交付格式

**先输出 3–5 步计划**，其中必须专门说明三件事：

1. 你打算怎么**实现 M0 的 `AsyncStateView` 合同**（怎么接 `AsyncPhase`、怎么把 `AsyncValue` 映射进去，不改合同）
2. `PagedList` 怎么和 M1 `FakeReposDataSource` 的分页切片对接，以及**为 M4 的 `CancelToken` 留了什么缝**
3. **Riverpod 3 自动重试怎么关掉 / 收敛**，保证 error 态测试稳定

等我确认再改文件。
一个 PR 只做 M3；内部建议按「共享组件 → 列表页 → 详情页」三次提交，便于 review，改动可独立回滚。
