# M5 · 内容渲染层 + 横向铺开（四个独立 PR）

> **M5 不是一个 PR，是里程碑组**。按 `AGENTS.md` §4.4 与 §12 第 12/26 条，拆成
> **M5-0 → M5-1 → M5-2 → M5-3**，顺序固定，一个 PR 只做一个 feature。
> 本文第一段是**现在就该发的 M5-0 完整 prompt**；后三段是后续变体，主体约束已由 M5-0 定死，
> 不必重复整段，只改「本次范围」即可。

## 前置条件（不满足就别发任何一段）

- M0 / M1 / M2 / M3 / **M4 全部已合入**，全链门禁绿，工作区干净
- **先核对 M4 的验收线证据**：`git diff --stat -- lib/features/**/presentation lib/shared/widgets lib/core/router lib/core/theme` 输出为空。若不为空，说明 M1/M3 的抽象没定对，**先回去修 M4，不要带着漂移进 M5**
- 本轮你只说了「M4 出来了」，没贴实施对照表；下面按「M4 验收线已过」写。若 M4 实际有偏离（例如改过 `AsyncStateView`、动过路由、新增了运行时依赖），先把偏离点补给我，我再校准 M5-0

---

# 第一段：M5-0 共享渲染层（可直接发给 Agent）

```
读 @AGENTS.md 和 @DESIGN.md（重点 §6.1 六条契约、§6 自建组件清单、§3 Token 表），
再读以下已合入的源码，全部按现状来，不要凭印象、不要臆造 API 或构造参数：

- lib/shared/widgets/ —— M3 的 AsyncStateView 实现、RepoCard / PagedList /
  EmptyView / ErrorView / OfflineView / Skeleton*（本次新增组件必须与它们同构）
- lib/core/theme/ 四文件（TThemeBuilder.light/dark 是 ThemeData 静态工厂，不是 Widget，
  见 DESIGN.md §1.2；无 infoColor，状态色只有 success/warning/error）
- lib/core/router/routes.dart、guards.dart —— 特别是 M2 的 from 站内校验纯函数
  （Uri.tryParse → 非绝对、无 scheme/host、以 / 开头 → 否则回落 /），本次链接路由要复用它
- lib/core/network/（M4 首次落地）：dioProvider / interceptors / pagination / CancelToken 缝
- lib/core/error/failure.dart、lib/features/repos/（M1/M3/M4 的
  Repository → DataSource → mapper 四层范式，照这个形状写后续 feature）
- lib/generated/cna_api/ 里 Issues / Pulls / Git / Build 四组 API 的目录结构
  （本次只读结构，不调用、不改任何文件）
- test/ 下全部既有用例（M0–M4）、tool/、.cnb.yml、pubspec.yaml / pubspec.lock

M0–M4 已合入，全链门禁绿，工作区干净。本次只做 **M5-0：首次装运行时依赖 + 建共享渲染组件骨架**。

【本次范围 —— 严格只有这五件，不写任何页面、不建 feature 目录】

1. 首次装运行时依赖（M0–M4 都没有为 UI 装过包，这是第一次）
   - 装前先跑 `flutter pub deps | grep material_ui`，**输出必须为空**，把结果贴进 PR 描述
   - 一律 `flutter pub add`，禁止手填版本号、禁止 pub upgrade --major-versions：
     flutter_markdown_plus（1.0.12）、flutter_highlight + highlight、
     cached_network_image、flutter_svg、url_launcher
   - **永久禁止 flutter_markdown**；禁止自行换成 gpt_markdown / markdown_widget /
     prism_markdown / 任何 git fork（AGENTS.md §12 第 20 条）
   - 装完立刻提交 pubspec.lock，确认 flutter pub get --enforce-lockfile 通过
   - 装完再跑一次 deps 检查，确认新依赖树里仍无 material_ui；
     若某包把 material_ui 带进来，停下来说明，走 DESIGN.md §6.1 的
     markdown 7.x + 自建渲染器保底路径，不得引入 MaterialUiCompatibilityBridge 凑合

2. lib/shared/widgets/markdown_body.dart —— 严格按 DESIGN.md §6.1 六条契约
   - 样式唯一出口：MarkdownStyleSheet.fromTheme(Theme.of(context)) 后，
     只把 h1..h6 / p / code / blockquote / table* 覆盖到 Theme.of(context).textTheme.*
     与 context.tTheme 语义色。禁止裸 hex、Colors.*、内联 TextStyle(fontSize: ...)
   - 浅深各构造一份，两套都要过 golden
   - 用 MarkdownBody / noScroll 形态（不自带滚动），**禁止**把自带滚动的 Markdown
     塞进已有滚动视图（两个 scrollable 会打架、报 viewport 错误）
   - fenced code 用 builders: {'pre': ...} 或 syntaxHighlighter 转交本次新建的 CodeBlock，
     不让 markdown 包自己画第二套代码框
   - 图片用 imageBuilder 接 cached_network_image，必须有加载中与失败占位；
     相对路径补全规则留一个明确 TODO（M5-1 定），本次禁止直接把任意 URL 丢给网络
   - 链接用 onTapLink 走本次新建的纯函数解析器（见第 4 点），不直接 launchUrl
   - **先读 flutter_markdown_plus 1.0.12 包源码确认构造参数与回调签名**
     （onTapLink 的 (text, href, title)、builders、selectable、noScroll），
     不确定就说明，禁止臆造 API
   - 不支持 inline HTML 是好事，不要绕过它引入任何 HTML 渲染；
     长文档不要在 build() 里重复解析，先解析一次再交给 Widget

3. lib/shared/widgets/ 其余四个骨架（与 M3 组件同构，内部消费 Token，外部只暴露业务参数）
   - CodeBlock：flutter_highlight + 等宽字排 + 横向滚动 + 浅深两套高亮主题；
     长行不得 RIGHT OVERFLOWED
   - StatusBadge：Issue / PR / 构建状态，仅用 tTheme.success/warning/error，
     info 语义用 brandColor（§1.2 实测无 infoColor）
   - CommitTile：commit hash 等宽、message、作者、时间
   - LogTerminal：等宽、自动滚动、可暂停、可取消订阅的**骨架**（本段不接数据流，
     不实现网络；为 M5-3 留好 Stream + cancel 接口）
   - 每个组件浅/深 golden test；禁止各自定义颜色 / 间距 / 字号

4. lib/shared/ 或 lib/core/router/ 下的**链接解析纯函数**（必须可单测）
   - 复用 M2 from 校验：Uri.tryParse → 要求非绝对、无 scheme/host、以 / 开头，
     否则拒绝或回落 /，防开放重定向
   - 站内路径走 core/router/routes.dart 常量与 path builder，禁止拼字符串
   - `#123` → Issue 详情、`@user` → 用户页（路由表里没有就先返回未解析，别臆造路由）
   - 外链只允许 https 且经 url_launcher；其余一律不响应
   - **禁止把「识别出链接」直接等同于「执行跳转」**

