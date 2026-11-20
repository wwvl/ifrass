import 'package:tdesign_flutter/tdesign_flutter.dart';

/// Issue、PR 与构建状态共用的语义，不绑定服务端枚举。
enum StatusTone {
  /// 成功或完成。
  success,

  /// 等待或需要注意。
  warning,

  /// 失败。
  error,

  /// 信息态，使用品牌色。
  info,
}

/// 带文字的状态标签，配色由 TDesign 1.1 的语义 Token 提供。
class StatusBadge extends StatelessWidget {
  /// 创建状态标签；调用方只提供业务文案与语义。
  const new({required this.label, required this.tone, super.key});

  /// 可访问的状态文案，颜色之外仍可理解状态。
  final String label;

  /// 状态语义。
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final preset = switch (tone) {
      StatusTone.success => TTagColorPreset.success,
      StatusTone.warning => TTagColorPreset.warning,
      StatusTone.error => TTagColorPreset.danger,
      StatusTone.info => TTagColorPreset.primary,
    };

    return TTag(label, colorPreset: preset, variant: TTagVariant.light);
  }
}
