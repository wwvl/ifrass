# DESIGN.md

> 本文件是 **cnb.cool Flutter 移动端客户端** 的视觉唯一事实源（Design System Contract）。
> 架构、技术栈、命令、禁令见同目录 `AGENTS.md`；本文件只回答「UI 应该长什么样、由什么组成」。
> 所有 AI 编码 Agent 在写任何一行 UI 代码之前必须读完本文件。
> 一句话原则：**AI 负责组合设计系统，不负责发明设计系统。**

---

## 0. 定位

这不是 moodboard，是一份可被审查、可被 golden test 校验的约束契约。

- 视觉底座：**TDesign Flutter**（腾讯设计体系）——cnb.cool 同属腾讯生态，视觉语言天然统一
- 产品形态：**开发者工具 / 代码托管客户端**，信息密度高、以内容为主，不是消费级营销页
- 气质关键词：克制、清晰、高信息密度、专业；**不要**「消费级 App 的大留白 + 大圆角卡片 + 渐变」
- 平台：手机优先（Android / iOS），折叠屏与平板做自适应，不单独设计另一套 UI

### 与 `AGENTS.md` 的分工

| 文件 | 回答 |
|---|---|
| `AGENTS.md` | 代码放哪、用哪个状态/路由/网络方案、跑什么命令 |
| `DESIGN.md` | 用什么颜色、什么组件、什么间距、每页有哪些状态 |

两者缺一不可：只有架构没有 Token 会产出不一致的丑 UI；只有 Token 没有架构会把逻辑塞进 Widget。

---

## 1. 版本与兼容性（先读这一段）

- 依赖锁定：`tdesign_flutter: ">=1.1.0 <1.2.0"`，**禁止** `^1.0.0`
- **1.1.0（2026-10-28）含公开 API、默认行为与视觉的 Breaking Changes**：`TActionSheet` 句柄行为、`Badge/SideBar/Cell` 圆角、`Table/Tabs/Toast` 内边距、`BackTop/Dropdown/Refresh` 图标默认规格、部分 `ThemeData` 新增成员、`TNavBar` 标题字体与颜色均有变化
- 1.0.0 要求 **Flutter ≥ 3.32.0 / Dart ≥ 3.8.0**；从 0.2.7 升级不能只替换 `TD` 前缀（构造参数、回调、受控值、主题配置、已移除能力都变了）
- **升级流程**：读 changelog → 锁版本 → 跑 `flutter analyze` → 跑 golden test 全量 → 人工过一遍 §7 的核心页面 → 才允许合并
- 组件名与 API **以当前依赖版本实际导出为准**；不确定时查 `example/lib/page/` 或官方文档，**禁止臆造 `T*` 组件名或构造参数**

### 1.1 设计库归属（2026 年 Flutter 解耦，必读）

Flutter 3.47 起 Material / Cupertino 开始拆成独立包 `material_ui` / `cupertino_ui`，3.50 起 SDK 内版本正式 deprecated。**本项目当前基线是 Flutter 3.47.9，属于 legacy Material 阵营**，理由见 `AGENTS.md` §1.0 / §15。

**唯一入口规则**：

- 全项目统一从 `package:tdesign_flutter/tdesign_flutter.dart` 取 `MaterialApp` / `Scaffold` / `Text` / `ThemeData` 等基础组件——**该入口按官方快速开始的说明，导出的是 SDK 内 `package:flutter/material.dart` 的组件**
- 禁止在部分文件 import `package:material_ui/material_ui.dart`、另一些文件 import `package:flutter/material.dart`。两边同名类型（`MaterialApp` / `ThemeData` / `ColorScheme` / `Scaffold`）是**不同的 Dart 类型**，混用会产生编译期或静默的运行时行为差异
- 禁止对 `lib/` 执行 `dart fix --apply --code=migrate_design_widgets`，禁止手工添加 `material_ui` / `cupertino_ui` 依赖
- **本地化**：3.47 起 `flutter_localizations` 已 unbundle，delegates 迁往独立设计包。本期仍按 legacy 方式注册 `GlobalMaterialLocalizations.delegate` / `GlobalCupertinoLocalizations.delegate` / `GlobalWidgetsLocalizations.delegate`；切到 `material_ui` 时统一改为 `GlobalMaterialLocalizations.delegates`（一次改完，不得半迁移）
- 依赖 `flutter_markdown`、`flutter_highlight`、`cached_network_image` 等仍使用 legacy Material 的包，若将来引入 `MaterialUiCompatibilityBridge`，**只在 `MaterialApp.builder` 包一层**，并为「主题继承 / 本地化 / 嵌套 Hero / 页面转场」各加一条 widget 测试

