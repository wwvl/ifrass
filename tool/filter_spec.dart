// tool/filter_spec.dart
//
// CNB Swagger 2.0 契约裁剪：api/spec/swagger.full.json → api/spec/mvp.json
//
// 用法：
//   dart run tool/filter_spec.dart            # 生成 mvp.json
//   dart run tool/filter_spec.dart --check   # 只比对不写文件，CI 新鲜度门禁用
//
// 设计要点（对应 AGENTS.md §4.2）：
//  - 纯 dart:io / dart:convert，零第三方依赖，可直接用 Flutter 自带 Dart 运行
//  - 裁剪在 spec 层，不在生成后删文件（删生成文件不可复现、无法解释）
//  - 按 operation.tags 白名单过滤，并递归解析 $ref 保留定义传递闭包
//  - 白名单顺序固定；不写时间戳；Map 保持原始 key 顺序 → 输出幂等
//  - 大小写不敏感匹配，但会校验「白名单项是否真的命中」，防写错 tag 静默生成空集
//
// 注意：Swagger 2.0 的 $ref 形如 `#/definitions/XXX`。本脚本只裁剪 definitions，
// 顶层 `parameters` / `responses` / `securityDefinitions` 全量保留（体量小且被复用）。
//
// 结构说明：核心裁剪为纯函数 [trimSpec]（不碰文件系统），main 只负责 IO、
// 退出码与 --check；`test/tool/filter_spec_test.dart` 直接调用 trimSpec。

import 'dart:convert';
import 'dart:io';

const _httpMethods = <String>{
  'get',
  'put',
  'post',
  'delete',
  'options',
  'head',
  'patch',
  'trace',
};

const _fullSpecPath = 'api/spec/swagger.full.json';
const _outputPath = 'api/spec/mvp.json';
const _whitelistPath = 'tool/spec_whitelist.yaml';

const _definitionPrefix = '#/definitions/';

/// 裁剪结果统计（[trimSpec] 的返回值；doc 为原地裁剪后的完整文档）。
class FilterOutcome {
  /// 创建统计对象。
  FilterOutcome({
    required this.doc,
    required this.matchedTags,
    required this.missingTags,
    required this.originalPaths,
    required this.keptPaths,
    required this.keptOperations,
    required this.originalDefinitions,
    required this.keptDefinitions,
  });

  /// 裁剪后的文档（paths / definitions / tags 已收敛）。
  final Map<String, dynamic> doc;

  /// 命中白名单的 tag（保留 spec 原始大小写）。
  final Set<String> matchedTags;

  /// 白名单中未命中任何 operation 的项（非空即应判失败）。
  final List<String> missingTags;

  /// 裁剪前的 path 数。
  final int originalPaths;

  /// 裁剪后的 path 数。
  final int keptPaths;

  /// 保留的 operation 数。
  final int keptOperations;

  /// 裁剪前的 definition 数。
  final int originalDefinitions;

  /// 裁剪后保留的 definition 数。
  final int keptDefinitions;
}

