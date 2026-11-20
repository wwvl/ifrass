import 'package:flutter_test/flutter_test.dart';

import '../../tool/relax_request_generics.dart' as gen;

/// `relaxRequestGenerics` 是生成链的生成后改写步（tool/generate.dart）：
/// 生成器 0.2.18 对所有 method 硬编码 `dio.request<Map<String, dynamic>>`，
/// 数组端点在 dio 5.11.1 的 `assureResponse<T>` 硬转换下运行时必崩
/// （详见 generate.dart 内注释与 M4 调研记录）。改写为 `dynamic` 后
/// sealed result 工厂仍按 schema 精确收敛。用例锁定：命中改写、无关
/// 内容不动、二次应用幂等（CI 新鲜度门禁依赖幂等）。
void main() {
  group('relaxRequestGenerics', () {
    const pattern = 'dio.request<Map<String, dynamic>>(';
    const relaxed = 'dio.request<dynamic>(';

    test('把模板泛型改写为 dynamic', () {
      const source = '''
    final response = await dio.request<Map<String, dynamic>>(
      '/user/repos',
      queryParameters: reqQueryParams,
    );
''';

      final out = gen.relaxRequestGenerics(source);

      expect(out, contains(relaxed));
      expect(out, isNot(contains(pattern)));
    });

    test('一个文件内多处命中全部改写', () {
      const source = '$pattern\n  foo();\n$pattern\n  bar();\n';

      final out = gen.relaxRequestGenerics(source);

      expect(pattern.allMatches(out), isEmpty);
      expect(relaxed.allMatches(out), hasLength(2));
    });

    test('无命中的内容原样返回（不做其它改动）', () {
      const source = '''
import 'package:dio/dio.dart';

class UsersApi {
  const UsersApi({required this.dio});
  final Dio dio;
}
''';

      expect(gen.relaxRequestGenerics(source), equals(source));
    });

    test('同一输入两次改写完全一致（幂等）', () {
      const source =
          'final response = await $pattern \'/\$repo\',\n';

      final once = gen.relaxRequestGenerics(source);
      final twice = gen.relaxRequestGenerics(once);

      expect(twice, once);
      expect(twice, isNot(contains(pattern)));
    });
  });
}