**迁移到 `material_ui` 是独立 PR**，不得与页面开发、SDK 升级、主题调整合并（见 `AGENTS.md` §15.4）。

### 1.2 TDesign 1.1.0 实测 API（M0 已验证，覆盖下方所有旧表述）

> **本节优先级最高**。M0 读包源码落地了 `lib/core/theme/` 四文件并通过 13 个用例；以下三条是实测结论，**禁止再按 §2.2 的旧表格或旧印象臆造 API**。

| 早前规则里的表述 | 实测事实 |
|---|---|
| 「`TThemeBuilder` 是包裹整树的 Widget」 | ❌ **`TThemeBuilder` 不是 Widget，是 `ThemeData` 静态工厂**。实际用法是 `TThemeBuilder.light(...)` / `.dark(...)` 产出两套 `ThemeData`，直接交给 `MaterialApp.theme` / `darkTheme` |
| 「`TThemeData` 是主题容器」 | ✅ **`TThemeData` 是 `ThemeExtension`**，挂在 `ThemeData.extensions` 上。`lib/core/theme/theme.dart` 是唯一桥接点 |
| 「语义 Token 有 `infoColor`」 | ❌ **无 `infoColor`**，info 语义由 `brandColor` 担当，已记入 `app_colors.dart` 注释 |
| — | `defaultData` / 内置 `defaultDark` 已用于浅深两套 Token 定义 |

**由此推出的硬规则**：

- 主题唯一出口是 `lib/core/theme/theme.dart`；任何页面不得自己包一层 `TThemeBuilder`（它不是 Widget，包了也无效）
- 读 Token 以 `context.tTheme`（或 M0 实际采用的等价扩展访问）为准；浅深两套各自完整，**深色扩展必须是指向 `root.dark` 的同一实例**（M0 已有断言，不许删/放宽）
- 状态色只有 `success` / `warning` / `error`；需要 info 时用 brand 语义，不得新增一个不存在的 `info*` Token
- `MarkdownBody` 依赖的 `flutter_markdown` 已被官方 discontinued（见 §6），M2/M3 不装，M4 前由人决策

---

## 2. 主题架构

### 2.1 唯一出口

```
lib/core/theme/
├── tdesign_theme.dart      # TThemeData 浅/深两套 Token 定义
├── app_tokens.dart         # AppSpacing / AppRadius / AppDurations / AppTypography
├── app_colors.dart         # 业务语义色（语言色条、状态色），仅补充 TDesign 未覆盖部分
└── theme.dart              # TThemeBuilder.light/dark（静态工厂）→ ThemeData，供 MaterialApp
```

`main.dart` 只从 `lib/core/theme/theme.dart` 取主题。**feature 目录下禁止出现第二份 `ThemeData`、色板、字号表。**

### 2.2 TDesign 主题机制（按 §1.2 实测，不是旧印象）

| 想改什么 | 入口 |
|---|---|
| 全局浅/深两套 `ThemeData` | `TThemeBuilder.light(...)` / `TThemeBuilder.dark(...)` 静态工厂，只在 `lib/core/theme/theme.dart` 调一次 |
| 全局颜色、字体、间距 Token | `TThemeData`（**ThemeExtension**），挂进 `ThemeData.extensions` |
| 某一类组件的默认样式 | 以 1.1.0 实际导出的 `T*ThemeData` 为准，不确定先读包源码，**禁止臆造** |
| 某个页面/区域 | 子树 `Theme` + extension 合并（以当前版本实际 API 为准） |
| 某个实例的尺寸/状态/内容 | 该组件的构造参数 |
| 读取当前主题 | `context.tTheme`（M0 已落地等价访问） |

> ⚠️ `TThemeBuilder` **不是 Widget**，不要在页面里 `return TThemeBuilder(child: ...)`。这一条是 M0 实测纠正的第一处，写错不会编译通过但方向全错。