【明确不做】
- **不写任何页面、不建 lib/features/issues|pulls|build 目录、不改路由表**
  （M5-0 是共享层 PR，后面三段才消费它；见 AGENTS.md §4.4）
- 不改 tool/spec_whitelist.yaml、不改 api/spec/*.json、不改 lib/generated/cna_api/
  任何文件 —— 7 个 tag 已含 Issues / Pulls / Git / Build，不需要重生成；门禁仍跑 --check
- 不改 M2 的 auth / 守卫 / refreshListenable / handleUnauthorized 纯函数形态
- 不改 M4 的 core/network 拦截器顺序、Retry 白名单、401 单一入口
- 不改 M3 的 AsyncStateView 实现、不改 lib/core/theme/ 的 Token 定义
- 不改 AGENTS.md / DESIGN.md 的禁令；不动三 Tab 的 StatefulShellRoute.indexedStack / TTabBar
- 不装 material_ui / cupertino_ui、不跑 migrate_design_widgets、
  不升 go_router 18+ 或 Flutter / Dart 基线
- 不引入 Rust / flutter_rust_bridge / NDK（§12 第 11 条）
- 不臆造 TDesign 组件名或构造参数，不确定先查 example/ 或包源码
- 不「顺便」重构无关页面

【测试（M0–M4 全部既有用例一条都不许删或放宽）】
- 链接解析纯函数：站内路径、#123、@user、https 外链放行；
  绝对 URL / javascript: / 带 scheme-host 的 / 相对 //evil.com → 一律拒绝或回落 /；
  大小写不误判（go_router 15+ URL 大小写敏感）
- MarkdownBody：标题/列表/引用/表格/删除线（GFM 默认开启）、
  fenced code 确实转交 CodeBlock、图片占位与失败态、
  **不嵌套双滚动**（外层已有滚动视图时内层不报 viewport 错误）
- CodeBlock：长行横向滚动不溢出、hash/日志等宽不被全局字重覆盖、浅深两套 golden
- StatusBadge：success/warning/error 三态 + info 用 brand、浅深 golden
- CommitTile / LogTerminal 骨架：字段渲染、浅深 golden
- 全部新增组件过 §8 五态相关约束（本段组件自身至少 loading/error 占位可组合）
- 带模拟延时的用例沿用 M2 经验：pumpAndSettle 不推进纯 Future.delayed，
  用 pump(Duration) 显式推钟
- 禁止在门禁里传 --update-goldens

【门禁（改完自己跑完并修到绿，别把红灯留给我）】
flutter pub deps | grep material_ui            # 装前 + 装后各一次，两次都必须为空
flutter pub get --enforce-lockfile
dart run tool/filter_spec.dart --check          # 白名单未变，必须字节级幂等
dart run tool/generate.dart                     # 清理并重生成 cna_api，确认 git diff 为空
dart run build_runner build                     # 新增注解类产出的 *.g.dart / *.freezed.dart 必须提交
dart format lib test
flutter analyze
flutter test

再本地复跑 .cnb.yml 完整链，确认：
- freshness gate 的 git diff --exit-code 仍覆盖四项：api/spec/mvp.json、lib/generated/、
  lib/**/*.g.dart、lib/**/*.freezed.dart