/// 纯函数裁剪：按 [whitelist] 过滤 [doc] 的 paths，递归保留被引用的
/// definitions 传递闭包，并把命中的 operation 的 tags 收敛为白名单子集
/// （生成器按首个 tag 归组，不收敛会产生白名单之外的 API 类）。
/// 不做任何 IO；输入 doc 被原地修改并返回统计。
FilterOutcome trimSpec({
  required Map<String, dynamic> doc,
  required List<String> whitelist,
}) {
  final paths = (doc['paths'] as Map?)?.cast<String, dynamic>();
  final definitions =
      (doc['definitions'] as Map?)?.cast<String, dynamic>() ??
      <String, dynamic>{};
  if (paths == null) {
    throw ArgumentError.value(doc, 'doc', 'spec 缺少 paths');
  }

  final originalPaths = paths.length;
  final originalDefinitions = definitions.length;
  final allowedLower = whitelist.map((e) => e.toLowerCase()).toSet();
  final matchedTags = <String>{}; // 保留 spec 里的原始大小写
  var keptOperations = 0;

  // ── 1. 按 tag 裁剪 operation ────────────────────────────────────────────
  for (final pathKey in paths.keys.toList()) {
    final item = paths[pathKey];
    if (item is! Map) {
      paths.remove(pathKey);
      continue;
    }
    final pathItem = item.cast<String, dynamic>();

    for (final method in _httpMethods) {
      final op = pathItem[method];
      if (op is! Map) continue;
      final tags =
          (op['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[];
      final hit = tags
          .where((t) => allowedLower.contains(t.toLowerCase()))
          .toList();
      if (hit.isEmpty) {
        pathItem.remove(method);
      } else {
        matchedTags.addAll(hit);
        keptOperations++;
        // 命中的 operation 其 tags 可能带非白名单项（如 ["Assets","Pulls"]）。
        // 生成器按首个 tag 归组，不裁剪会产生白名单之外的 API 类；
        // 这里把 tags 收敛为白名单命中子集（保持原相对顺序）。
        op['tags'] = hit;
      }
    }

    // 只剩 path 级 parameters 也视为空，整条删除
    final remaining = pathItem.keys
        .where((k) => _httpMethods.contains(k.toLowerCase()))
        .length;
    if (remaining == 0) paths.remove(pathKey);
  }

  final missing = whitelist
      .where((w) => !matchedTags.any((m) => m.toLowerCase() == w.toLowerCase()))
      .toList();

  // ── 3. 收集保留部分的 $ref，再做 definitions 传递闭包 ────────────────────
  final directRefs = <String>{};
  _collectRefs({
    'paths': paths,
    'securityDefinitions': doc['securityDefinitions'],
    'parameters': doc['parameters'],
    'responses': doc['responses'],
  }, directRefs);

  final keep = _resolveDefinitions(definitions, directRefs);
  final dropped = definitions.length - keep.length;
  definitions.removeWhere((key, _) => !keep.contains(key));

  // ── 4. 顶层 tags 声明同步收敛（保留命中项的原始顺序）─────────────────────
  final declaredTags = doc['tags'];
  if (declaredTags is List) {
    doc['tags'] = declaredTags
        .where(
          (t) =>
              t is Map &&
              matchedTags.any(
                (m) => m.toLowerCase() == t['name'].toString().toLowerCase(),
              ),
        )
        .toList();
  }

  // 顶层元数据一律保留：swagger / info / host / basePath / schemes /
  // consumes / produces / securityDefinitions / security / parameters / responses
  // （不做删减，体量小且被引用）

  return FilterOutcome(
    doc: doc,
    matchedTags: matchedTags,
    missingTags: missing,
    originalPaths: originalPaths,
    keptPaths: paths.length,
    keptOperations: keptOperations,
    originalDefinitions: originalDefinitions,
    keptDefinitions: definitions.length,
  );
}

void main(List<String> args) {
  final checkOnly = args.contains('--check');

  final fullFile = File(_fullSpecPath);
  if (!fullFile.existsSync()) {
    stderr.writeln('[filter_spec] 缺少 $_fullSpecPath');
    stderr.writeln(
      '先执行：curl -o api/spec/swagger.full.json '
      'https://api.cnb.cool/swagger.json',
    );
    exit(64);
  }

  final whitelist = _readWhitelist();
  if (whitelist.isEmpty) {
    stderr.writeln('[filter_spec] $_whitelistPath 的 tags 为空或解析失败');
    exit(65);
  }

  // jsonDecode 返回 LinkedHashMap，遍历顺序与源文件一致 → 输出可复现
  final doc = jsonDecode(fullFile.readAsStringSync()) as Map<String, dynamic>;

  if (doc['swagger'] != '2.0') {
    stderr.writeln('[filter_spec] 期望 Swagger 2.0，实际 swagger=${doc['swagger']}');
    stderr.writeln('CNB 的 /openapi.json 需登录，禁止当作契约源（AGENTS.md §4.0）');
    exit(66);
  }

  final outcome = trimSpec(doc: doc, whitelist: whitelist);

  // ── 2. 校验白名单：有未命中项直接失败，避免静默生成空子集 ────────────────
  if (outcome.missingTags.isNotEmpty) {
    stderr.writeln(
      '[filter_spec] 白名单中以下 tag 在 spec 里没有命中：'
      '${outcome.missingTags.join(', ')}',
    );
    stderr.writeln('实际存在的 tag 请核对 api.cnb.cool 文档页或 swagger.full.json');
    exit(68);
  }
  if (outcome.keptOperations == 0) {
    stderr.writeln('[filter_spec] 裁剪后没有任何 operation，拒绝生成');
    exit(69);
  }

  // ── 5. 输出（缩进固定、无时间戳 → 幂等）──────────────────────────────
  final encoded =
      '${const JsonEncoder.withIndent('  ').convert(outcome.doc)}\n';
  final outFile = File(_outputPath);

  if (checkOnly) {
    final current = outFile.existsSync() ? outFile.readAsStringSync() : '';
    if (current != encoded) {
      stderr.writeln('[filter_spec] mvp.json 与白名单不一致，请重跑生成并提交');
      exit(1);
    }
    stdout.writeln('[filter_spec] --check 通过');
  } else {
    outFile.parent.createSync(recursive: true);
    outFile.writeAsStringSync(encoded);
  }

  stdout.writeln(
    '[filter_spec] tags(${whitelist.length}): ${whitelist.join(', ')}',
  );
  stdout.writeln(
    '[filter_spec] matched: ${outcome.matchedTags.toList().join(', ')}',
  );
  stdout.writeln(
    '[filter_spec] paths:    ${outcome.originalPaths} → ${outcome.keptPaths}',
  );
  stdout.writeln('[filter_spec] ops kept: ${outcome.keptOperations}');
  stdout.writeln(
    '[filter_spec] defs:     ${outcome.originalDefinitions} → '
    '${outcome.keptDefinitions} '
    '(dropped ${outcome.originalDefinitions - outcome.keptDefinitions})',
  );
  if (!checkOnly) stdout.writeln('[filter_spec] wrote $_outputPath');
}

/// 极简 YAML 读取：只取 `tags:` 段下的 `- value` 行，支持行内 # 注释。
/// 刻意不引入 package:yaml —— 本脚本要能用任意 Dart SDK 直接跑。
List<String> _readWhitelist() {
  final file = File(_whitelistPath);
  if (!file.existsSync()) {
    stderr.writeln('[filter_spec] 缺少 $_whitelistPath');
    exit(65);
  }
  final result = <String>[];
  var inTags = false;
  for (final raw in file.readAsLinesSync()) {
    final line = raw.split('#').first.trimRight();
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    if (!inTags) {
      if (trimmed == 'tags:') inTags = true;
      continue;
    }
    if (!raw.startsWith(RegExp(r'^\s+-'))) {
      // 遇到下一个顶层 key 即结束（当前文件 tags 是最后一段，仅作防御）
      if (!line.startsWith(' ') && !trimmed.startsWith('#')) break;
      continue;
    }
    final value = trimmed.replaceFirst(RegExp(r'^-\s*'), '').trim();
    if (value.isNotEmpty) result.add(value);
  }
  return result;
}

/// 递归收集任意 JSON 节点中的 $ref 字符串。
void _collectRefs(dynamic node, Set<String> out) {
  if (node is Map) {
    for (final entry in node.entries) {
      if (entry.key == r'$ref' && entry.value is String) {
        out.add(entry.value as String);
      } else {
        _collectRefs(entry.value, out);
      }
    }
  } else if (node is List) {
    for (final item in node) {
      _collectRefs(item, out);
    }
  }
}

/// 从直接引用的 definitions 出发，递归展开其内部的 $ref，得到必须保留的闭包。
Set<String> _resolveDefinitions(
  Map<String, dynamic> definitions,
  Set<String> directRefs,
) {
  final pending = <String>[];
  for (final ref in directRefs) {
    if (ref.startsWith(_definitionPrefix)) {
      pending.add(ref.substring(_definitionPrefix.length));
    }
  }

  final keep = <String>{};
  final unresolved = <String>{};
  while (pending.isNotEmpty) {
    final name = pending.removeAt(0);
    if (keep.contains(name)) continue;
    final schema = definitions[name];
    if (schema == null) {
      unresolved.add(name);
      continue;
    }
    keep.add(name);
    final nested = <String>{};
    _collectRefs(schema, nested);
    for (final ref in nested) {
      if (ref.startsWith(_definitionPrefix)) {
        final child = ref.substring(_definitionPrefix.length);
        if (!keep.contains(child)) pending.add(child);
      }
    }
  }
  if (unresolved.isNotEmpty) {
    stderr.writeln(
      '[filter_spec] 警告：以下 definition 被引用但未在 spec 中声明：'
      '${unresolved.toList().join(', ')}',
    );
  }
  return keep;
}