### 2.3 三个必须知道的坑

1. **TD 内置视觉不隐式继承 Material 主题**。改 Material 的 `buttonTheme` / `textTheme` / `IconTheme` **不会**作用于 TD 组件的内置外观。要改 TD 组件就得改 TD 的 Token 或组件 Theme
2. `TThemeData.defaultData()` / 内置 default 只是默认配置，**不能代替当前上下文主题**；一律用 `context.tTheme`。M0 已用 `defaultDark` 准备深色一套
3. **浅色 / 深色各准备一套完整 Token**，不得只做浅色再靠 `Brightness.dark` 猜；切换 `ThemeMode` 时两套 `ThemeData`（由静态工厂产出）都要就位。M0 的「深色扩展必须是指向 `root.dark` 的同一实例」断言即为此设，不许删或放宽

### 2.4 主题切换

- `themeProvider`（Riverpod）持有 `ThemeMode`：system / light / dark，持久化到 `shared_preferences`
- 切换后整树重建，禁止在个别页面局部覆盖亮度
- 所有自建组件必须同时通过浅色与深色 golden test

---

## 3. Token 表

### 3.1 颜色

优先级：`context.tTheme` 的语义 Token > `app_colors.dart` 业务补充 > （禁止）裸 hex。

| 语义 | 来源 | 用途 |
|---|---|---|
| 品牌 / 主操作 | `tTheme.brand*` | 主按钮、选中态、链接 |
| 背景 / 表面 | `tTheme.bg*` | 页面底、卡片表面、浮层 |
| 文字（主 / 次 / 弱） | `tTheme.text*` | 三级文字层次，每页只用这三级 |
| 边框 / 分割线 | `tTheme.border*` | 卡片描边、列表分隔 |
| 状态色 | `tTheme.success / warning / error` | 构建状态、PR 状态、错误提示。**无 `infoColor`**，info 语义由 `brandColor` 担当（§1.2 实测） |
| 语言色条 | `app_colors.dart` | 仓库语言标识，24 种 + 兜底，独立常量表，集中维护 |

**禁止**：`Color(0xFF…)`、`Colors.blue`、在 Widget 里用 `withOpacity` 临时调色（应加语义 Token）。
**对比度**：正文 ≥ 4.5:1，大字号 ≥ 3:1（WCAG AA），深浅两套都要过。

### 3.2 字排

一律 `Theme.of(context).textTheme.*` 或 `AppTypography.*`，**禁止** `TextStyle(fontSize: 14)` 这类内联值。

| 角色 | 用途 |
|---|---|
| `headline*` | 页面标题、仓库名 |
| `title*` | 区块标题、Issue / PR 标题 |
| `body*` | 正文、描述、评论 |
| `label*` | 元信息：作者、时间、star 数、标签 |
| `code` | 代码 / commit hash / 日志（等宽，单独定义） |

行高、字重、字族只在 `app_tokens.dart` 定义一次；`strutStyle` / `textHeightBehavior` 用于对齐，禁止用旧版字体 padding 补偿。

### 3.3 间距（8pt 网格）

`AppSpacing`：`xs=4` / `sm=8` / `md=16` / `lg=24` / `xl=32` / `xxl=48`。

- 所有 `padding` / `margin` / `gap` / `SizedBox` 必须取 `AppSpacing.*`，落在 8pt 网格
- **禁止** `EdgeInsets.all(13)`、`SizedBox(height: 10)` 等任意值
- 组件内部间距由组件自己按 Token 决定，外部不要靠包一层 `Padding` 硬凑
- 输入框 / 文本域的布局、内容间距、文字高度走组件 API 与 Theme，**不能假设给外层设高度内部就等比缩放**

### 3.4 圆角、边框、动效、图标

- `AppRadius`：`sm` / `md` / `lg` / `pill`；禁止裸 `BorderRadius.circular(13)`
- `AppDurations`：`fast=150ms` / `normal=250ms` / `slow=400ms`；`AppCurves` 统一
- 图标优先 TDesign 图标库；替换资源集中配置，禁止各页面散落 `Icons.*` 混用风格
- `TImage` 走 Flutter `ImageProvider` 机制，**不要假定每次重建都会重新下载**；加载/失败占位由组件参数配置

