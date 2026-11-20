# M5-0 共享渲染层实施记录

本段只提供共享组件和链接解析，不新增页面、feature 目录或路由。

## 兼容性基线补正

开始实施时，已合入的锁文件包含以下依赖链：

```text
flutter_riverpod 3.5.0 -> material_ui 1.11.1
cached_network_image 4.0.7 -> material_ui 1.11.1
material_ui 1.11.1 -> cupertino_ui 1.1.7
```

因此原需求的“装前检查为空”在原基线上不成立。维护者确认按最优方案
修复既有兼容性基线后，通过 `flutter pub add` 调整为：

| 包 | 版本 | 约束原因 |
|---|---|---|
| flutter_riverpod / riverpod | 3.4.3 | 保留 Riverpod 3 API，使用 legacy Material |
| riverpod_annotation | 4.0.7 | 与运行时 3.4.3 对齐 |
| riverpod_generator | 4.0.9 | 与注解 4.0.7 对齐 |
| build_runner | 2.16.2 | 与生成器要求的 build 4.x 兼容，支持 `--only-check` |
| cached_network_image | 3.4.1 | 使用 legacy Material 及对应的图片平台接口 |

不使用已经撤回的 build_runner 2.17.0 / build 4.1.0，也不通过
dependency override 绕过生成器契约。Flutter 3.47.9、Dart 3.13.7、
go_router 17.5.0 和 TDesign 1.1.0 保持不变。

修复后的兼容基线在安装新渲染依赖前，以及安装后分别检查：

```text
flutter pub deps --style=compact | rg 'material_ui|cupertino_ui'
<无匹配输出>
```

新增的包为 flutter_markdown_plus 1.0.12、markdown 7.3.1 和
url_launcher 6.3.3。markdown 7.3.1 是自定义代码块 builder 使用 AST
类型所需的直接依赖；渲染仍由指定的 flutter_markdown_plus 1.0.12 负责。
flutter_highlight 0.7.0、highlight 0.7.0 和 flutter_svg 2.4.0 原本已存在，
不把它们重复描述为本次新增。

来源：[Riverpod 3.4.3](https://pub.dev/packages/flutter_riverpod/versions/3.4.3)、
[图片缓存迁移日志](https://pub.dev/packages/cached_network_image/changelog)、
[build_runner 撤回版本](https://pub.dev/packages/build_runner/versions)。

## 渲染与链接契约

- MarkdownBody 使用 flutter_markdown_plus 1.0.12 的非滚动 body。
  该构造器没有 `noScroll` 参数；`noScroll` 属于带滚动容器的 Markdown。
  包内部缓存普通重建的解析结果，主题或正文变化时重新构造内容。
- `onTapLink` 的真实签名是 `void Function(String, String?, String)`。
  只把解析后的意图报告给调用方，组件不直接导航或启动浏览器。
- fenced code 通过 `builders['pre']` 读取 code 子元素的正文和语言，交给
  CodeBlock；清空包外层默认代码装饰，保留一套代码框。
- 样式从当前 ThemeData 的 textTheme 和 TDesign 1.1 语义色构造；等宽
  字族与字重复用现有 AppTypography.code，不新增主题 Token 或固定色板。
- 图片默认仅批准 HTTPS 的 cnb.cool / api.cnb.cool；凭据、显式端口、
  相对路径和其他未批准来源均显示占位。可注入仓库上下文审批策略，
  审批结果仍受 HTTPS 和无凭据约束。M5-1 再确定相对路径补全规则。
- M2 私有的 from 校验只公开名称为 safeFromTarget，函数算法、守卫
  行为和认证结构不变。内容链接解析复用该入口，不复制第二套校验。
  只有已注册路由才解析为站内目标；尚未注册的 Issue 详情和用户页使
  `#123`、`@user` 保持未解析。执行层在显式操作时再次验证目标。
- LogTerminal 只接收快照或调用方提供的 Dart 3.13 Stream 对象，
  不连接网络；提供暂停、继续、停止、自动跟随及订阅释放，并限制保留行数。

## 验证边界

新组件分别提供浅深色 golden；基线创建仅限新增的十张图片。完整门禁
不携带 `--update-goldens`，既有测试及其基线保持原样。
生成器版本调整后，应用侧产物由 build_runner 2.16.2 重生成并检查新鲜度。
OpenAPI spec、白名单、生成客户端、路由表、页面和主题 Token 均不修改。