- pubspec.lock 已提交、git diff --exit-code 全绿
- 把「装前 deps 检查为空」的输出贴进 PR 描述作为证据

【交付格式】
先输出 3–5 步计划，其中必须专门说明三件事：
1. 你读 flutter_markdown_plus 1.0.12 源码后，确认 onTapLink / builders / noScroll
   的真实签名是什么，以及 fenced code 打算怎么转交 CodeBlock
2. MarkdownStyleSheet 怎么做到「只引用 Theme.textTheme.* 与 context.tTheme」，
   浅深两套分别在哪构造
3. 链接解析纯函数放在哪一层、怎么复用 M2 的 from 校验而不重复实现
等我确认再改文件。
一个 PR 只做 M5-0；改动可独立回滚。
```

---

# 第二段：M5-1 issues（等 M5-0 合入后发）

在 M5-0 prompt 基础上，**只替换「本次范围」与「明确不做」两节**，其余（读源码清单、六条契约、测试基线、门禁链、交付格式）原样保留：

```
本次只做 M5-1：issues feature（Issue 列表 / 详情 / 评论流），第一个消费 MarkdownBody。

范围：
- lib/features/issues/ 按 M1/M4 四层范式建：domain/（Freezed 实体 + 抽象 Repository）、
  data/（RemoteIssuesDataSource 调 cna_api.IssuesApi + mappers/）、
  presentation/（列表页 + 详情页 + 评论流 + AsyncNotifier）
