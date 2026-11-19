import 'package:tdesign_flutter/tdesign_flutter.dart';

/// App 主题 Token 出口（DESIGN.md §2.1：浅深两套完整 Token）。
///
/// TDesign 1.1.0 的 `TThemeData.defaultData()` 内置浅色（default）与
/// 深色（defaultDark）两套完整 Token，深色挂载在根实例 `.dark` 上；
/// 本表不做「只做浅色再靠 `Brightness.dark` 猜」的半套方案。
/// 品牌色等覆盖收敛在本文件；DESIGN.md 未给出品牌 hex 前不自行发明色值。
abstract final class AppThemeTokens {
  /// Token 根实例：浅色本体，`.dark` 挂载深色（defaultData 内部缓存单例）。
  static final TThemeData root = TThemeData.defaultData();

  /// 浅色 Token。
  static TThemeData get light => root;

  /// 深色 Token；defaultData 内置 defaultDark，缺失时回退浅色。
  static TThemeData get dark => root.dark ?? root;
}