---

## 4. 组件优先级与白名单

```
TDesign 组件  >  lib/shared/widgets 自建业务组件  >  Material / Flutter 原生组件
```

**规则**：存在等价的上层组件时，禁止直接使用下层组件；存在可复用组件时禁止新建等价组件。

### 4.1 TDesign 组件白名单（按场景）

| 场景 | 组件 |
|---|---|
| 导航 | `TNavBar`、`TTabs`（顶部页签）、底部导航（注意与顶部页签区分，1.0 后语义不同） |
| 列表 / 单元 | `TCell`、`TSideBar`、`TTable` |
| 操作 | `TButton`、`TActionSheet`、`TDropdown`、`TBackTop` |
| 反馈 | `TToast`、`TRefresh`、`TBadge`、`TTag` |
| 输入 | `TInput` / `TTextarea`（构造参数以当前版本为准） |
| 展示 | `TText`、`TImage` |
| 主题 | `TThemeData`、`TThemeBuilder`、`T*ThemeData`、`context.tTheme` |

> 这张表是**允许清单**，不是「可以自由发挥的灵感库」。新增白名单外组件必须先改本文件并说明理由。

### 4.2 Toast 与 Overlay 的硬规则

- 使用目标 `Navigator` 与 `Theme` 子树中**仍挂载、能访问 Overlay** 的 context；异步操作后先检查 `context.mounted`
- **禁止**长期缓存页面 context、禁止用全局 context 绕过局部主题
- 持续加载需显式 `Duration.zero` 并在业务结束后关闭；句柄与关闭方式按当前版本 API
- `TActionSheet` 1.1.0 起 Popup 句柄关闭后默认保留 State 可复用，所属 Navigator 卸载时释放——按此行为设计，不要假设每次都是全新实例

---

## 5. 页面规格模板（每个页面都必须填）

AI 生成任何页面前，先在提示词或该 feature 的 `presentation/` 注释里明确这七项：

1. **路径**：`core/router/routes.dart` 中的常量路由
2. **数据源**：对应 `Repository` 接口的方法（不是 Dio 调用）
3. **主组件**：白名单中的哪几个
4. **字段清单**：展示哪些实体字段
5. **交互**：点击去哪、下拉刷新、上拉分页、长按菜单
6. **五态**：loading / empty / error / offline / dark 的具体呈现
7. **不做**：明确列出本页不实现什么（防 AI 自由发挥）

---

## 6. 自建业务组件清单（`lib/shared/widgets/`）

TDesign 是通用移动组件库，**下列才是本 App 的主体界面**，必须自建且全部走 Token：

| 组件 | 职责 |
|---|---|
| `RepoCard` | 仓库名、描述、语言色条、star/fork、更新时间、可见性 |
| `LanguageBar` | 仓库语言占比色条 |
| `MetaRow` | 作者 / 时间 / 计数等元信息统一排版 |
| `StatusBadge` | Issue / PR / 构建状态（复用 TDesign 状态色） |
| `FileTree` | 目录树、折叠、文件类型图标 |
| `CommitTile` | commit hash（等宽）、message、作者、时间 |
| `DiffView` | 双栏 / 统一视图、增删行高亮、行号 |
| `CodeBlock` | 语法高亮（`flutter_highlight`）、等宽字排、横向滚动 |
| `MarkdownBody` | Issue / PR / README 渲染，链接走应用内路由。**`flutter_markdown` 已被官方 discontinued，禁止安装**；M4 内容渲染前由人决策替代方案（社区 fork / 自建解析），再更新本行 |
| `LogTerminal` | 构建日志流式终端视图、等宽、自动滚动、可暂停、可取消订阅 |
| `PagedList` | 统一分页列表：下拉刷新 / 上拉加载 / 骨架 / 空 / 错 / 离线 |
| `AsyncStateView` | 五态统一宿主，避免每页各写一遍 `when` |
| `Skeleton*`、`EmptyView`、`ErrorView`、`OfflineView` | 状态占位，文案走本地化 |

**约束**：这些组件内部消费 Token，外部只暴露业务参数；禁止它们各自定义颜色/间距；每个都要有浅/深 golden test。

---

## 7. 页面清单与视觉契约

