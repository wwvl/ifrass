// golden 跨平台容差比较器（AGENTS.md §10 golden 回归的 CI 适配）。
//
// 背景：golden 基线在本机（Windows）生成，CI 在 Linux（GitHub Actions
// ubuntu runner / cnb ubuntu 容器）比对，Skia 光栅化的抗锯齿与亚像素采样
// 存在平台级确定性差异。实测 3 组 golden 的差异为 0.03%–0.15%（135–722
// px），全部是边缘像素噪声，任何单一平台的逐像素基线都无法双平台同时绿。
//
// 策略：像素差比例 ≤ [kGoldenMaxDiffRatio] 判为通过；超阈值时走
// [LocalFileComparator] 原生失败路径（异常文本与 failures/ 差异图行为
// 不变）。真实视觉回归（颜色/布局/组件级改动）的像素差远超该阈值，
// 仍会被拦截。本机 --update-goldens 生成基线的用法不受影响（update
// 未改写）。
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

/// golden 像素差容差上限（0.5%）。
///
/// 实测 Windows 基线 vs Linux CI 最大 0.15%，留约 3 倍余量。
const double kGoldenMaxDiffRatio = 0.005;

/// flutter test 的全局配置入口：把默认逐像素比较器替换为容差版。
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final defaultComparator = goldenFileComparator;
  if (defaultComparator is LocalFileComparator) {
    goldenFileComparator = TolerantLocalFileComparator(
      defaultComparator.basedir,
    );
  }
  await testMain();
}

/// 在逐像素比对之上叠加比例容差的 golden 比较器。
///
/// `LocalFileComparator.compare` 失败时抛 FlutterError 而非返回 false；
/// 本类先算差异比例，阈值内改判通过，超阈值时复用原生失败路径。
class TolerantLocalFileComparator extends LocalFileComparator {
  /// 从测试文件所在目录构造（bootstrap 以测试文件 URI 初始化默认比较器，
  /// [testExecutable] 时刻 [LocalFileComparator.basedir] 已就绪）。
  ///
  /// `LocalFileComparator` 的构造入参是「测试文件」URI，basedir 取其
  /// dirname；这里用一个虚拟文件名还原出同一 basedir。
  new(Uri basedir) : super(basedir.resolve('__tolerant_comparator__.dart'));

  /// 供测试的判定缝：逐像素通过，或差比例 ≤ [kGoldenMaxDiffRatio]。
  @visibleForTesting
  static bool withinTolerance(ComparisonResult result) =>
      result.passed || result.diffPercent <= kGoldenMaxDiffRatio;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final within = withinTolerance(result);
    result.dispose();
    if (within) {
      return true;
    }
    // 超阈值：走原生失败路径（含 failures/ 差异图与原始异常文本）
    return await super.compare(imageBytes, golden);
  }
}
