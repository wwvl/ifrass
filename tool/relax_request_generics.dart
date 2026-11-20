// tool/relax_request_generics.dart
//
// 生成链的生成后改写步：纯函数、零依赖（dart core only），test/tool/ 直接测。
// 独立成文件的原因与 filter_spec.dart 的 trimSpec 相同——不把
// package:openapi_flutter_gen 依赖带进测试编译单元。
//
// 背景（M4 调研，2026-11-20）：openapi_flutter_gen 0.2.18 的
// generator/dart/api_generator.dart:213 对所有 method 模板硬编码
// `dio.request<Map<String, dynamic>>(`，不看响应 schema 是否数组；而
// dio 5.11.1 在 dio_mixin.dart `assureResponse<T>` 末尾做
// `response.data as T?` 硬转换——数组端点（如 `/user/repos`，spec 为裸
// array）在进入 sealed result 之前就被 `List as Map` 抛 TypeError
// （被包成 DioException(unknown, _TypeError)，response 数据不可恢复）。
// 生成器 0.2.5 有意引入该泛型，0.2.18（最新）未修；其自身 runtime 路径
// （runtime_generator.dart:355）用的就是 `request<dynamic>`。
//
// 修法：统一改写为 `dynamic`。sealed result 工厂仍按 schema 精确收敛
// （200 → `as Map<String, dynamic>` / `as List`），Map 端点语义不变；
// dio 的 dynamic 泛型为无操作转换。幂等：改写后的源码不再含原模式。
// 上游修复后删除本步即可。

/// 把生成器硬编码的请求泛型改写为 `dynamic`，返回改写后的源码。
///
/// 无命中时内容不变；二次应用结果一致（幂等，CI 新鲜度门禁依赖）。
String relaxRequestGenerics(String source) => source.replaceAll(
  'dio.request<Map<String, dynamic>>(',
  'dio.request<dynamic>(',
);
