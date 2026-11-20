// tool/generate.dart
//
// api/spec/mvp.json → lib/generated/cna_api/（生成器产物包）
//
// 用法（必须在 tool/ 工程内跑，吃 tool/pubspec.lock 钉死的生成器版本）：
//   cd tool && dart run generate.dart
//
// 要点（AGENTS.md §4.1 / §4.2）：
//  - 只用 openapi_flutter_gen 的公开导出 API（loadSpec / SwaggerNormalizer /
//    OpenApiSpecParser / CodeGenerator），不 import 生成器内部路径
//  - 产物是独立 Dart 包（lib/generated/cna_api/），主 app 以 path 依赖引用；
//    生成器本身永远不进主 app 的 pubspec.yaml
//  - 产物为纯 Dart 源码、commit 即用；禁止手改（AGENTS.md §4.2）——
//    本脚本的生成后改写步是唯一例外（见 [relaxRequestGenerics] 注释），
//    且必须走本链路而非手改文件，保证可复现
//  - 幂等：无时间戳，连续两次运行 diff 为空（CI 新鲜度门禁依赖此性质）

import 'dart:io';

import 'package:openapi_flutter_gen/openapi_flutter_gen.dart';

import 'relax_request_generics.dart';

/// 产物包名：主 app import 形态为 `package:cna_api/cna_api.dart`。
const String packageName = 'cna_api';

/// 脚本锚定 tool/ 目录，路径不随 CWD 漂移。
final String _toolDir = File(Platform.script.toFilePath()).parent.path;
final String _repoRoot = Directory('$_toolDir/..').resolveSymbolicLinksSync();

Future<void> main() async {
  final specPath = '$_repoRoot/api/spec/mvp.json';
  final outputDir = '$_repoRoot/lib/generated';

  final specFile = File(specPath);
  if (!specFile.existsSync()) {
    stderr.writeln('[generate] 缺少 $specPath，先跑 filter_spec.dart');
    exit(64);
  }

  print('[generate] loading $specPath');
  final spec = await loadSpec(specPath);
  final normalized = SwaggerNormalizer.normalize(spec);

  print('[generate] parsing...');
  final doc = OpenApiSpecParser(normalized).parse();

  // 生成器只写不删：上一次的多余产物会残留并污染 git diff 幂等判定。
  // 先整体清掉产物包目录（固定包名，只删生成物，不碰其它内容）。
  final packageDir = Directory('$outputDir/$packageName');
  if (packageDir.existsSync()) {
    packageDir.deleteSync(recursive: true);
    print('[generate] cleaned stale $packageDir');
  }

  print('[generate] generating package $packageName → $outputDir');
  final generator = CodeGenerator(
    doc: doc,
    outputDir: outputDir,
    packageName: packageName,
  );
  await generator.generate();

  final rewritten = _relaxRequestGenericsInPlace(packageDir);
  print('[generate] relaxed request generics in $rewritten file(s)');

  print('[generate] done');
}

/// 对产物包内全部 .dart 文件应用 [relaxRequestGenerics]，返回改写文件数。
int _relaxRequestGenericsInPlace(Directory packageDir) {
  var changed = 0;
  for (final entity in packageDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final original = entity.readAsStringSync();
    final relaxed = relaxRequestGenerics(original);
    if (relaxed != original) {
      entity.writeAsStringSync(relaxed);
      changed++;
    }
  }
  return changed;
}