页面 IA 由 `cnb-rs` 的 28 个资源模块 / 14 个命令组映射而来（不是从 GitHub 截图抄来的）。完整路由表见 `AGENTS.md` §7。

### 一期核心页面

| 页面 | 主内容 | 关键视觉约束 |
|---|---|---|
| Splash | 品牌 + 解析态 | 不做动画炫技，不做广告页；`AuthUnknown` 期间停留 |
| 登录 | PAT 输入、权限说明、最小权限引导 | 一个主操作；明示「token 只存本机 Keychain/Keystore」；不放用户名密码框 |
| 首页 | 动态 / 最近仓库 | 高信息密度列表，非卡片瀑布 |
| 仓库列表 | 分页 + 搜索 | `RepoCard` + `PagedList`；搜索态与结果态都要有 |
| 仓库详情 | Shell：code / issues / pulls / releases / build | 顶部 `TNavBar` + `TTabs`；子页各自独立栈 |
| Issue / PR 详情 | 正文（Markdown）+ 评论流 + 状态 | `MarkdownBody`；代码块走 `CodeBlock`；评论输入框常驻但不遮挡内容 |
| 构建日志 | 流式日志 | `LogTerminal`；**禁止一次性加载全部日志**；退出页面必须取消订阅 |
| 设置 | 主题 / 语言 / 列表密度 / 退出登录 | 用 `TCell` 分组；退出登录用破坏性样式 |

### 通用视觉规则

- 每页**一个主操作**，不要堆三个同权重按钮
- 文字三级层次：主 → 次 → 弱；不要出现第四种灰度
- 相邻同表面区块之间必须有分隔（表面色差 / 留白 / 分割线 / 描边，四选一），禁止两个同表面区块直接叠
- 列表密度可在设置里切换（compact / comfortable），通过 Token 缩放而非改死数值
- 空态文案说明「为什么空 + 下一步做什么」，不要只放一张插画

---

## 8. 五态规范（硬性）

每个含数据的页面必须实现且可被测试：

| 态 | 呈现 | 触发 |
|---|---|---|
| loading | 骨架屏（与真实布局同尺寸），**不用全屏转圈** | `AsyncLoading` |
| empty | `EmptyView`：说明 + 引导操作 | 数据为空且非错误 |
| error | `ErrorView`：可读错误 + 重试按钮；`Failure.http(403/404)` 给差异化文案 | `AsyncError` |
| offline | `OfflineView`：离线提示 + 重试；不伪装成空态 | 网络不可达 |
| dark | 完整深色 Token，所有自建组件与 golden 通过 | `ThemeMode.dark` |

**已知权限现实**：用户有 token 但看不到私有资源时，归入 `Failure.http(403)` 的差异化文案，提示检查访问令牌授权范围，**不得显示为崩溃或空白页**。

**禁止**：只做 empty 漏掉有数据态；改了浅色把深色改坏；改了空态把 loading 改坏；只改一个状态就宣称「页面完成」。

---

## 9. 布局、响应式与本地化

- 手机优先；`LayoutBuilder` + 断点做自适应，禁止写死 `width: 375`
- 必须防 `RIGHT OVERFLOWED`：长仓库名、长 commit message、长 URL 一律省略或换行策略明确
- 安全区、`SafeArea`、键盘弹出、横竖屏、大字体（系统字体缩放）都要过
- 国际化：`flutter_localizations` + `intl`，中文优先；**组件库自带文案需完整注册资源代理**，检查 `context` 位于 `Localizations` 之下、切换语言后不缓存旧代理
- 无障碍：语义标签、点击目标 ≥ 48dp、颜色不作为唯一状态传达（状态必须带文字/图标）
- 代码 / hash / 日志使用等宽字排，不要被全局字重覆盖

---

## 10. 视觉硬禁令（AI 生成 UI 最常见翻车点）