- 路由用 routes.dart 已有常量（/repo/:owner/:name/issue/:id），禁止拼字符串
- 详情页正文走 M5-0 的 MarkdownBody；fenced code 自动落到 CodeBlock；
  #123 / @user 链接走 M5-0 的解析纯函数；StatusBadge 显示 open/closed
- 评论输入框常驻但不遮挡内容（DESIGN.md §7）；不放第二个主操作
- 五态走 M3 的 AsyncStateView；Failure.http(403) 差异化文案
  （提示检查访问令牌授权范围，不得崩溃/空白）
- 分页走 core/network/pagination.dart；页面销毁接 M4 的 CancelToken
- 每个 @riverpod 显式 @Riverpod(name: '...')（M2 实测命名陷阱）

明确不做：不写 pulls / build 页面，不改 MarkdownBody / CodeBlock 等共享组件
（若发现共享组件不够用，停下来说明，回 M5-0 补，不要在 feature 里另建等价组件），
不改 spec 白名单 / api/spec / lib/generated，不改路由表结构，不新增依赖，
不装 material_ui，不升基线，不让 widget 测试打真实网络。
```

---

# 第三段：M5-2 pulls（等 M5-1 合入后发）

```
本次只做 M5-2：pulls feature（PR 列表 / 详情 / DiffView）。

范围：
- lib/features/pulls/ 四层同 M5-1，调 cna_api.PullsApi / Git 组
- 自建 DiffView（lib/shared/widgets/）：双栏/统一视图、行号、增删行高亮
  —— 状态色只用 tTheme.success / error（无 infoColor），
  代码高亮复用 M5-0 的 CodeBlock，禁止另建第二套高亮器
- PR 正文与评论复用 MarkdownBody；StatusBadge 显示 open/merged/closed
- 评论输入框常驻但不遮挡内容；五态 + 403 差异化；分页 + CancelToken
- 每个 @riverpod 显式 @Riverpod(name: '...')

明确不做：不写 build 页面，不改共享组件（不够用就回 M5-0 补），
不改 spec 白名单 / api/spec / lib/generated，不改路由表结构，不新增依赖，
不装 material_ui，不升基线，不引入 FRB。
```

---

# 第四段：M5-3 build（等 M5-2 合入后发）

```
本次只做 M5-3：build feature（构建状态 + 日志流），收尾一期 MVP。

范围：
- lib/features/build/ 四层同前，调 cna_api.BuildApi
- 消费 M5-0 的 LogTerminal 骨架，接真实流式响应：
  **禁止一次性加载全部日志再解析**（AGENTS.md §5），按行/SSE 增量渲染
- 退出页面必须取消订阅，接 M4 的 CancelToken；自动滚动 + 可暂停
- 等宽字排、深色终端内容区 Token；状态色 success/warning/error
- 五态 + 403 差异化（有 token 看不到私有构建是常态）
- 每个 @riverpod 显式 @Riverpod(name: '...')

明确不做：不改共享组件，不改 spec 白名单 / api/spec / lib/generated，
不改路由表结构，不新增依赖，不装 material_ui，不升基线，
**不引入 flutter_rust_bridge / Rust / NDK**（§12 第 11 条；
大日志流式处理若将来真成瓶颈，按 §9 走 benchmark 门禁的二期选项，本期不碰）。
```

---

## 四段共同的收尾检查

每段都要：一个 PR 一个 feature · 浅深两套 golden · 既有全部用例不许删/放宽 ·
freshness gate 四项 · `flutter pub get --enforce-lockfile` · `git diff --exit-code` 全绿 ·
PR 描述里附本段特有的证据（M5-0 附 deps 检查，M5-1/2/3 附「未改共享组件」的 diff 说明）。

**真机截图闭环**：M5-1 起每段跑起来后截自家 App 的图回传，配固定话术
「这张只定布局，配色以 DESIGN.md 为准；只修间距溢出，不改交互与暗色 Token」，
修正结果补进 golden test。禁止把 GitHub 客户端截图当输入。
