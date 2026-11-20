import 'package:flutter/foundation.dart';

/// 应用级配置（AGENTS.md §2 core/config：环境、baseUrl、常量；禁止放密钥）。
///
/// baseUrl 事实源说明：`api/spec/*.json` 实查顶层 **无 host / basePath**
/// （Swagger 2.0 缺省 = 服务方根路径），生成物 core/ 默认值是占位
/// `https://localhost/`——都不携带真实地址。因此 app 侧唯一一份 baseUrl
/// 在此定义（AGENTS.md §5：禁止散落第二份），取值对齐 AGENTS.md §0
/// 「后端唯一事实源：https://api.cnb.cool」，由 `test/core/config`
/// 契约测试锁定。超时同样集中此处，禁止散落魔法数字（AGENTS.md §5）。
abstract final class AppConfig {
  /// 后端根地址（app 侧唯一一份，见类注释；结尾无 `/`，dio 拼接路径均以
  /// `/` 开头）。
  static const String apiBaseUrl = 'https://api.cnb.cool';

  /// 建连超时。
  static const Duration connectTimeout = Duration(seconds: 10);

  /// 请求体发送超时。
  static const Duration sendTimeout = Duration(seconds: 10);

  /// 响应接收超时（M4 为普通 JSON 接口；M5 构建日志流另议）。
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// 重试退避基数：第 n 次重试延迟 = base × 2ⁿ（AGENTS.md §5 指数退避）；
  /// 服务端带 `Retry-After` 时优先尊重该头（Retry 拦截器实现）。
  static const Duration retryBackoffBase = Duration(milliseconds: 500);

  /// dart-define 开关：true 时两条数据链装配 Fake 实现（无网开发 / 演示）。
  /// 生产默认 false = remote；测试经 provider `overrideWithValue` 回
  /// FakeDataSource，不读本开关（AGENTS.md §4 provider 切换约定）。
  static const bool useFakeApi = bool.fromEnvironment('CNA_FAKE_API');

  /// 是否打印 HTTP 结构化日志（AGENTS.md §11：调试日志 release 关闭）。
  static bool get enableHttpLogging => !kReleaseMode;
}