1. 禁止裸 hex、`Colors.*`、`EdgeInsets.all(13)`、`SizedBox(height: 10)`、内联 `TextStyle`
2. 禁止渐变背景、紫渐变 + 白底 + 三个圆角卡片、三列同构 feature 网格、居中正文、通用 AI hero 文案
3. 禁止 AI「顺手重新设计页面」：不得改变既有文字/图标/按钮位置，不得改变组件尺寸，不得删减字段
4. 禁止新建与白名单等价的组件；禁止绕过 `lib/shared/widgets` 直接用 Material 原生组件拼业务视图
5. 禁止把 GitHub / GitLab 客户端截图当视觉输入（产品是 cnb.cool 客户端，IA 不匹配且有原创性风险）
6. 禁止只给一张截图就让模型「照着做」——静态截图不携带组件层级、响应式、交互、五态；若必须参考，见 §11
7. 禁止在 feature 目录定义第二套主题 / 色板 / 字号
8. 禁止假设 TD 组件会跟随 Material 主题变化
9. 禁止用缓存的 / 全局的 context 弹 Toast
10. 禁止把 DTO 字段直接塞进 `Text()` 渲染（先过 mapper，见 `AGENTS.md` §2）
11. 禁止混用 `material_ui` / `cupertino_ui` 与 `package:flutter/material.dart`；禁止执行 `dart fix --apply --code=migrate_design_widgets`（见 §1.1）
12. 禁止半迁移本地化 delegates：要么三个 legacy delegate 齐全，要么整套换成 `GlobalMaterialLocalizations.delegates`

---

## 11. AI 生成 UI 的标准工作流

**第 0 步**：读 `AGENTS.md` + 本文件 + 目标目录现状。

**第 1 步（用文字定规格，不用截图）**：按 §5 的七项写清页面规格，@ 上本文件与 `Repository` 接口。

**第 2 步（提示词模板）**：

```
按 DESIGN.md 与 AGENTS.md 实现 /repo/:owner/:name 的 issues 子页。
只组合白名单组件：TCell、TTag、TRefresh、AsyncStateView、PagedList、MarkdownBody。
不新建等价组件，不改其他页面，不改主题文件。
必须实现 loading/empty/error/offline/dark 五态。
颜色走 context.tTheme，间距走 AppSpacing，字排走 Theme.textTheme。
数据源是 IssuesRepository 接口，禁止直接调 Dio 或渲染 DTO。
交付前跑 build_runner → dart format → flutter analyze → flutter test。
```

**第 3 步**：真机跑起来，跑 golden test。

**第 4 步（唯一值得传图的环节）**：把**自家 App 的真机截图**回传，配结构化指令：

```
这张只定布局，配色以 DESIGN.md 为准。
只修间距溢出 / 对齐问题；不改交互逻辑、不改暗色 Token、不动其他页面。
```

**禁止**的传图方式：整包 GitHub 客户端截图、未裁剪的全屏连拍、把截图当唯一规格。若确需外部参考，只允许 cnb.cool 自家 Web 端或 TDesign 组件示例页，且必须同时给出 Token 与组件白名单。

**第 5 步**：把结果补进 golden test，一个页面一个 PR。

> 输入信息量决定还原度：只给截图约 60–70%；补上设计系统 Token + 组件清单 + 可运行预览可达 80–90%。差距不在模型能力，在约束是否给足。

---

## 12. 验收清单（每个 UI PR）

- [ ] 无裸 hex / 无魔法间距 / 无内联 TextStyle / 无裸 `BorderRadius`
- [ ] 只使用了 §4 白名单或 `lib/shared/widgets` 组件
- [ ] 五态齐全且各自可测
- [ ] 浅色 + 深色 golden test 通过
- [ ] 长文本、大字体、窄屏无 `OVERFLOWED`
- [ ] 组件自带文案的本地化代理已注册
- [ ] 深色下对比度达标（正文 4.5:1 / 大字 3:1）
- [ ] Toast / Overlay 使用挂载中的局部 context，异步后检查 `context.mounted`
- [ ] `flutter analyze` + `flutter test` 全绿（见 `AGENTS.md` §3）
- [ ] 未改动 `lib/core/theme/` 之外的任何主题定义

---

## 13. 参考（按需查证，禁止凭记忆写 API）

- TDesign Flutter 更新日志：`https://tdesign.tencent.com/flutter/changelog`
- 自定义主题 / 暗色模式：`https://tdesign.tencent.com/flutter/dark-mode`
- 快速开始与 FAQ（版本要求、1.0 迁移、Toast/图片/国际化常见问题）
- 组件示例：`tdesign-component/example/lib/page/`
- 组件库首页（移动端 Flutter 入口）：`https://tdesign.tencent.com/`
