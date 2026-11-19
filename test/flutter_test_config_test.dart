// flutter_test_config.dart 的单元测试：容差判定缝、basedir 往返、
// 同字节短路通过与全局安装生效（AGENTS.md §10 新增代码须有测试）。
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'flutter_test_config.dart';

void main() {
  group('TolerantLocalFileComparator', () {
    test('testExecutable 已把全局比较器替换为容差版', () {
      expect(goldenFileComparator, isA<TolerantLocalFileComparator>());
    });

    group('withinTolerance', () {
      test('逐像素通过即通过', () {
        final result = ComparisonResult(passed: true, diffPercent: 1);
        expect(TolerantLocalFileComparator.withinTolerance(result), isTrue);
      });

      test('阈值内（实测平台噪声 0.0015）通过', () {
        final result = ComparisonResult(passed: false, diffPercent: 0.0015);
        expect(TolerantLocalFileComparator.withinTolerance(result), isTrue);
      });

      test('阈值外判失败', () {
        final result = ComparisonResult(passed: false, diffPercent: 0.006);
        expect(TolerantLocalFileComparator.withinTolerance(result), isFalse);
      });
    });

    test('basedir 经虚拟文件名往返后保持一致', () async {
      final dir = await Directory.systemTemp.createTemp('golden_tolerance');
      addTearDown(() => dir.delete(recursive: true));
      final basedir = Uri.directory(dir.path);

      final comparator = TolerantLocalFileComparator(basedir);
      expect(comparator.basedir, basedir);
    });

    test('同字节比对经 listEquals 短路通过（无需真实 PNG）', () async {
      final dir = await Directory.systemTemp.createTemp('golden_tolerance');
      addTearDown(() => dir.delete(recursive: true));
      final basedir = Uri.directory(dir.path);
      final golden = Uri.parse('g.png');
      final bytes = Uint8List.fromList([1, 2, 3]);
      await File.fromUri(basedir.resolveUri(golden)).writeAsBytes(bytes);

      final comparator = TolerantLocalFileComparator(basedir);
      expect(await comparator.compare(bytes, golden), isTrue);
    });
  });
}
