/// 统一错误形态（AGENTS.md §5 网络层约定：sealed Failure）。
///
/// DataSource / Repository 在失败时抛出 [Failure]，UI 通过类型分派差异化文案：
/// 403 → 提示检查令牌授权范围；404 → 资源不存在；网络类 → OfflineView。
/// 纯 Dart，不依赖 Flutter / Dio / 生成客户端（domain 层可直接引用）。
///
/// 日志脱敏：`toString` 输出不携带 body 全文（AGENTS.md §11）。
library;

/// 错误基类。禁止在本文件之外 extends/implements（sealed 收口）。
sealed class Failure implements Exception {
  const new();
}

/// HTTP 非 2xx。保留 [status] 供 UI 决策（DESIGN.md §8：403/404 差异化文案）。
class FailureHttp extends Failure {
  /// 创建 HTTP 错误。
  const new(this.status, {this.body});

  /// HTTP 状态码。
  final int status;

  /// 服务端响应体摘录（可能含服务端 message；日志打印时注意脱敏）。
  final String? body;

  @override
  String toString() => 'FailureHttp($status)';
}

/// 网络不可达 / 超时 / 连接失败（OfflineView 对应态）。
class FailureNetwork extends Failure {
  /// 创建网络错误。
  const new({this.message});

  /// 概要描述（可选）。
  final String? message;

  @override
  String toString() => 'FailureNetwork(${message ?? 'unreachable'})';
}

/// 401 会话失效：由统一错误映射触发「清 token → 翻转 AuthState → 跳登录」，
/// 禁止在各页面分散处理（AGENTS.md §5）。
class FailureUnauthorized extends Failure {
  /// 创建鉴权失效错误。
  const new({this.body});

  /// 服务端响应体摘录（可选）。
  final String? body;

  @override
  String toString() => 'FailureUnauthorized()';
}

/// 响应解析失败：契约破坏（必需字段缺失 / 类型不符）。
class FailureParse extends Failure {
  /// 创建解析错误。
  const new(this.message);

  /// 解析失败的具体位置说明。
  final String message;

  @override
  String toString() => 'FailureParse($message)';
}

/// 未归类的兜底错误。
class FailureUnknown extends Failure {
  /// 创建未知错误。
  const new(this.message);

  /// 概要描述。
  final String message;

  @override
  String toString() => 'FailureUnknown($message)';
}
